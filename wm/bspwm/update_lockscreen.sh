#!/bin/bash

# Get current theme from bspwm config
bsp_color=$(grep '^bsp_color=' "$HOME/.config/bspwm/config" | cut -d'=' -f2 | tr -d '"')

# Check if we got a valid theme name
if [ -z "$bsp_color" ]; then
    echo "Error: Could not determine current theme"
    exit 1
fi

# Check if the theme directory exists
if [ ! -d "$HOME/dotfiles/theme/colors/$bsp_color" ]; then
    echo "Error: Theme directory not found: $HOME/dotfiles/theme/colors/$bsp_color"
    exit 1
fi

# Update lockscreen
echo "Updating lockscreen for theme: $bsp_color"
betterlockscreen -u "$HOME/dotfiles/theme/colors/$bsp_color/wall" --fx blur
