#!/bin/bash
# disk-space-analyzer.sh - A comprehensive disk space analysis script for Arch Linux

echo "======== DISK SPACE ANALYZER ========"
echo "Running disk space analysis on $(hostname)"
echo "Date: $(date)"
echo "===============================\n"

# 1. Overall disk usage summary
echo "### FILESYSTEM USAGE SUMMARY ###"
df -h | grep -v tmp
echo -e "\n"

# 2. Largest directories in root filesystem (top 15)
echo "### TOP 15 LARGEST DIRECTORIES ###"
sudo du -h --max-depth=2 / 2>/dev/null | sort -hr | head -15
echo -e "\n"

# 3. User home directories usage
echo "### USER HOME DIRECTORIES USAGE ###"
sudo du -h --max-depth=1 /home 2>/dev/null | sort -hr
echo -e "\n"

# 4. Package management space usage
echo "### PACKAGE MANAGEMENT SPACE USAGE ###"
echo "Pacman cache size:"
sudo du -sh /var/cache/pacman/pkg/ 2>/dev/null
echo -e "\nPacman database size:"
sudo du -sh /var/lib/pacman/ 2>/dev/null
echo -e "\n"

# 5. Log files space usage
echo "### LOG FILES SPACE USAGE ###"
sudo du -sh /var/log/ 2>/dev/null
echo "Largest log files:"
sudo find /var/log -type f -exec du -h {} \; 2>/dev/null | sort -hr | head -10
echo -e "\n"

# 6. Temporary files
echo "### TEMPORARY FILES USAGE ###"
sudo du -sh /tmp /var/tmp 2>/dev/null
echo -e "\n"

# 7. Docker usage (if installed)
if command -v docker &> /dev/null; then
    echo "### DOCKER USAGE ###"
    sudo du -sh /var/lib/docker 2>/dev/null
    echo "Docker images:"
    docker images --format "{{.Repository}}:{{.Tag}} - {{.Size}}" 2>/dev/null
    echo -e "\n"
fi

# 8. Find largest files (> 500MB) in the filesystem
echo "### LARGEST FILES (>500MB) ###"
sudo find / -type f -size +500M -exec ls -lh {} \; 2>/dev/null | sort -k5hr
echo -e "\n"

# 9. Check for deleted but open files (potentially reclaiming space)
echo "### DELETED BUT OPEN FILES ###"
sudo lsof +L1 2>/dev/null | grep -v "mem"
echo -e "\n"

# 10. Potential cleanup options
echo "### POTENTIAL CLEANUP OPTIONS ###"
echo "1. Clear pacman cache:"
echo "   sudo pacman -Sc"
echo "2. Remove orphaned packages:"
echo "   sudo pacman -Rns \$(pacman -Qtdq)"
echo "3. Clear journal logs:"
echo "   sudo journalctl --vacuum-time=1week"
echo "4. Clean temporary files:"
echo "   sudo rm -rf /tmp/* /var/tmp/*"
echo "5. Clean old snapshots or backups (if applicable)"
echo "6. Remove unused Docker images (if applicable):"
echo "   docker system prune -a"

echo -e "\n### ANALYSIS COMPLETE ###"
