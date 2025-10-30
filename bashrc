gforce() {
    git add .
    git commit -m "$1"
    git push
}

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
