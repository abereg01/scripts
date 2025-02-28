#!/bin/bash
# setup_remote_access.sh

SERVERS=(
    "172.20.0.21"
    "172.20.96.18"
    "172.20.0.22"
    "172.20.0.23"
    "172.20.0.24"
    "172.20.96.24"
    "172.20.96.19"
    "172.20.96.16"
)

# Get the public key content
PUBLIC_KEY=$(cat $HOME/clementine/keys/clementine.pub)

for server in "${SERVERS[@]}"; do
    echo "Setting up SSH access for digit@$server..."
    
    # You'll need to enter digit's password once per server during setup
    ssh digit@$server "
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        echo '$PUBLIC_KEY' >> ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
    "
done
