#!/usr/bin/env bash
# Home Lab Setup Script for Debian/Ubuntu
# Automates initial server configuration with package installation,
# SSH hardening, Docker setup, and useful aliases.
# WARNING: This script disables SSH password authentication.

set -euo pipefail

# Colors
BLUE="\033[34m"
YELLOW="\033[33m"
RED="\033[31m"
GREEN="\033[32m"
RESET="\033[0m"

# Configuration
timezone="unknown"
packages=(btop tmux neofetch mc htop iotop iftop wget curl jq nano git coreutils rclone rsync python3 python3-pip figlet p7zip-full docker.io docker-compose-v2 wipe ufw openssh-server)
flag_file="/var/log/setup-complete.flag"

# Spinner / throbber
spinner() {
    local pid=$1 delay=0.1 spinstr='|/-\'
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Check system compatibility
check_system() {
    echo -e "${BLUE}Checking system compatibility${RESET}"
    if ! command -v lsb_release &>/dev/null && [ ! -f /etc/os-release ]; then
        echo -e "${RED}Unable to detect OS information. Exiting.${RESET}"
        return 1
    fi

    if command -v lsb_release &>/dev/null; then
        distro=$(lsb_release -is 2>/dev/null | tr '[:upper:]' '[:lower:]')
    else
        distro=$(grep -E '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')
    fi

    if ! command -v apt-get &>/dev/null; then
        echo -e "${RED}This system does not use apt package manager. Exiting.${RESET}"
        return 1
    fi

    case "$distro" in
        ubuntu|debian|linuxmint|pop|elementary|zorin|kali)
            echo -e "${GREEN}Detected supported distro: $distro${RESET}"
            ;;
        *)
            echo -e "${RED}Unsupported distribution: $distro${RESET}"
            return 1
            ;;
    esac
}

# Add aliases
add_alias() {
    local name="$1" def="$2"
    if ! grep -q "^alias $name=" ~/.bashrc 2>/dev/null; then
        echo "alias $name='$def'" >> ~/.bashrc
    fi
}

# Exit message
exit_message_error() {
    echo -e "${RED}Setup script has already executed${RESET}"
    sleep 0.3
    echo -e "${RED}Aborting script${RESET}"
    sleep 0.3
    echo -e "${YELLOW}To override; run command;${RESET}"
    sleep 0.3
    echo -e "${RED}sudo rm /var/log/setup-complete.flag${RESET}"
    echo -e "\n${RED}IMPORTANT: Copy your private key from ~/.ssh/id_rsa before disconnecting${RESET}\n"
}

# Prevent re-run
if [ -f "$flag_file" ]; then
    clear
    echo -e "${YELLOW}This script has already been run previously${RESET}"
    echo -e "${YELLOW}To re-run, delete $flag_file and try again${RESET}"
    exit_message_error
    exit 0
fi

clear
echo -e "${YELLOW}==============================================${RESET}"
echo -e "${YELLOW}Whonix Initium${RESET}" echo -e "${YELLOW}For Debian/Ubuntu${RESET}"
echo -e "${YELLOW}==============================================${RESET}\n"

echo -e "${RED}WARNING: This script may cause SSH lockouts.${RESET}\n"

if ! check_system; then
    exit 1
fi

read -rp "Do you want to continue? (y/n) " answer
[[ "$answer" =~ ^[yY]$ ]] || { echo -e "${YELLOW}Exiting${RESET}"; exit 0; }

echo -e "${RED}This script requires sudo privileges${RESET}"
if ! sudo -v; then
    echo -e "${RED}Failed to obtain sudo privileges${RESET}"
    exit 1
fi

# SSH configuration
read -rp "Do you want to configure SSH? (y/n) " ssh_answer
if [[ "$ssh_answer" =~ ^[yY]$ ]]; then
    read -rp "Import existing SSH keys or generate new keys? (gen/imp) " paste_answer
    if [[ "$paste_answer" == "imp" ]]; then
        echo -e "${YELLOW}Paste your SSH public key (then press Enter twice):${RESET}"
        user_pubkey=""
        while IFS= read -r line; do
            [[ -z "$line" ]] && break
            user_pubkey+="$line"$'\n'
        done

        echo -e "${YELLOW}Paste your SSH private key (then press Enter twice):${RESET}"
        user_privkey=""
        while IFS= read -r line; do
            [[ -z "$line" ]] && break
            user_privkey+="$line"$'\n'
        done
    fi
fi

# Update and install packages
update_install() {
    echo -e "${BLUE}Updating system packages${RESET}"
    (sudo apt-get update -y >/dev/null 2>&1) & spinner $!
    echo -e "${GREEN}System updated${RESET}"

    echo -e "${BLUE}Installing required packages${RESET}"
    (sudo apt-get install -y "${packages[@]}" >/dev/null 2>&1) & spinner $!
    echo -e "${GREEN}Packages installed${RESET}"
    echo -e "${BLUE}Upgrading system${RESET}"
    sudo apt-get autoremove -y >/dev/null 2>&1) & spinner $!
    sudo apt-get install -y
    echo -e "${GREEN}Upgrade complete${RESET}"  
}

# Add user to docker group
usermods() {
    local user
    user="$(whoami)"
    echo -e "${BLUE}Adding $user to docker group${RESET}"
    (sudo usermod -aG docker "$user") & spinner $!
    echo -e "${GREEN}User added to docker group${RESET}"
}

# Set aliases
set_aliases() {
    echo -e "${BLUE}Adding aliases${RESET}"
    (
        cp ~/.bashrc ~/.bashrc.bak
        add_alias "cdc" "cat docker-compose.yml"
        add_alias "rmdc" "rm docker-compose.yml"
        add_alias "ndc" "nano docker-compose.yml"
        add_alias "nenv" "nano .env"
        add_alias "rmenv" "rm .env"
        add_alias "dcu" "docker compose up -d"
        add_alias "dcd" "docker compose down"
        add_alias "dcr" "docker compose restart"
        add_alias "dcp" "docker compose pull"
        add_alias "dcl" "docker compose logs -f"
        add_alias "dps" "docker ps --format '{{.Names}}'"
    ) & spinner $!
    echo -e "${GREEN}Aliases added to ~/.bashrc${RESET}"
}

# SSH + UFW hardening
ssh_ufw_hardening() {
    echo -e "${BLUE}Configuring UFW${RESET}"
    (sudo sed -i 's/IPV6=yes/IPV6=no/' /etc/default/ufw) & spinner $!
    echo -e "${GREEN}UFW IPv6 disabled${RESET}"

    local user hostname
    user="$(whoami)"
    hostname="$(hostname)"

    if [[ "$ssh_answer" =~ ^[yY]$ ]]; then
        case "$paste_answer" in
            imp)
                sudo rm -rf ~/.ssh
                mkdir -p ~/.ssh
                if [ -n "$user_pubkey" ]; then
                    echo -e "${BLUE}Adding public key${RESET}"
                    (echo "$user_pubkey" > ~/.ssh/authorized_keys && chmod 644 ~/.ssh/authorized_keys) & spinner $!
                    echo -e "${GREEN}Public key added${RESET}"
                fi
                if [ -n "$user_privkey" ]; then
                    echo -e "${BLUE}Adding private key${RESET}"
                    (echo "$user_privkey" > ~/.ssh/id_rsa && chmod 600 ~/.ssh/id_rsa) & spinner $!
                    echo -e "${GREEN}Private key added${RESET}"
                fi
                ;;
            *)
                echo -e "${BLUE}Generating new RSA key pair${RESET}"
                sudo rm -rf ~/.ssh
                mkdir -p ~/.ssh
                (ssh-keygen -t rsa -b 4096 -C "${user}@${hostname}" -f ~/.ssh/id_rsa -N "" -q) & spinner $!
                (cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys && chmod 644 ~/.ssh/authorized_keys && chmod 600 ~/.ssh/id_rsa) & spinner $!
                echo -e "${GREEN}SSH keys generated${RESET}"
                echo -e "\n${RED}IMPORTANT: Copy your private key from ~/.ssh/id_rsa before disconnecting${RESET}\n"
                ;;
        esac

        echo -e "${BLUE}Backing up SSH config${RESET}"
        (sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak) & spinner $!
        echo -e "${GREEN}Backup created${RESET}"

        echo -e "${BLUE}Hardening SSH configuration${RESET}"
        (
            sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
            sudo sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
            sudo sed -i 's/^#\?KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/' /etc/ssh/sshd_config
            sudo sed -i 's/^#\?UsePAM.*/UsePAM no/' /etc/ssh/sshd_config
            sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
        ) & spinner $!
        echo -e "${GREEN}SSH configuration hardened${RESET}"

        echo -e "${BLUE}Reloading SSH service${RESET}"
        (sudo systemctl reload ssh) & spinner $!
        echo -e "${GREEN}SSH service reloaded${RESET}"
    else
        echo -e "${YELLOW}Skipping SSH configuration${RESET}"
    fi
}

# Timezone setup
set_timezone() {
  echo -e "${BLUE}Setting timezone${RESET}"

  # Start curl in background and capture PID for spinner
  tmpfile=$(mktemp)
  curl -s 'http://ip-api.com/json/?fields=status,message,timezone' >"$tmpfile" &
  curl_pid=$!
  spinner "$curl_pid"
  wait "$curl_pid"

  # Parse timezone only if status is success
  status=$(jq -r '.status // empty' <"$tmpfile")
  if [ "$status" = "success" ]; then
    timezone=$(jq -r '.timezone // empty' <"$tmpfile")
  else
    timezone=""
  fi
  rm -f "$tmpfile"

  if [ -n "$timezone" ]; then
    (sudo timedatectl set-timezone "$timezone") &
    spinner $!
    echo -e "${GREEN}Timezone set to $timezone${RESET}"
  else
    echo -e "${YELLOW}Could not determine timezone automatically${RESET}"
    timezone="unknown"
  fi
}

# MOTD
figlet_motd() {
    echo -e "${BLUE}Creating MOTD${RESET}"
    (figlet "$(hostname)" | sudo tee /etc/motd >/dev/null) & spinner $!
    echo -e "${GREEN}MOTD created${RESET}"
}

# Exit message
exit_message() {
    echo -e "${GREEN}================================${RESET}"
    echo -e "${GREEN}Setup Complete!${RESET}"
    echo -e "${GREEN}================================${RESET}"
    echo -e "Timezone set to ${timezone:-unknown}\n"
    if [ -f ~/.ssh/id_rsa ]; then
        echo -e "${RED}REMINDER: Save your private key from ~/.ssh/id_rsa${RESET}\n"
    fi
}

# main
update_install
usermods
set_aliases
ssh_ufw_hardening
set_timezone
figlet_motd

echo -e "${BLUE}Creating completion flag${RESET}"
(sudo touch "$flag_file") & spinner $!
exit_message

read -rp "Press Enter to reboot the system (or Ctrl+C to cancel)"
echo -e "${BLUE}Rebooting system${RESET}"
sleep 2
sudo reboot