#!/bin/bash
# sync_system.sh - Enhanced system synchronization script

# Directory structure
SYNC_DIR="$HOME/.system-sync"
BACKUP_DIR="$SYNC_DIR/backups/$(date +%Y%m%d)"
CONFIG_FILE="$SYNC_DIR/sync-config.conf"

# Git repositories to manage
REPOS=(
    "$HOME/dotfiles"
    "$HOME/lib/scripts"
    "$HOME/lib/images/wallpapers"
)

# Create necessary directories
mkdir -p "$SYNC_DIR" "$BACKUP_DIR"

# Function to backup and sync .ssh directory
sync_ssh() {
    echo "Syncing SSH directory..."
    rclone sync "$HOME/.ssh" "nextcloud:abe/linux/system-backups/ssh/"
}

# Function to track installed packages
track_packages() {
    local temp_file="$SYNC_DIR/temp_packages.txt"
    
    # Ensure SYNC_DIR exists
    mkdir -p "$SYNC_DIR"
    
    # Get current packages
    echo "Generating package list..."
    pacman -Qe > "$temp_file"
    pacman -Qm >> "$temp_file"
    
    if [ ! -f "$SYNC_DIR/installed_packages.txt" ]; then
        echo "Creating initial package list..."
        mv "$temp_file" "$SYNC_DIR/installed_packages.txt"
    else
        if ! cmp -s "$temp_file" "$SYNC_DIR/installed_packages.txt"; then
            echo "Package list has changed, updating..."
            mv "$temp_file" "$SYNC_DIR/installed_packages.txt"
        else
            echo "No changes in package list."
            rm "$temp_file"
        fi
    fi
}

# Function to manage config symlinks
setup_symlinks() {
    local config_dir="$HOME/dotfiles/configs"
    local target_dir="$HOME/.config"
    
    # Create .config directory if it doesn't exist
    mkdir -p "$target_dir"
    
    # Loop through each directory in configs/
    for dir in "$config_dir"/*; do
        if [ -d "$dir" ]; then
            base_name=$(basename "$dir")
            target="$target_dir/$base_name"
            
            # Remove existing directory or symlink
            rm -rf "$target"
            
            # Create symlink
            echo "Creating symlink for $base_name"
            ln -sf "$dir" "$target"
        fi
    done
}

# Function to install missing packages
install_packages() {
    while read -r package; do
        if ! pacman -Qi "$package" >/dev/null 2>&1; then
            echo "Installing missing package: $package"
            yay -S --noconfirm "$package"
        fi
    done < "$SYNC_DIR/installed_packages.txt"
}

# Function to sync fonts
sync_fonts() {
    local fonts_dir="$HOME/.local/share/fonts"
    if [[ -n "$(diff -r "$fonts_dir" "$BACKUP_DIR/fonts" 2>/dev/null)" ]] || [[ ! -d "$BACKUP_DIR/fonts" ]]; then
        echo "Changes detected in fonts, syncing..."
        rclone sync "$fonts_dir" nextcloud:system-backups/fonts/
    else
        echo "No changes in fonts, skipping..."
    fi
}

# Function to update a single repository
update_repo() {
    local repo=$1
    echo "Processing repository: $repo"
    if [ -d "$repo/.git" ]; then
        cd "$repo" || exit
        if [ -n "$(git status --porcelain)" ]; then
            git add .
            git commit -m "Auto update $(date)"
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

# Main execution
case "$1" in
    "backup")
        track_packages
        sync_ssh
        sync_fonts
        ;;
    "restore")
        # Restore fonts and SSH
        rclone sync "nextcloud:abe/linux/system-backups/fonts/" "$HOME/.local/share/fonts/"
        rclone sync nextcloud:system-backups/ssh/ "$HOME/.ssh/"
        # Install missing packages
        install_packages
        # Setup config symlinks
        setup_symlinks
        ;;
    "push")
        # First run backup
        "$0" backup
        # Then update all git repositories
        for repo in "${REPOS[@]}"; do
            update_repo "$repo"
        done
        ;;
    "pull")
        # First update system
        echo "Updating system packages..."
        yay -Syuu
        # Pull all repositories
        for repo in "${REPOS[@]}"; do
            pull_repo "$repo"
        done
        # Then run restore
        "$0" restore
        ;;
    *)
        echo "Usage: $0 {backup|restore|push|pull}"
        exit 1
        ;;
esac
