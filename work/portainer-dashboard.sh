#!/bin/bash

# Colors and styling
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration file path
CONFIG_FILE="$HOME/lib/work/config.json"

# Global arrays for tunnel management
declare -A SSH_TUNNELS
declare -A LOCAL_PORTS

# Dependencies check
check_dependencies() {
    local deps=("jq" "curl" "ssh" "nc")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" > /dev/null 2>&1; then
            echo "Error: $dep is required but not installed."
            case $dep in
                "nc") echo "Install with: yay -S openbsd-netcat";;
                "jq") echo "Install with: yay -S jq";;
                "curl") echo "Install with: yay -S curl";;
            esac
            exit 1
        fi
    done
}

# Find available local port
find_available_port() {
    local port=49152
    while netstat -tuln | grep -q ":$port "; do
        port=$((port + 1))
    done
    echo "$port"
}

# Setup SSH tunnel
setup_ssh_tunnel() {
    local server_ip=$1
    local user=$2
    local remote_port=$3
    local ssh_key=$4
    
    local local_port
    local_port=$(find_available_port)
    
    echo "Debug: Setting up tunnel from localhost:$local_port to $server_ip:$remote_port"
    
    # Store the local port in the global array
    LOCAL_PORTS["$server_ip"]="$local_port"
    
    # Test SSH connection first
    if ! ssh -i "$ssh_key" -o ConnectTimeout=5 "${user}@${server_ip}" echo "SSH test successful"; then
        echo "Failed to connect to $server_ip via SSH"
        return 1
    fi
    
    # Setup the tunnel
    ssh -f -N -L "$local_port:localhost:$remote_port" \
        -i "$ssh_key" \
        "${user}@${server_ip}"
    
    local tunnel_status=$?
    
    if [ $tunnel_status -eq 0 ]; then
        SSH_TUNNELS["$server_ip"]=$!
        echo "SSH tunnel established for $server_ip on local port $local_port"
        # Verify the tunnel is working
        sleep 2
        if nc -z localhost "$local_port" 2>/dev/null; then
            echo "Port $local_port is now listening"
            return 0
        else
            echo "Port $local_port is not listening after tunnel setup"
            return 1
        fi
    else
        echo "Failed to establish SSH tunnel for $server_ip (Exit code: $tunnel_status)"
        return 1
    fi
}

# Cleanup SSH tunnels
cleanup_tunnels() {
    echo -e "\nCleaning up SSH tunnels..."
    for pid in "${SSH_TUNNELS[@]}"; do
        kill "$pid" 2>/dev/null
    done
    exit 0
}

# Load configuration
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: Configuration file not found at $CONFIG_FILE"
        exit 1
    fi
    
    SERVERS=$(jq -r '.docker_servers | to_entries | map({
        name: .key,
        ip: .value.ip,
        user: .value.user,
        portainer_port: (.value.portainer.port // 9443),
        portainer_user: (.value.portainer.username // "admin"),
        https: (.value.portainer.https // true)
    })' "$CONFIG_FILE")
    
    echo "Debug: Loaded server configuration:"
    echo "$SERVERS" | jq '.'
    
    SSH_KEY=$(jq -r '.ssh_key' "$CONFIG_FILE")
    SSH_KEY="${SSH_KEY/#\~/$HOME}"
    
    if [ ! -f "$SSH_KEY" ]; then
        echo "Error: SSH key not found at $SSH_KEY"
        exit 1
    fi
}

# Get authentication token for a server
get_auth_token() {
    local server_ip=$1
    local portainer_user=$2
    local local_port=${LOCAL_PORTS[$server_ip]}
    
    read -s -p "Enter Portainer password for ${server_ip}: " PASSWORD
    echo
    
    local token
    echo "Debug: Attempting to connect to http://localhost:${local_port}/api/auth"
    token=$(curl -v -k -X POST \
        "https://localhost:${local_port}/api/auth" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"${portainer_user}\",\"password\":\"${PASSWORD}\"}" \
        2>&1 | tee /dev/stderr | jq -r .jwt)
    
    if [ -z "$token" ] || [ "$token" = "null" ]; then
        echo "Authentication failed for ${server_ip}. Please check your credentials."
        return 1
    fi
    
    echo "$token"
}

# Get endpoints information for a server
get_endpoints() {
    local server_ip=$1
    local token=$2
    local local_port=${LOCAL_PORTS[$server_ip]}
    
    curl -s -k -H "Authorization: Bearer $token" \
        "https://localhost:${local_port}/api/endpoints" \
        | jq -r '.[] | "ID: \(.Id) | Name: \(.Name) | Type: \(.Type) | URL: \(.URL)"'
}

# Get containers status
get_containers() {
    local server_ip=$1
    local token=$2
    local endpoint_id=$3
    local local_port=${LOCAL_PORTS[$server_ip]}
    
    curl -s -k -H "Authorization: Bearer $token" \
        "https://localhost:${local_port}/api/endpoints/${endpoint_id}/docker/containers/json?all=true" \
        | jq -r '.[] | "\(.Names[0])||\(.State)||\(.Status)"'
}

# Get system information
get_system_info() {
    local server_ip=$1
    local token=$2
    local endpoint_id=$3
    local local_port=${LOCAL_PORTS[$server_ip]}
    
    curl -s -k -H "Authorization: Bearer $token" \
        "https://localhost:${local_port}/api/endpoints/${endpoint_id}/docker/info" \
        | jq '.'
}

# Display header
print_header() {
    clear
    echo -e "${BLUE}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                  Portainer Terminal Dashboard                   ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Display container status with colors
display_container_status() {
    local container_info=$1
    local name=$(echo "$container_info" | cut -d'||' -f1)
    local state=$(echo "$container_info" | cut -d'||' -f2)
    local status=$(echo "$container_info" | cut -d'||' -f3)
    
    if [ "$state" = "running" ]; then
        echo -e "  └─ ${name:1} : ${GREEN}●${NC} $status"
    else
        echo -e "  └─ ${name:1} : ${RED}●${NC} $status"
    fi
}

# Process single server
process_server() {
    local server_name=$1
    local server_ip=$2
    local user=$3
    local portainer_user=$4
    local local_port="${LOCAL_PORTS[$server_ip]}"
    
    echo -e "\n${YELLOW}${BOLD}Server: ${server_name} (${server_ip})${NC}"
    echo "Debug: Local port for server is ${local_port}"
    
    if [ -z "$local_port" ]; then
        echo "Error: No local port found for server $server_ip"
        return 1
    fi
    
    local token
    token=$(get_auth_token "$server_ip" "$portainer_user")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    local endpoints
    endpoints=$(get_endpoints "$server_ip" "$token")
    echo "$endpoints" | while read -r endpoint; do
        echo -e "\n${BOLD}$endpoint${NC}"
        local endpoint_id
        endpoint_id=$(echo "$endpoint" | cut -d' ' -f2)
        
        echo -e "\n${BOLD}Containers:${NC}"
        local containers
        containers=$(get_containers "$server_ip" "$token" "$endpoint_id")
        echo "$containers" | while read -r container; do
            display_container_status "$container"
        done
        
        echo -e "\n${BOLD}System Information:${NC}"
        local system_info
        system_info=$(get_system_info "$server_ip" "$token" "$endpoint_id")
        echo -e "  └─ Containers: $(echo "$system_info" | jq -r '.Containers')"
        echo -e "  └─ Running: $(echo "$system_info" | jq -r '.ContainersRunning')"
        echo -e "  └─ Paused: $(echo "$system_info" | jq -r '.ContainersPaused')"
        echo -e "  └─ Stopped: $(echo "$system_info" | jq -r '.ContainersStopped')"
        echo -e "  └─ Images: $(echo "$system_info" | jq -r '.Images')"
    done
}

# Setup tunnels for all servers
setup_tunnels() {
    local names=()
    local ips=()
    local users=()
    local ports=()
    
    while IFS= read -r server; do
        names+=("$(echo "$server" | jq -r '.name')")
        ips+=("$(echo "$server" | jq -r '.ip')")
        users+=("$(echo "$server" | jq -r '.user')")
        ports+=("$(echo "$server" | jq -r '.portainer_port')")
    done < <(echo "$SERVERS" | jq -c '.[]')
    
    for i in "${!names[@]}"; do
        echo "Setting up SSH tunnel for ${names[$i]} (${ips[$i]})..."
        if ! setup_ssh_tunnel "${ips[$i]}" "${users[$i]}" "${ports[$i]}" "$SSH_KEY"; then
            echo "Failed to setup tunnel for ${names[$i]}"
            cleanup_tunnels
            exit 1
        fi
    done
    
    # Debug output of established tunnels
    echo "Debug: Established tunnels:"
    declare -p LOCAL_PORTS
    declare -p SSH_TUNNELS
}

# Main display loop
main_loop() {
    while true; do
        print_header
        echo "Debug: Current SSH tunnels:"
        for server in "${!SSH_TUNNELS[@]}"; do
            echo "Server $server -> PID ${SSH_TUNNELS[$server]} -> Port ${LOCAL_PORTS[$server]}"
        done
        
        # Read server data into arrays
        local names=()
        local ips=()
        local users=()
        local portainer_users=()
        
        while IFS= read -r server; do
            names+=("$(echo "$server" | jq -r '.name')")
            ips+=("$(echo "$server" | jq -r '.ip')")
            users+=("$(echo "$server" | jq -r '.user')")
            portainer_users+=("$(echo "$server" | jq -r '.portainer_user')")
        done < <(echo "$SERVERS" | jq -c '.[]')
        
        # Process each server
        for i in "${!names[@]}"; do
            process_server "${names[$i]}" "${ips[$i]}" "${users[$i]}" "${portainer_users[$i]}"
        done
        
        echo -e "\n${BLUE}Refreshing in 10 seconds... (Press Ctrl+C to exit)${NC}"
        sleep 10
    done
}

# Main execution
check_dependencies
load_config
setup_tunnels
trap cleanup_tunnels SIGINT SIGTERM
main_loop
