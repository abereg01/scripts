#!/usr/bin/env bash

theme_name="$1"
theme_dir="$HOME/dotfiles/theme/colors/$theme_name"
conf_file="$theme_dir/$theme_name.conf"

if [[ ! -f "$conf_file" ]]; then
    echo "Theme configuration not found!"
    exit 1
fi

# Read colors from conf file
background=$(grep '^background\b' "$conf_file" | awk '{print $2}')
foreground=$(grep '^foreground\b' "$conf_file" | awk '{print $2}')
color0=$(grep '^color0\b' "$conf_file" | awk '{print $2}')
color1=$(grep '^color1\b' "$conf_file" | awk '{print $2}')
color2=$(grep '^color2\b' "$conf_file" | awk '{print $2}')
color3=$(grep '^color3\b' "$conf_file" | awk '{print $2}')
color4=$(grep '^color4\b' "$conf_file" | awk '{print $2}')
color5=$(grep '^color5\b' "$conf_file" | awk '{print $2}')
color6=$(grep '^color6\b' "$conf_file" | awk '{print $2}')
color7=$(grep '^color7\b' "$conf_file" | awk '{print $2}')

# Print color block function
print_color_block() {
    local color=$1
    printf "\033[48;2;%d;%d;%dm    \033[0m " \
        "0x${color:1:2}" "0x${color:3:2}" "0x${color:5:2}"
}

echo -e "\n  Theme: $theme_name\n"
echo -n "  "

# Print all color blocks in one row
for color in "$color0" "$color1" "$color2" "$color3" "$color4" "$color5" "$color6" "$color7"; do
    print_color_block "$color"
done

echo -e "\n"
