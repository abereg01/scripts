#!/bin/bash
# sync_system.sh - Enhanced system synchronization script

# Directory structure
SYNC_DIR="$HOME/.system-sync"
BACKUP_DIR="$SYNC_DIR/backups/$(date +%Y%m%d)"

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
    
    # Get current packages (only names, no versions)
    echo "Generating package list..."
    pacman -Qqe | grep -vx "$(pacman -Qqm)" > "$temp_file"  # Explicitly installed non-AUR packages
    pacman -Qqm >> "$temp_file"                             # AUR packages
    
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

    # Sync the package list to Nextcloud
    echo "Syncing package list to Nextcloud..."
    rclone sync "$SYNC_DIR/installed_packages.txt" "nextcloud:abe/linux/system-backups/packages/"
}

# Function to install missing packages
install_packages() {
    # First, ensure we have the latest package list
    echo "Retrieving package list from Nextcloud..."
    mkdir -p "$SYNC_DIR"
    rclone sync "nextcloud:abe/linux/system-backups/packages/" "$SYNC_DIR/"

    if [ ! -f "$SYNC_DIR/installed_packages.txt" ]; then
        echo "No package list found!"
        return 1
    fi

    # Make sure yay is installed
    if ! command -v yay &> /dev/null; then
        echo "Installing yay first..."
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay || exit
        makepkg -si --noconfirm
        cd - || exit
    fi

    # Install packages
    while read -r package; do
        if ! yay -Qi "$package" &> /dev/null; then
            echo "Installing missing package: $package"
            yay -S --noconfirm "$package"
        fi
    done < "$SYNC_DIR/installed_packages.txt"
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

# Main execution
case "$1" in
    "backup")
        track_packages
        sync_ssh
        ;;
    "restore")
        # Restore SSH
        rclone sync "nextcloud:abe/linux/system-backups/ssh/" "$HOME/.ssh/"
        # Install missing packages
        install_packages
        # Setup config symlinks
        setup_symlinks
        ;;
    *)
        echo "Usage: $0 {backup|restore}"
        exit 1
        ;;
esac
