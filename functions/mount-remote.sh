#!/bin/bash

# Read available hosts from ~/.ssh/config
hosts=$(grep -E "^Host " ~/.ssh/docker-swarm-config | awk '{print $2}' | grep -v '*' | sort)

# Prompt user to select a host
echo "Available SSH hosts:"
select host in $hosts; do
    if [[ -n "$host" ]]; then
        break
    else
        echo "Invalid selection. Try again."
    fi
done

# Define mount point
MOUNT_POINT=~/remote-server

# Create mount point if it doesn't exist
mkdir -p "$MOUNT_POINT"

# Mount using SSHFS
echo "Mounting $host at $MOUNT_POINT..."
sshfs "$host":/ "$MOUNT_POINT"

echo "Done! Remote server mounted at $MOUNT_POINT"

