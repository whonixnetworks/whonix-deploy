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
    LAST_COMMIT=$(git log -1 --pretty=format:"%ad^%s" --date=format:'%Y-%m-%d %H:%M:%S' HEAD)Jake1996!
    LAST_COMMIT_DATE=$(echo "$LAST_COMMIT" | cut -d'^' -f1)
    LAST_COMMIT_MESSAGE=$(echo "$LAST_COMMIT" | cut -d'^' -f2)
    echo "--- Git Status (gstat) ---"
    echo "**Repository:** $REPO_NAME"
    echo "**Branch:** $CURRENT_BRANCH"
    echo "---"
    echo "**Last Commit:** $LAST_COMMIT_DATE"
    echo "**Message:** $LAST_COMMIT_MESSAGE"
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

alias reboot='sudo reboot'
alias shutdown='shutdown -h now'

alias dev='cd /home/whonix/dev/github'
alias devsw='cd /home/whonix/dev/github/syncwarden'

alias py='python3'
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
#alias cpuuse='cpuusage() {   a=($(grep 'cpu ' /proc/stat));   idle1=${a[4]};   total1=$((${a[1]}+${a[2]}+${a[3]}+${a[4]}+${a[5]}+${a[6]}+${a[7]}));   sleep 1;   a=($(grep 'cpu ' /proc/stat));   idle2=${a[4]};   total2=$((${a[1]}+${a[2]}+${a[3]}+${a[4]}+${a[5]}+${a[6]}+${a[7]}));   usage=$(echo "scale=2; 100*(1-($idle2-$idle1)/($total2-$total1))" | bc);   echo "CPU: ${usage}%"; }'
alias mount='./dev/github/scripts/rclone/new.sh "mount"'
alias unmount='./dev/github/scripts/rclone/new.sh "unmount"'
alias gpuded='sudo system76-power graphics nvidia && sudo reboot'
alias gpuhyb='sudo system76-power graphics hybrid && sudo reboot'
alias gpuint='sudo system76-power graphics integrated && sudo reboot'
alias gpumd='system76-power graphics'

gstat() {
    # 1. Get the repository name (directory name)
    REPO_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")
    
    # 2. Get the current branch name
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    
    # Check if we are in a Git repository
    if [ -z "$REPO_NAME" ]; then
        echo "❌ Not a Git repository (or no .git directory found)."
        return 1
    fi

    # 3. Get the last commit time/date and message
    # --pretty=format:... allows us to define a custom output format for the log
    LAST_COMMIT=$(git log -1 --pretty=format:"%ad^%s" --date=format:'%Y-%m-%d %H:%M:%S' HEAD)
    
    # Split the commit info into date and message
    LAST_COMMIT_DATE=$(echo "$LAST_COMMIT" | cut -d'^' -f1)
    LAST_COMMIT_MESSAGE=$(echo "$LAST_COMMIT" | cut -d'^' -f2)

    echo "--- Git Status (gstat) ---"
    echo "📦 **Repository:** $REPO_NAME"
    echo "🌳 **Branch:** $CURRENT_BRANCH"
    echo "---"
    echo "🕒 **Last Commit:** $LAST_COMMIT_DATE"
    echo "💬 **Message:** $LAST_COMMIT_MESSAGE"
    echo "--------------------------"
}

alias bat='batcat'

gforce() {
    git add .
    git commit -m "$1"
    git push
}


alias reboot='sudo reboot'
alias shutdown='shutdown -h now'

alias gc='git clone'
alias gpush='git push'
alias gpull='git pull'
alias gadd='git add .'


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

alias jekyll='cd Documents/jekyll && bundle exec jekyll serve --host 0.0.0.0'
# Install Ruby Gems to ~/gems
export GEM_HOME="$HOME/gems"
export PATH="$HOME/gems/bin:$PATH"

# Added by `rbenv init` on Wed Oct 22 06:20:07 PM ACDT 2025
eval "$(~/.rbenv/bin/rbenv init - --no-rehash bash)"
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
alias gs='git status'
alias gcmt='git commit -m'
alias update='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install -y'
alias clean='sudo apt autoremove --purge'
alias c='clear'
alias h='history'
alias df='df -h'
alias du='du -ch'
alias reload='source ~/.bashrc'
alias bat='batcat'







alias bat='batcat'

alias bat='batcat'

alias bat='batcat'



alias gc='git clone'
alias gpush='git push'
alias gpull='git pull'
alias gadd='git add .'


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

alias jekyll='cd Documents/jekyll && bundle exec jekyll serve --host 0.0.0.0'
# Install Ruby Gems to ~/gems
export GEM_HOME="$HOME/gems"
export PATH="$HOME/gems/bin:$PATH"

# Added by `rbenv init` on Wed Oct 22 06:20:07 PM ACDT 2025
eval "$(~/.rbenv/bin/rbenv init - --no-rehash bash)"
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
alias gs='git status'
alias gcmt='git commit -m'
alias update='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install -y'
alias clean='sudo apt autoremove --purge'
alias c='clear'
alias h='history'
alias df='df -h'
alias du='du -ch'
alias reload='source ~/.bashrc'
