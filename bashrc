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
    REPO_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -z "$REPO_NAME" ]; then
        echo "Not a Git repository (or no .git directory found)."
        return 1
    fi
    LAST_COMMIT=$(git log -1 --pretty=format:"%ad^%s" --date=format:'%Y-%m-%d %H:%M:%S' HEAD)
    LAST_COMMIT_DATE=$(echo "$LAST_COMMIT" | cut -d'^' -f1)
    LAST_COMMIT_MESSAGE=$(echo "$LAST_COMMIT" | cut -d'^' -f2)
    echo "--- Git Status (gstat) ---"
    echo "--------------------------"
    echo "RREPOSITORY: $REPO_NAME"
    echo "BRANCH: $CURRENT_BRANCH"
    echo "LAST COMMIT: $LAST_COMMIT_DATE"
    echo "MESSAGE: $LAST_COMMIT_MESSAGE"
    echo "--------------------------"
}

cpustat() {
  a=($(grep 'cpu ' /proc/stat));
  idle1=${a[4]};
  total1=$((${a[1]}+${a[2]}+${a[3]}+${a[4]}+${a[5]}+${a[6]}+${a[7]}));
  sleep 1;
  a=($(grep 'cpu ' /proc/stat));
  idle2=${a[4]};
  total2=$((${a[1]}+${a[2]}+${a[3]}+${a[4]}+${a[5]}+${a[6]}+${a[7]}));
  usage=$(echo "scale=2; 100*(1-($idle2-$idle1)/($total2-$total1))" | bc);
  echo "CPU: ${usage}%";
}
