# System alias
#alias reload='source ~/.bashrc'
alias reboot='sudo reboot'
alias shutdown='shutdown -h now'
alias c='clear'
alias h='history'
alias dfc='df -h .'
alias du='du -ch'
alias bat='batcat'
alias reload='source ~/.zshrc'

# Git aliases
alias gc='git clone'
alias gpush='git push'
alias gpull='git pull'
alias gadd='git add .'
alias gcmt='git commit -m'

# Docker aliases
alias cdc='cat docker-compose.yml'
alias rmdc='rm docker-compose.yml'
alias ndc='nano docker-compose.yml'
alias nenv='nano .env'
alias rmenv='rm .env'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcr='docker compose restart'
alias dcp='docker compose pull'
alias dcl='docker compose logs -f'
alias dps='docker ps --format '{{.Names}}''

# Function alias
update() {
    echo "Updating..."
    sudo apt update
    sudo apt upgrade -y
    sudo apt autoremove --purge -y
    echo "Updates complete"
}

gforce() {
    git add .
    git commit -m "$1"
    git push
}

gstat() {
    RED="\033[1;31m"
    GREEN="\033[1;32m"
    WHITE="\033[0;37m"
    RESET="\033[0m"

    REPO_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

    if [ -z "$REPO_NAME" ]; then
        echo -e "${GREEN}Not a Git repository (or no .git directory found).${RESET}"
        return 1
    fi

    LAST_COMMIT=$(git log -1 --pretty=format:"%ad^%s" --date=format:'%Y-%m-%d %H:%M:%S' HEAD)
    LAST_COMMIT_DATE=$(echo "$LAST_COMMIT" | cut -d'^' -f1)
    LAST_COMMIT_MESSAGE=$(echo "$LAST_COMMIT" | cut -d'^' -f2)

    echo
    echo -e "${RED}--- Git Status (gstat) ---${RESET}"
    echo -e "${RED}--------------------------${RESET}"
    echo -e "${GREEN}REPOSITORY:${RESET} ${WHITE}$REPO_NAME${RESET}"
    echo -e "${GREEN}BRANCH:${RESET} ${WHITE}$CURRENT_BRANCH${RESET}"
    echo -e "${GREEN}LAST COMMIT:${RESET} ${WHITE}$LAST_COMMIT_DATE${RESET}"
    echo -e "${GREEN}MESSAGE:${RESET} ${WHITE}$LAST_COMMIT_MESSAGE${RESET}"
    echo -e "${RED}--------------------------${RESET}"
}


sstat() {
    RED="\033[1;31m"
    GREEN="\033[1;32m"
    WHITE="\033[0;37m"
    RESET="\033[0m"
    a=($(grep 'cpu ' /proc/stat))
    idle1=${a[4]}
    total1=$((${a[1]}+${a[2]}+${a[3]}+${a[4]}+${a[5]}+${a[6]}+${a[7]}))
    sleep 1
    a=($(grep 'cpu ' /proc/stat))
    idle2=${a[4]}
    total2=$((${a[1]}+${a[2]}+${a[3]}+${a[4]}+${a[5]}+${a[6]}+${a[7]}))
    CPU_USAGE=$(echo "scale=2; 100*(1-($idle2-$idle1)/($total2-$total1))" | bc)
    MEM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    MEM_FREE=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    MEM_USED=$((MEM_TOTAL - MEM_FREE))
    MEM_PERCENT=$(echo "scale=2; $MEM_USED*100/$MEM_TOTAL" | bc)
    MEM_USED_MB=$(echo "scale=0; $MEM_USED/1024" | bc)
    MEM_TOTAL_MB=$(echo "scale=0; $MEM_TOTAL/1024" | bc)

    echo
    echo -e "${RED}--- System Status (sstat) ---${RESET}"
    echo -e "${RED}--------------------------${RESET}"
    echo -e "${GREEN}CPU USAGE:${RESET} ${WHITE}${CPU_USAGE}%${RESET}"
    echo -e "${GREEN}MEMORY USAGE:${RESET} ${WHITE}${MEM_USED_MB}MB / ${MEM_TOTAL_MB}MB (${MEM_PERCENT}%)${RESET}"
    echo -e "${RED}--------------------------${RESET}"
}

