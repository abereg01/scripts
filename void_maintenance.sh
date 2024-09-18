#!/bin/bash

# Void Linux Maintenance Script

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    echo -e "${YELLOW}===========================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${YELLOW}===========================${NC}"
}

# Function to check if a command was successful
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Success${NC}"
    else
        echo -e "${RED}Failed${NC}"
    fi
}

# Update package repositories
update_repos() {
    print_message "Updating package repositories"
    sudo xbps-install -S
    check_status
}

# Upgrade all packages
upgrade_packages() {
    print_message "Upgrading all packages"
    sudo xbps-install -u
    check_status
}

# Remove old kernels
remove_old_kernels() {
    print_message "Removing old kernels"
    sudo vkpurge rm all
    check_status
}

# Clean package cache
clean_cache() {
    print_message "Cleaning package cache"
    sudo xbps-remove -O
    check_status
}

# Remove orphaned packages
remove_orphans() {
    print_message "Removing orphaned packages"
    sudo xbps-remove -o
    check_status
}

# Check for and install updates to flatpak applications
update_flatpaks() {
    if command -v flatpak &> /dev/null; then
        print_message "Updating Flatpak applications"
        flatpak update -y
        check_status
    else
        echo "Flatpak is not installed. Skipping Flatpak updates."
    fi
}

# Main function to run all maintenance tasks
main() {
    print_message "Starting Void Linux maintenance"
    
    update_repos
    upgrade_packages
    remove_old_kernels
    clean_cache
    remove_orphans
    update_flatpaks
    
    print_message "Maintenance complete"
}

# Run the main function
main
