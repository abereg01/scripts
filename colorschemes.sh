#!/bin/bash

set -euo pipefail

# Configuration file paths
ST_CONFIG_FILE="$HOME/.dotfiles/.config/st/colors.c"
EWW_CONFIG_FILE="$HOME/.dotfiles/.config/eww/eww.scss"

# Color schemes
declare -A SCHEMES=(
    ["catppuccin"]="Catppuccin"
    ["dracula"]="Dracula"
    ["nord"]="Nord"
    ["tokyonight"]="Tokyo Night"
    ["onedark"]="One Dark"
)

# Function to display the menu and get user choice
show_menu() {
    echo "Select a color scheme:"
    local i=1
    for scheme in "${!SCHEMES[@]}"; do
        echo "$i) ${SCHEMES[$scheme]}"
        ((i++))
    done
    echo "$i) Quit"
    
    read -p "Enter your choice (1-$i): " choice
    echo
    
    if [[ "$choice" -eq "$i" ]]; then
        echo "quit"
    elif [[ "$choice" -ge 1 && "$choice" -lt "$i" ]]; then
        echo "${!SCHEMES[@]:$((choice-1)):1}"
    else
        echo "invalid"
    fi
}

# Function to update the St configuration file
update_st_config() {
    local new_scheme=$1
    sed -i "s/#include \"colorschemes\/.*\.c\"/#include \"colorschemes\/$new_scheme.c\"/" "$ST_CONFIG_FILE"
    echo "St color scheme updated to $new_scheme"
}

# Function to update the Eww configuration file
update_eww_config() {
    local new_scheme=$1
    sed -i "s/@import \"scss\/themes\/.*\.scss\";/@import \"scss\/themes\/$new_scheme.scss\";/" "$EWW_CONFIG_FILE"
    echo "Eww color scheme updated to $new_scheme"
}

# Function to check if a file exists
check_file() {
    if [ ! -f "$1" ]; then
        echo "Error: Configuration file not found at $1" >&2
        exit 1
    fi
}

# Main script
main() {
    check_file "$ST_CONFIG_FILE"
    check_file "$EWW_CONFIG_FILE"

    while true; do
        choice=$(show_menu)
        
        case $choice in
            quit) 
                echo "Exiting without changes."
                exit 0
                ;;
            invalid) 
                echo "Invalid choice. Please try again."
                ;;
            *)
                update_st_config "$choice"
                update_eww_config "$choice"
                exit 0
                ;;
        esac
    done
}

main
