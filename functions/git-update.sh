#!/bin/bash

# Array of repositories to update
repos=(
    "$HOME/dotfiles"
    "$HOME/lib/scripts"
    "$HOME/lib/images/wallpapers"
)

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

# Update all repositories
for repo in "${repos[@]}"; do
    update_repo "$repo"
done

echo "All repositories processed!"
