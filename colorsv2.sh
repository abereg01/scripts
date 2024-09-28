#!/usr/bin/env bash

# Load configuration
CONFIG_FILE="$HOME/.config/colorscript/config.ini"
source "$CONFIG_FILE"

# Constants
CACHE_FILE="/tmp/colorschemes_cache"
CACHE_TIMEOUT=3600  # Cache expires after 1 hour
LOG_FILE="$HOME/.colorscript.log"
LAST_SCHEME_FILE="$HOME/.last_colorscheme"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Error handling function
handle_error() {
    log "ERROR: $1"
    echo "Error: $1" >&2
    exit 1
}

# Function to list available color schemes with caching
list_colorschemes() {
    if [[ -f "$CACHE_FILE" ]] && [[ $(($(date +%s) - $(stat -c %Y "$CACHE_FILE"))) -lt $CACHE_TIMEOUT ]]; then
        cat "$CACHE_FILE"
    else
        find "$COLOR_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort | tee "$CACHE_FILE"
    fi
}

# Function to generate color preview
generate_preview() {
    local scheme="$1"
    local preview_file="$COLOR_DIR/$scheme/$scheme.preview"
    if [[ ! -f "$preview_file" ]]; then
        # Generate preview if it doesn't exist
        local conf_file="$COLOR_DIR/$scheme/$scheme.conf"
        awk '/^(background|foreground|color[0-7])/ {printf "\033[48;2;%d;%d;%dm  \033[0m", substr($2,2,2), substr($2,4,2), substr($2,6,2)}' "$conf_file" > "$preview_file"
    fi
    cat "$preview_file"
}

# Function to select color scheme using fzf with preview
select_color() {
    list_colorschemes | fzf --prompt="Select color scheme: " --preview="$0 --preview {}" \
                            --preview-window=right:20%:wrap \
                            --height=100% --layout=reverse --border
}

# Function to read color values from .conf file using ripgrep
read_color_values() {
    local conf_file="$COLOR_DIR/$color/$color.conf"
    [[ ! -f "$conf_file" ]] && handle_error "Color configuration file not found: $conf_file"

    # Read all color values using ripgrep
    eval $(rg -N '^(background|foreground|color[0-7])\b' "$conf_file" | awk '{printf "%s=%s\n", $1, $2}')
}

# Function to update all configuration files
update_configs() {
    local template_dir="$CONFIG_DIR/colorscript/templates"
    local temp_dir=$(mktemp -d)

    # Process each template file
    for template in "$template_dir"/*; do
        local filename=$(basename "$template")
        local output_file="$temp_dir/$filename"
        
        envsubst < "$template" > "$output_file"
        
        # Move the processed file to its final destination
        case "$filename" in
            bspwm_decoration) mv "$output_file" "$CONFIG_DIR/bspwm/config/decoration" ;;
            rofi_colors.rasi) mv "$output_file" "$CONFIG_DIR/rofi/colors.rasi" ;;
            polybar_colors.ini) mv "$output_file" "$HOME/.config/polybar/colors.ini" ;;
            dunstrc) mv "$output_file" "$CONFIG_DIR/dunst/dunstrc" ;;
            bspwm_options) mv "$output_file" "$CONFIG_DIR/bspwm/user/options" ;;
            bat.conf) mv "$output_file" "$CONFIG_DIR/bat/bat.conf" ;;
        esac
    done

    rm -rf "$temp_dir"
}

# Function to generate feh background configuration
generate_fehbg() {
    echo "feh --no-fehbg --bg-fill $COLOR_DIR/$color/wall/" > "$HOME/.fehbg"
    chmod 755 "$HOME/.fehbg"
}

# Function to update terminal colors
update_terminal_colors() {
    cp "$COLOR_DIR/$color/$color.conf" "$CONFIG_DIR/kitty/theme.conf"
    killall -SIGUSR1 kitty
}

generate_colors_fzf() {
    local fish_colors_file="$HOME/.config/fish/fzfcolors.fish"
    cat > "$fish_colors_file" << EOL
# Color configuration
set -g color_background $background
set -g color_foreground $foreground
set -g color_black $color0
set -g color_red $color1
set -g color_green $color2
set -g color_yellow $color3
set -g color_blue $color4
set -g color_magenta $color5
set -g color_cyan $color6
set -g color_white $color7

# Additional color mappings for fzf
set -g color_fg \$color_foreground
set -g color_bg \$color_background
set -g color_hl \$color_yellow
set -g color_fg_plus \$color_white
set -g color_bg_plus \$color_black
set -g color_hl_plus \$color_yellow
set -g color_border \$color_black
set -g color_header \$color_blue
set -g color_gutter \$color_background
set -g color_spinner \$color_yellow
set -g color_info \$color_cyan
set -g color_pointer \$color_magenta
set -g color_marker \$color_red
set -g color_prompt \$color_foreground
EOL
}

# Function to restart necessary services
restart_services() {
    bspc wm -r
    pkill -USR1 -x sxhkd
    sleep 1
}

# Main function
main() {
    # Save current scheme for potential revert
    echo "$color" > "$LAST_SCHEME_FILE"

    if [[ "$1" == "--preview" ]]; then
        generate_preview "$2"
        exit 0
    else
        color=$(select_color)
    fi

    [[ -z "$color" ]] && exit 0
    [[ -d "$COLOR_DIR/$color" ]] || handle_error "Invalid color scheme: $color"

    read_color_values

    # Run independent operations in parallel
    generate_fehbg &
    update_terminal_colors &
    generate_colors_fzf &

    # Update all configurations
    update_configs

    # Wait for background processes to finish
    wait

    # Restart services
    restart_services

    log "Color scheme changed to $color"
    echo "Color scheme changed to $color. Press 'r' to revert, any other key to exit."
    read -n 1 -s key
    if [[ "$key" == "r" ]]; then
        color=$(cat "$LAST_SCHEME_FILE")
        main
    fi
}

# Run the main function
main "$@"
exit 0
