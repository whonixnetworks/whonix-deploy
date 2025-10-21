#!/usr/bin/env bash
# Home Lab Setup Script (Debian/Ubuntu)
# Automates initial configuration: updates, SSH hardening, Docker setup, and aliases.

set -euo pipefail

BLUE="\033[34m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

timezone="unknown"
flag_file="/var/log/setup-complete.flag"

packages=(
    btop tmux neofetch mc htop iotop iftop wget curl nano git coreutils
    rclone rsync python3 python3-pip figlet p7zip-full docker.io
    docker-compose-v2 wipe ufw openssh-server
)

spinner() {
    local pid=$1 delay=0.1 spinstr='|/-\'
    while kill -0 $pid 2>/dev/null; do
        printf " [%c]  " "$spinstr"
        spinstr=${spinstr#?}${spinstr%"${spinstr#?}"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "      \b\b\b\b\b\b"
}

add_alias() {
    local name="$1" cmd="$2"
    sed -i "/^alias $name=/d" ~/.bashrc
    echo "alias $name='$cmd'" >> ~/.bashrc
}

if [ -f "$flag_file" ]; then
    clear
    echo -e "${YELLOW}Setup already completed.${RESET}"
    echo "Delete $flag_file to rerun."
    exit 0
fi

clear
echo -e "${YELLOW}==============================================${RESET}"
echo -e "${YELLOW}   Debian/Ubuntu Home Lab Setup${RESET}"
echo -e "${YELLOW}==============================================${RESET}"
echo ""
echo -e "${RED}WARNING: This will disable SSH password login.${RESET}"
echo ""

read -p "Continue? (y/n): " ans
[[ "$ans" =~ ^[Yy]$ ]] || exit 0

echo "Checking sudo access..."
if ! sudo -v; then
    echo -e "${RED}Failed to get sudo access.${RESET}"
    exit 1
fi

read -p "Configure SSH? (y/n): " ssh_answer
if [[ "$ssh_answer" =~ ^[Yy]$ ]]; then
    read -p "Import existing SSH keys or generate new? (imp/gen): " key_choice
    if [ "$key_choice" = "imp" ]; then
        echo -e "${YELLOW}Paste your public key:${RESET}"
        read -r user_pubkey
        echo -e "${YELLOW}Paste your private key:${RESET}"
        read -r user_privkey
    fi
fi

update_install() {
    echo -e "${BLUE}Updating system...${RESET}"
    sudo apt-get update >/dev/null 2>&1 &
    spinner $!
    echo -e "${YELLOW}Done.${RESET}"

    echo -e "${BLUE}Installing packages...${RESET}"
    sudo apt-get install -y "${packages[@]}" >/dev/null 2>&1 &
    spinner $!
    echo -e "${YELLOW}Packages installed.${RESET}"

    echo -e "${BLUE}Upgrading system...${RESET}"
    sudo apt-get upgrade -y >/dev/null 2>&1 &
    spinner $!
    echo -e "${YELLOW}System upgraded.${RESET}"
}

usermods() {
    local user
    user=$(whoami)
    echo -e "${BLUE}Adding $user to docker group...${RESET}"
    sudo usermod -aG docker "$user" &
    spinner $!
    echo -e "${YELLOW}User added to docker group.${RESET}"
}

set_aliases() {
    echo -e "${BLUE}Adding common aliases...${RESET}"
    cp ~/.bashrc ~/.bashrc.bak
    add_alias "dcu" "docker compose up -d"
    add_alias "dcd" "docker compose down"
    add_alias "dcr" "docker compose restart"
    add_alias "dcp" "docker compose pull"
    add_alias "dcl" "docker compose logs -f"
    add_alias "dps" "docker ps --format '{{.Names}}'"
    add_alias "ndc" "nano docker-compose.yml"
    add_alias "nenv" "nano .env"
    echo -e "${YELLOW}Aliases added.${RESET}"
}

ssh_ufw_hardening() {
    echo -e "${BLUE}Configuring UFW...${RESET}"
    sudo sed -i 's/IPV6=yes/IPV6=no/' /etc/default/ufw &
    spinner $!
    echo -e "${YELLOW}IPv6 disabled in UFW.${RESET}"

    if [[ "$ssh_answer" =~ ^[Yy]$ ]]; then
        case "$key_choice" in
            imp)
                mkdir -p ~/.ssh
                echo "$user_pubkey" > ~/.ssh/authorized_keys
                chmod 644 ~/.ssh/authorized_keys
                [ -n "$user_privkey" ] && echo "$user_privkey" > ~/.ssh/id_rsa && chmod 600 ~/.ssh/id_rsa
                ;;
            *)
                mkdir -p ~/.ssh
                ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" >/dev/null 2>&1 &
                spinner $!
                cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys
                chmod 600 ~/.ssh/id_rsa
                chmod 644 ~/.ssh/authorized_keys
                echo -e "${YELLOW}SSH key generated at ~/.ssh/id_rsa${RESET}"
                ;;
        esac

        echo -e "${BLUE}Backing up and hardening SSH config...${RESET}"
        sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
        sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
        sudo sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
        sudo sed -i 's/^#\?UsePAM.*/UsePAM no/' /etc/ssh/sshd_config
        sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
        sudo systemctl reload ssh
        echo -e "${YELLOW}SSH hardened (key-only auth).${RESET}"
    else
        echo -e "${YELLOW}SSH setup skipped.${RESET}"
    fi
}

set_timezone() {
    echo -e "${BLUE}Detecting timezone...${RESET}"
    timezone=$(curl -s http://ip-api.com/line/?fields=timezone || echo "")
    if [ -n "$timezone" ]; then
        sudo timedatectl set-timezone "$timezone" >/dev/null 2>&1 &
        spinner $!
        echo -e "${YELLOW}Timezone set to $timezone${RESET}"
    else
        echo -e "${RED}Could not determine timezone.${RESET}"
    fi
}

figlet_motd() {
    echo -e "${BLUE}Creating MOTD...${RESET}"
    figlet "$(hostname)" | sudo tee /etc/motd >/dev/null
    echo -e "${YELLOW}MOTD updated.${RESET}"
}

exit_message() {
    clear
    echo -e "${YELLOW}================================${RESET}"
    echo -e "${YELLOW} Setup Complete! ${RESET}"
    echo -e "${YELLOW}================================${RESET}"
    echo "Timezone: ${timezone:-unknown}"
    if [ -f ~/.ssh/id_rsa ]; then
        echo -e "${RED}Don't forget to back up ~/.ssh/id_rsa${RESET}"
    fi
}

# ===== EXECUTION =====
#update_install
#usermods
set_aliases
ssh_ufw_hardening
set_timezone
figlet_motd

echo -e "${BLUE}Finalizing setup...${RESET}"
sudo touch "$flag_file"
exit_message

read -p "Press Enter to reboot..."
echo -e "${BLUE}Rebooting...${RESET}"
sleep 2
sudo reboot