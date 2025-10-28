#!/usr/bin/env bash

# Whonix Initium Script for Debian/Ubuntu
# Automates initial server configuration with package installation,
# SSH hardening, Docker setup, and useful aliases.
# WARNING: This script disables SSH password authentication, test before rebooting!

set -euo pipefail

BLUE="\033[34m"
YELLOW="\033[33m"
RED="\033[31m"
GREEN="\033[32m"
RESET="\033[0m"

packages=(btop wireguard speedtest-cli tmux snapd neofetch mc htop iotop iftop wget curl jq nano git coreutils rclone rsync python3 python3-pip figlet p7zip-full docker.io docker-compose-v2 wipe ufw openssh-server ipcalc)
timezone="unknown"
flag_file="/var/log/setup-complete.flag"

ssh_config_enabled=false
ssh_key_source="none"
key_url=""
new_hostname=""
configure_git=false
git_username=""
git_email=""

# spinner / throbber
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

# compatibility check
check_system() {
    echo -e "${BLUE}Checking system compatibility${RESET}"
    if ! command -v lsb_release &>/dev/null && [ ! -f /etc/os-release ]; then
        echo -e "${RED}Unable to detect OS information. Exiting.${RESET}"
        return 1
    fi
    if command -v lsb_release &>/dev/null; then
        distro=$(lsb_release -is 2>/dev/null | tr '[:upper:]' '[:lower:]')
        version=$(lsb_release -rs 2>/dev/null)
    else
        distro=$(grep -E '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')
        version=$(grep -E '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
    fi
    if ! command -v apt-get &>/dev/null; then
        echo -e "${RED}This system is not compatible. Exiting.${RESET}"
        return 1
    fi
    case "$distro" in
        ubuntu|debian|linuxmint|pop|elementary|zorin|kali)
            echo -e "${GREEN}System compatible: $distro $version${RESET}"
            ;;
        *)
            echo -e "${RED}Unsupported distribution: $distro${RESET}"
            return 1
            ;;
    esac
}

# ~/.bashrc aliases
add_alias() {
    local name="$1" def="$2"
    if ! grep -q "^alias $name=" ~/.bashrc 2>/dev/null; then
        echo "alias $name='$def'" >> ~/.bashrc
    fi
}

# validate yes / no input
validate_yes_no() {
    local prompt="$1"
    local response
    while true; do
        read -rp "$prompt" response
        if [[ "$response" =~ ^[yYnN]$ ]]; then
            echo "$response"
            return 0
        else
            echo -e "${RED}Invalid input. Please enter 'y' or 'n'.${RESET}"
        fi
    done
}

# backup and setup SSH directory
setup_ssh_dir() {
    if [ -d ~/.ssh ]; then
        sudo mv ~/.ssh ~/.ssh-bak
    fi
    mkdir -p ~/.ssh
}

# generate SSH keys and setup permissions
generate_ssh_keys() {
    local user hostname
    user="$(whoami)"
    hostname="$(hostname)"
    echo -e "${BLUE}Generating new RSA key pair${RESET}"
    (ssh-keygen -t rsa -b 4096 -C "${user}@${hostname}" -f ~/.ssh/id_rsa -N "" -q) & spinner $!
    cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/authorized_keys ~/.ssh/id_rsa
    echo -e "${GREEN}SSH keys generated${RESET}"
}

# initial setup / prompts
initial_setup() {
    clear
    echo -e "${YELLOW}==============================================${RESET}"
    echo -e "${YELLOW}Whonix Initium${RESET}"
    echo -e "${YELLOW}For Debian/Ubuntu${RESET}"
    echo -e "${YELLOW}==============================================${RESET}\n"

    if [ -f "$flag_file" ]; then
        echo -e "${YELLOW}This script has already been run previously${RESET}"
        local override_answer
        override_answer=$(validate_yes_no "Do you want to override and run again? (y/n) ")
        if [[ ! "$override_answer" =~ ^[yY]$ ]]; then
            echo -e "${YELLOW}Exiting${RESET}"
            exit 0
        fi
        sudo rm -f "$flag_file"
        echo ""
    fi

    echo -e "${RED}WARNING: This script may cause SSH lockouts.${RESET}\n"

    if ! check_system; then
        exit 1
    fi

    local answer
    answer=$(validate_yes_no "Do you want to continue? (y/n) ")
    [[ "$answer" =~ ^[yY]$ ]] || { echo -e "${YELLOW}Exiting${RESET}"; exit 0; }
    echo -e "${RED}This script requires sudo privileges${RESET}"
    if ! sudo -v; then
        echo -e "${RED}Failed to obtain sudo privileges${RESET}"
        exit 1
    fi

    echo ""
    local hostname_answer
    hostname_answer=$(validate_yes_no "Do you want to set a new hostname? (y/n) ")
    if [[ "$hostname_answer" =~ ^[yY]$ ]]; then
        while true; do
            read -rp "Enter new hostname: " new_hostname
            if [ -n "$new_hostname" ]; then
                if [[ "$new_hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]; then
                    break
                else
                    echo -e "${RED}Invalid hostname format. Use only letters, numbers, and hyphens.${RESET}"
                fi
            else
                echo -e "${YELLOW}No hostname provided. Keeping current hostname.${RESET}"
                new_hostname=""
                break
            fi
        done
    fi

    echo ""
    local git_answer
    git_answer=$(validate_yes_no "Do you want to configure Git profile? (y/n) ")
    if [[ "$git_answer" =~ ^[yY]$ ]]; then
        configure_git=true
        while true; do
            read -rp "Enter Git username: " git_username
            if [ -n "$git_username" ]; then
                break
            else
                echo -e "${RED}Username cannot be empty. Please try again.${RESET}"
            fi
        done
        while true; do
            read -rp "Enter Git email: " git_email
            if [[ "$git_email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
                break
            else
                echo -e "${RED}Invalid email format. Please try again.${RESET}"
            fi
        done
    fi

    echo ""
    local ssh_answer
    ssh_answer=$(validate_yes_no "Do you want to configure SSH? (y/n) ")
    if [[ "$ssh_answer" =~ ^[yY]$ ]]; then
        ssh_config_enabled=true

        local response
        while true; do
            read -rp "Import keys via URL or generate new keys? (url/gen) " response
            case "$response" in
                url|gen)
                    ssh_key_source="$response"
                    break
                    ;;
                *)
                    echo -e "${RED}Invalid input. Please enter 'url' or 'gen'.${RESET}"
                    ;;
            esac
        done

        if [[ "$ssh_key_source" == "url" ]]; then
            while true; do
                read -rp "Enter the URL for your SSH public key (e.g., https://github.com/user.keys): " key_url
                if [ -n "$key_url" ]; then
                    if [[ "$key_url" =~ ^https?:// ]]; then
                        break
                    else
                        echo -e "${RED}Invalid URL format. Must start with http:// or https://${RESET}"
                    fi
                else
                    echo -e "${RED}No URL provided. Defaulting to key generation.${RESET}"
                    ssh_key_source="gen"
                    break
                fi
            done
        fi
    fi
    echo ""
}

# update + install packages
update_install() {
    echo -e "${BLUE}Updating system packages${RESET}"
    (sudo DEBIAN_FRONTEND=noninteractive apt-get update -y >/dev/null 2>&1) & spinner $!
    echo -e "${GREEN}System updated${RESET}"
    echo -e "${BLUE}Installing required packages${RESET}"
    (sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}" >/dev/null 2>&1) & spinner $!
    echo -e "${GREEN}Packages installed${RESET}"
    echo -e "${BLUE}Upgrading system${RESET}"
    (sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y >/dev/null 2>&1) & spinner $!
    (sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove -y >/dev/null 2>&1) & spinner $!
    echo -e "${GREEN}Upgrade complete${RESET}"
}

# nano syntax highlighting
nano_syntax() {
    echo -e "${BLUE}Enabling nano syntax highlighting${RESET}"
    (
        if [ ! -f ~/.nanorc ]; then
            touch ~/.nanorc
        fi
        if ! grep -q "include /usr/share/nano/\*.nanorc" ~/.nanorc 2>/dev/null; then
            echo 'include /usr/share/nano/*.nanorc' >> ~/.nanorc
        fi
        if [ -d /usr/share/nano-syntax-highlighting ]; then
            if ! grep -q "include /usr/share/nano-syntax-highlighting/\*.nanorc" ~/.nanorc 2>/dev/null; then
                echo 'include /usr/share/nano-syntax-highlighting/*.nanorc' >> ~/.nanorc
            fi
        fi
    ) & spinner $!
    echo -e "${GREEN}Nano syntax highlighting enabled${RESET}"
}

# set hostname
set_hostname() {
    if [ -n "$new_hostname" ]; then
        echo -e "${BLUE}Setting hostname to $new_hostname${RESET}"
        (
            sudo hostnamectl set-hostname "$new_hostname"
            sudo sed -i "s/127.0.1.1.*/127.0.1.1\t$new_hostname/" /etc/hosts
        ) & spinner $!
        echo -e "${GREEN}Hostname set to $new_hostname${RESET}"
    fi
}

# configure Git
git_profile() {
    if [ "$configure_git" = true ] && [ -n "$git_username" ] && [ -n "$git_email" ]; then
        echo -e "${BLUE}Configuring Git profile${RESET}"
        (
            git config --global user.name "$git_username"
            git config --global user.email "$git_email"
        ) & spinner $!
        echo -e "${GREEN}Git configured: $git_username <$git_email>${RESET}"
    fi
}

# docker group usermods
usermods() {
    local user
    user="$(whoami)"
    echo -e "${BLUE}Adding $user to docker group${RESET}"
    (sudo usermod -aG docker "$user") & spinner $!
    echo -e "${GREEN}User added to docker group${RESET}"
}

# set aliases
set_aliases() {
    echo -e "${BLUE}Adding shell aliases${RESET}"
    (
        cp ~/.bashrc ~/.bashrc.bak
        add_alias "gs" "git status"
        add_alias "gc" "git clone"
        add_alias "gadd" "git add"
        add_alias "gcmt" "git commit -m"
        add_alias "gpull" "git pull"
        add_alias "gpush" "git push"
        add_alias "update" "sudo apt update && sudo apt upgrade -y"
        add_alias "install" "sudo apt install -y"
        add_alias "clean" "sudo apt autoremove --purge"
        add_alias "c" "clear"
        add_alias "h" "history"
        add_alias "df" "df -h"
        add_alias "du" "du -ch"
        add_alias "reload" "source ~/.bashrc"
        add_alias "shutdown" "sudo shutdown -h now"
        add_alias "reboot" "sudo reboot"
        add_alias "ll" "ls -lhA"
        add_alias "la" "ls -A"
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
    echo -e "${GREEN}Shell aliases added${RESET}"
}

# SSH + UFW hardening
ssh_ufw_hardening() {
    echo -e "${BLUE}Configuring UFW${RESET}"
    (sudo sed -i 's/IPV6=yes/IPV6=no/' /etc/default/ufw) & spinner $!
    echo -e "${GREEN}UFW IPv6 disabled${RESET}"
    
    if [ "$ssh_config_enabled" = true ]; then
        case "$ssh_key_source" in
            url)
                setup_ssh_dir
                echo -e "${BLUE}Fetching public key from URL${RESET}"
                if curl -sSL "$key_url" > ~/.ssh/authorized_keys && [ -s ~/.ssh/authorized_keys ]; then
                    chmod 700 ~/.ssh
                    chmod 600 ~/.ssh/authorized_keys
                    echo -e "${GREEN}Authorized keys added from $key_url${RESET}"
                else
                    echo -e "${RED}Failed to retrieve key from URL. Falling back to key generation.${RESET}"
                    ssh_key_source="gen"
                    setup_ssh_dir
                    generate_ssh_keys
                fi
                ;;
            gen)
                setup_ssh_dir
                generate_ssh_keys
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
            sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
        ) & spinner $!
        echo -e "${GREEN}SSH configuration hardened${RESET}"
        echo -e "${BLUE}Reloading SSH service${RESET}"
        (sudo systemctl reload ssh) & spinner $!
        echo -e "${GREEN}SSH service reloaded${RESET}"
    else
        echo -e "${YELLOW}Skipped SSH configuration${RESET}"
    fi
}

# timezone
timezone() {
    echo -e "${BLUE}Detecting timezone${RESET}"
    tmpfile=$(mktemp)
    curl -s 'http://ip-api.com/json/?fields=status,message,timezone' >"$tmpfile" &
    curl_pid=$!
    spinner "$curl_pid"
    wait "$curl_pid"
    status=$(jq -r '.status // empty' <"$tmpfile")

    if [ "$status" = "success" ]; then
        timezone=$(jq -r '.timezone // empty' <"$tmpfile")
    else
        timezone=""
    fi

    rm -f "$tmpfile"

    if [ -n "$timezone" ]; then
        (sudo timedatectl set-timezone "$timezone") & spinner $!
        echo -e "${GREEN}Timezone set to $timezone${RESET}"
    else
        echo -e "${YELLOW}Could not detect timezone, defaulting to America/New_York${RESET}"
        (sudo timedatectl set-timezone "America/New_York") & spinner $!
        timezone="America/New_York"
        echo -e "${GREEN}Timezone set to $timezone${RESET}"
    fi
}

# MOTD
motd() {
    local hostname_display
    hostname_display=$(hostname)
    echo -e "${BLUE}Creating MOTD${RESET}"
    (figlet "$hostname_display" | sudo tee /etc/motd >/dev/null) & spinner $!
    echo -e "${GREEN}MOTD created${RESET}"
}

# completion message
completion_message() {
    echo ""
    echo -e "${GREEN}================================${RESET}"
    echo -e "${GREEN}Setup Complete!${RESET}"
    echo -e "${GREEN}================================${RESET}"
    echo -e "Timezone: $timezone"

    if [ -n "$new_hostname" ]; then
        echo -e "Hostname: $new_hostname"
    fi

    if [ "$configure_git" = true ]; then
        echo -e "Git: $git_username <$git_email>"
    fi

    if [ "$ssh_config_enabled" = true ] && [ "$ssh_key_source" = "gen" ] && [ -f ~/.ssh/id_rsa ]; then
        echo ""
        echo -e "${RED}IMPORTANT: Save your private key before disconnecting${RESET}"
        echo -e "${YELLOW}Private key location: ~/.ssh/id_rsa${RESET}"
        echo ""
        cat ~/.ssh/id_rsa
        echo ""
    fi

    echo -e "${GREEN}================================${RESET}"
}

# main execution
initial_setup
update_install
nano_syntax
set_hostname
git_profile
usermods
set_aliases
ssh_ufw_hardening
timezone
motd

echo -e "${BLUE}Creating completion flag${RESET}"
(sudo touch "$flag_file") & spinner $!

completion_message

read -rp "Press Enter to reboot the system (or Ctrl+C to cancel)"

echo -e "${BLUE}Rebooting system${RESET}"
sleep 2
sudo reboot
