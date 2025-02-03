#!/bin/bash

# Array of repositories to update
repos=(
    "$HOME/dotfiles"
    "$HOME/lib/scripts"
    "$HOME/lib/images/wallpapers"
)

# Path to sync_system script
SYNC_SCRIPT="$HOME/lib/scripts/functions/sync_system.sh"

# Function to update a single repository
update_repo() {
    local repo=$1
    echo "Updating repository: $repo"
    if [ -d "$repo/.git" ]; then
        cd "$repo" || exit
        # Check if there are changes to commit
        if [ -n "$(git status --porcelain)" ]; then
            git add .
            git commit -m "update"
            git push
            echo "✓ Successfully updated $repo"
        else
            echo "→ No changes in $repo"
        fi
    else
        echo "✗ Error: $repo is not a git repository"
    fi
    echo "-------------------"
}

# Function to pull a single repository
pull_repo() {
    local repo=$1
    echo "Pulling repository: $repo"
    if [ -d "$repo/.git" ]; then
        cd "$repo" || exit
        git pull
        echo "✓ Successfully pulled $repo"
    else
        echo "✗ Error: $repo is not a git repository"
    fi
    echo "-------------------"
}

# Function to handle push operation
handle_push() {
    echo "Pushing changes to all repositories..."
    for repo in "${repos[@]}"; do
        update_repo "$repo"
    done
    
    echo "Running system sync backup..."
    $SYNC_SCRIPT backup
    
    echo "All push operations completed!"
}

# Function to handle pull operation
handle_pull() {
    echo "Updating system packages..."
    yay -Syuu
    
    echo "Pulling all repositories..."
    for repo in "${repos[@]}"; do
        pull_repo "$repo"
    done
    
    echo "Running system sync restore..."
    $SYNC_SCRIPT restore
    
    echo "All pull operations completed!"
}

# Main script execution
echo "Choose operation:"
echo "1. Push (push git repos and backup to Nextcloud)"
echo "2. Pull (update system, pull repos, and restore from Nextcloud)"
read -p "Enter your choice (1/2): " choice

case $choice in
    1)
        handle_push
        ;;
    2)
        handle_pull
        ;;
    *)
        echo "Invalid choice. Please enter 1 for push or 2 for pull."
        exit 1
        ;;
esac
