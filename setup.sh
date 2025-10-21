#!/usr/bin/env bash
# Home Lab Setup Script for Debian/Ubuntu
# Automates initial server configuration with package installation,
# SSH hardening, Docker setup, and useful aliases
# WARNING: This script disables SSH password authentication!

set -euo pipefail

# Color definitions
BLUE="\033[34m"
YELLOW="\033[33m"
RED="\033[31m"
GREEN="\033[32m"
RESET="\033[0m"

# Configuration
timezone="unknown"
packages=(btop tmux neofetch mc htop iotop iftop wget curl nano git coreutils rclone rsync python3 jq python3-pip figlet p7zip-full docker.io docker-compose-v2 wipe ufw openssh-server)
flag_file="/var/log/setup-complete.flag"

# Function to show spinner
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "      \b\b\b\b\b\b"
}

# System compatibility check
check_system() {
    echo -e "${BLUE}Checking system compatibility...${RESET}"
    
    # Ensure lsb_release or /etc/os-release exists
    if ! command -v lsb_release &>/dev/null && [ ! -f /etc/os-release ]; then
        echo -e "${RED}Unable to detect OS information. Exiting.${RESET}"
        return 1
    fi

    # Get distribution info
    if command -v lsb_release &>/dev/null; then
        distro=$(lsb_release -is 2>/dev/null | tr '[:upper:]' '[:lower:]')
    elif [ -f /etc/os-release ]; then
        distro=$(grep -E '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')
    fi

    # Check if apt exists
    if ! command -v apt-get &>/dev/null; then
        echo -e "${RED}This system does not use apt package manager. Exiting.${RESET}"
        return 1
    fi

    # Verify supported distributions
    case "$distro" in
        ubuntu|debian|linuxmint|pop|elementary|zorin|kali)
            echo -e "${GREEN}Detected supported distro: $distro${RESET}"
            return 0
            ;;
        *)
            echo -e "${RED}Unsupported distribution: $distro${RESET}"
            return 1
            ;;
    esac
}

# Function to add aliases without duplicates
add_alias() {
    local alias_name="$1"
    local alias_def="$2"
    if ! grep -q "^alias $alias_name=" ~/.bashrc 2>/dev/null; then
        echo "alias $alias_name='$alias_def'" >> ~/.bashrc
    fi
}

# Exit message for error
exit_message_error() {
    clear
    echo -e "${RED}Setup script has already executed${RESET}"
    sleep 0.2
    echo -e "${RED}Aborting script${RESET}"
}

# Check if script already ran
if [ -f "$flag_file" ]; then
    clear
    echo -e "${YELLOW}This script has already been run previously.${RESET}"
    echo -e "${YELLOW}To force re-run, delete $flag_file and try again${RESET}"
    exit_message_error
    exit 0
fi

clear

# ===== ALL QUESTIONS AT THE BEGINNING =====
echo -e "${YELLOW}==============================================${RESET}"
echo -e "${YELLOW}Home Lab Debian/Ubuntu Setup Script${RESET}"
echo -e "${YELLOW}==============================================${RESET}"
echo ""
echo -e "${RED}WARNING: This script can cause SSH lockouts${RESET}"
echo ""

# Run system check first
if ! check_system; then
    exit 1
fi

read -rp "Do you want to continue? (y/n) " answer
case "$answer" in
    [yY]*) ;;
    *) echo -e "${YELLOW}Exiting...${RESET}"; exit 0 ;;
esac

echo -e "${BLUE}This script requires sudo privileges${RESET}"
if ! sudo -v; then
    echo -e "${RED}Failed to obtain sudo privileges${RESET}"
    exit 1
fi

# SSH Configuration Questions
read -rp "Do you want to configure SSH? (y/n) " ssh_answer
if [[ "$ssh_answer" =~ ^[yY]$ ]]; then
    read -rp "Import existing SSH keys or generate new keys? (gen/imp) " paste_answer
    if [[ "$paste_answer" == "imp" ]]; then
        echo -e "${YELLOW}Please paste your SSH public key and press Enter:${RESET}"
        read -r user_pubkey
        echo -e "${YELLOW}Please paste your SSH private key and press Enter:${RESET}"
        read -r user_privkey
    fi
fi

# ===== MAIN SCRIPT FUNCTIONS =====
update_install() {
    echo -e "${BLUE}Updating system packages...${RESET}"
    sudo apt-get update >/dev/null 2>&1 &
    local update_pid=$!
    spinner $update_pid &
    local spinner_pid=$!
    wait $update_pid
    kill $spinner_pid 2>/dev/null || true
    echo -e "${GREEN}Updates complete${RESET}"
    
    echo -e "${BLUE}Installing packages...${RESET}"
    sudo apt-get install -y "${packages[@]}" >/dev/null 2>&1 &
    local install_pid=$!
    spinner $install_pid &
    local spinner_pid=$!
    wait $install_pid
    kill $spinner_pid 2>/dev/null || true
    echo -e "${GREEN}Packages installed${RESET}"
    
    echo -e "${BLUE}Upgrading system...${RESET}"
    sudo apt-get upgrade -y >/dev/null 2>&1 &
    local upgrade_pid=$!
    spinner $upgrade_pid &
    local spinner_pid=$!
    wait $upgrade_pid
    kill $spinner_pid 2>/dev/null || true
    echo -e "${GREEN}Upgrade complete${RESET}"
}

usermods() {
    local user
    user="$(whoami)"
    echo -e "${BLUE}Adding $user to docker group...${RESET}"
    sudo usermod -aG docker "$user" &
    local usermod_pid=$!
    spinner $usermod_pid &
    local spinner_pid=$!
    wait $usermod_pid
    kill $spinner_pid 2>/dev/null || true
    echo -e "${GREEN}User/Group modifications complete${RESET}"
}

set_aliases() {
    echo -e "${BLUE}Adding aliases to bashrc...${RESET}"
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
        add_alias "dps" 'docker ps --format '\''{{.Names}}'\'''
    ) &
    local aliases_pid=$!
    spinner $aliases_pid &
    local spinner_pid=$!
    wait $aliases_pid
    kill $spinner_pid 2>/dev/null || true
    echo -e "${GREEN}Aliases added to ~/.bashrc${RESET}"
}

ssh_ufw_hardening() {
    echo -e "${BLUE}Configuring UFW...${RESET}"
    sudo sed -i 's/IPV6=yes/IPV6=no/' /etc/default/ufw &
    local ufw_pid=$!
    spinner $ufw_pid &
    local spinner_pid=$!
    wait $ufw_pid
    kill $spinner_pid 2>/dev/null || true
    echo -e "${GREEN}UFW IPv6 disabled${RESET}"
    
    local user hostname
    user="$(whoami)"
    hostname="$(hostname)"
    
    if [[ "$ssh_answer" =~ ^[yY]$ ]]; then
        case "$paste_answer" in
            [iI][mM][pP]*)
                sudo rm -rf ~/.ssh
                mkdir -p ~/.ssh
                if [ -n "$user_pubkey" ]; then
                    echo -e "${BLUE}Adding your public key to authorized_keys...${RESET}"
                    (
                        echo "$user_pubkey" > ~/.ssh/authorized_keys
                        chmod 644 ~/.ssh/authorized_keys
                    ) &
                    local paste_pid=$!
                    spinner $paste_pid &
                    local spinner_pid=$!
                    wait $paste_pid
                    kill $spinner_pid 2>/dev/null || true
                    echo -e "${GREEN}Public key added successfully${RESET}"
                    
                    if [ -n "$user_privkey" ]; then
                        echo -e "${BLUE}Adding your private key to ~/.ssh...${RESET}"
                        (
                            echo "$user_privkey" > ~/.ssh/id_rsa
                            chmod 600 ~/.ssh/id_rsa
                        ) &
                        local pasteid_pid=$!
                        spinner $pasteid_pid &
                        local spinner_pid=$!
                        wait $pasteid_pid
                        kill $spinner_pid 2>/dev/null || true
                        echo -e "${GREEN}Private key added successfully${RESET}"
                    fi
                else
                    echo -e "${RED}No key provided, skipping...${RESET}"
                fi
                ;;
            *)
                echo -e "${YELLOW}Generating new SSH keys...${RESET}"
                echo -e "${BLUE}Generating RSA keys${RESET}"
                sudo rm -rf ~/.ssh
                mkdir -p ~/.ssh
                ssh-keygen -t rsa -b 4096 -C "${user}@${hostname}" -f ~/.ssh/id_rsa -N "" -q &
                local keygen_pid=$!
                spinner $keygen_pid &
                local spinner_pid=$!
                wait $keygen_pid
                kill $spinner_pid 2>/dev/null || true
                
                echo -e "${BLUE}Setting up authorized_keys...${RESET}"
                (
                    cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys
                    chmod 644 ~/.ssh/authorized_keys
                    chmod 600 ~/.ssh/id_rsa
                ) &
                local setup_pid=$!
                spinner $setup_pid &
                local spinner_pid=$!
                wait $setup_pid
                kill $spinner_pid 2>/dev/null || true
                echo -e "${GREEN}SSH keys generated${RESET}"
                
                echo ""
                echo -e "${YELLOW}================================${RESET}"
                echo -e "${YELLOW}YOUR PRIVATE KEY (save this):${RESET}"
                echo -e "${YELLOW}================================${RESET}"
                cat ~/.ssh/id_rsa
                echo -e "${YELLOW}================================${RESET}"
                echo ""
                echo -e "${RED}IMPORTANT: Your private key is at ~/.ssh/id_rsa${RESET}"
                echo -e "${RED}You MUST copy it before disconnecting!${RESET}"
                echo ""
                ;;
        esac
        
        echo -e "${BLUE}Creating SSH config backup...${RESET}"
        sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak &
        local cp_pid=$!
        spinner $cp_pid &
        local spinner_pid=$!
        wait $cp_pid
        kill $spinner_pid 2>/dev/null || true
        echo -e "${GREEN}Backup created at /etc/ssh/sshd_config.bak${RESET}"
        
        echo -e "${BLUE}Hardening SSH configuration...${RESET}"
        (
            sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
            sudo sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
            sudo sed -i 's/^#\?KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/' /etc/ssh/sshd_config
            sudo sed -i 's/^#\?UsePAM.*/UsePAM no/' /etc/ssh/sshd_config
            sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
        ) &
        local sed_pid=$!
        spinner $sed_pid &
        local spinner_pid=$!
        wait $sed_pid
        kill $spinner_pid 2>/dev/null || true
        
        echo -e "${BLUE}Reloading SSH service...${RESET}"
        sudo systemctl reload ssh &
        local reload_pid=$!
        spinner $reload_pid &
        local spinner_pid=$!
        wait $reload_pid
        kill $spinner_pid 2>/dev/null || true
        echo -e "${GREEN}SSH configured for key-only authentication${RESET}"
    else
        echo -e "${YELLOW}Skipping SSH configuration...${RESET}"
    fi
}

set_timezone() {
    echo -e "${BLUE}Setting timezone...${RESET}"
    timezone=$(curl -s http://ip-api.com/line/?fields=timezone 2>/dev/null || echo "") &
    local curl_pid=$!
    spinner $curl_pid &
    local spinner_pid=$!
    wait $curl_pid
    kill $spinner_pid 2>/dev/null || true
    
    if [ -n "$timezone" ]; then
        sudo timedatectl set-timezone "$timezone" 2>/dev/null &
        local tz_pid=$!
        spinner $tz_pid &
        local spinner_pid=$!
        wait $tz_pid
        kill $spinner_pid 2>/dev/null || true
        echo -e "${GREEN}Timezone set to $timezone${RESET}"
    else
        echo -e "${YELLOW}Could not determine timezone automatically${RESET}"
        timezone="unknown"
    fi
}

figlet_motd() {
    echo -e "${BLUE}Creating MOTD...${RESET}"
    (
        figlet "$(hostname)" | sudo tee /etc/motd >/dev/null
    ) &
    local motd_pid=$!
    spinner $motd_pid &
    local spinner_pid=$!
    wait $motd_pid
    kill $spinner_pid 2>/dev/null || true
    echo -e "${GREEN}MOTD set${RESET}"
}

exit_message() {
    clear
    echo -e "${GREEN}================================${RESET}"
    echo -e "${GREEN}Setup Complete!${RESET}"
    echo -e "${GREEN}================================${RESET}"
    echo -e "Timezone set to ${timezone:-unknown}"
    echo ""
    if [ -f ~/.ssh/id_rsa ]; then
        echo -e "${RED}REMINDER: Save your private key from ~/.ssh/id_rsa${RESET}"
        echo ""
    fi
}

# Main
echo -e "${BLUE}Starting system setup...${RESET}"

update_install
usermods
set_aliases
ssh_ufw_hardening
set_timezone
figlet_motd

echo -e "${BLUE}Creating completion flag...${RESET}"
sudo touch "$flag_file" &
local flag_pid=$!
spinner $flag_pid &
local spinner_pid=$!
wait $flag_pid
kill $spinner_pid 2>/dev/null || true

exit_message

read -rp "Press Enter to reboot the system (or Ctrl+C to cancel)..."
echo -e "${BLUE}Rebooting system...${RESET}"
sleep 2
sudo reboot