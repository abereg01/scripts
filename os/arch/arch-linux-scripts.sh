#!/bin/bash

# 1. System Update and Cleanup Script
update_and_cleanup() {
    echo "Updating system and cleaning up..."
    sudo pacman -Syu
    sudo pacman -Sc
    sudo pacman -Rns $(pacman -Qtdq)
    sudo journalctl --vacuum-time=2weeks
    sudo updatedb
    echo "System updated and cleaned."
}

# 3. Backup Home Directory Script
backup_home() {
    echo "Backing up home directory..."
    backup_dir="/path/to/backup/directory"
    rsync -avz --exclude='.cache' $HOME $backup_dir
    echo "Backup completed."
}

# 4. System Resource Monitor
monitor_resources() {
    echo "Monitoring system resources. Press Ctrl+C to exit."
    while true; do
        clear
        echo "CPU Usage:"
        mpstat 1 1 | awk '/Average:/ {print 100-$NF"%"}'
        echo "Memory Usage:"
        free -m | awk 'NR==2{printf "%.2f%%\n", $3*100/$2}'
        echo "Disk Usage:"
        df -h | awk '$NF=="/"{printf "%s\n", $5}'
        sleep 5
    done
}

# 5. Network Speed Test
test_network_speed() {
    echo "Testing network speed..."
    curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -
}

# Main menu
while true; do
    echo "
    Arch Linux Utility Scripts
    1. Update System and Cleanup
    2. Backup Home Directory
    3. Monitor System Resources
    4. Test Network Speed
    Q. Exit
    "
    read -p "Enter your choice: " choice
    case $choice in
        1) update_and_cleanup ;;
        3) backup_home ;;
        4) monitor_resources ;;
        5) test_network_speed ;;
        q) exit 0 ;;
        *) echo "Invalid option" ;;
    esac
    echo "Press Enter to continue..."
    read
done
