#!/usr/bin/env bash

# Constants
DOTFILES="$HOME/dotfiles"
THEMES_DIR="$HOME/.theme/colors"
CONFIG_DIR="$HOME/.config"
FZF_CONFIG="$CONFIG_DIR/fish/config.fish"

# Check for fzf
command -v fzf >/dev/null 2>&1 || { echo "fzf is required but not installed. Aborting."; exit 1; }

# Select color scheme
color=$(find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort | fzf --prompt="Select a color scheme: " --height=40% --layout=reverse --border)

[[ -z "$color" ]] && { echo "No color scheme selected. Exiting."; exit 0; }
[[ ! -d "$THEMES_DIR/$color" ]] && { echo "Color scheme $color not found in $THEMES_DIR"; exit 1; }

# Source color scheme
source "$THEMES_DIR/$color/$color.sh"

# Update configs
update_config() {
    local app=$1 src=$2 dest=$3
    echo "Updating $app..."
    cp "$src" "$dest"
}

update_sed() {
    local file=$1 pattern=$2 replacement=$3
    sed -i "s|$pattern|$replacement|g" "$file"
}

# Update various configs
update_config "kitty" "$THEMES_DIR/kitty/$color.conf" "$CONFIG_DIR/kitty/theme.conf"
update_config "dunst" "$THEMES_DIR/dunst/$color.conf" "$CONFIG_DIR/dunst/theme.conf"
update_config "polybar" "$THEMES_DIR/polybar/$color.conf" "$CONFIG_DIR/polybar/theme.conf"
update_config "rofi" "$THEMES_DIR/rofi/$color.conf" "$CONFIG_DIR/rofi/theme.conf"
update_config "zathura" "$THEMES_DIR/zathura/$color" "$DOTFILES/zathura/zathurarc"

# Update fzf config
temp_file=$(mktemp)
{ head -n 6 "$FZF_CONFIG"; cat "$THEMES_DIR/fish/$color"; tail -n +12 "$FZF_CONFIG"; } > "$temp_file"
mv "$temp_file" "$FZF_CONFIG"

# Update wallpaper
echo "Updating background..."
cp "$THEMES_DIR/$color/wall" "$THEMES_DIR/theme"
feh --bg-fill "$THEMES_DIR/theme"

# Update bspwm colors
update_sed "$CONFIG_DIR/bspwm/config/decoration" "bspc config normal_border_color .*" "bspc config normal_border_color \"$br\""
update_sed "$CONFIG_DIR/bspwm/config/decoration" "bspc config focused_border_color .*" "bspc config focused_border_color \"$br2\""

# Update other UI elements
update_sed "$CONFIG_DIR/polybar/colors.ini" "background = .*" "background = $bg"
update_sed "$CONFIG_DIR/polybar/colors.ini" "foreground = .*" "foreground = $fg"
update_sed "$CONFIG_DIR/polybar/colors.ini" "accent = .*" "accent = $br2"
update_sed "$CONFIG_DIR/polybar/colors.ini" "alert = .*" "alert = $r"

update_sed "$CONFIG_DIR/rofi/colors.rasi" "background: .*;" "background: $bg;"
update_sed "$CONFIG_DIR/rofi/colors.rasi" "foreground: .*;" "foreground: $fg;"
update_sed "$CONFIG_DIR/rofi/colors.rasi" "foreground-alt: .*;" "foreground-alt: $br2;"

update_sed "$CONFIG_DIR/dunst/dunstrc" "background = .*" "background = \"$bg\""
update_sed "$CONFIG_DIR/dunst/dunstrc" "foreground = .*" "foreground = \"$fg\""

update_sed "$CONFIG_DIR/gtk-3.0/settings.ini" "gtk-theme-name=.*" "gtk-theme-name=$color"
update_sed "$HOME/.xsettingsd" "Net/ThemeName .*" "Net/ThemeName \"$color\""

# Update icon theme based on mode
icon_theme="Papirus-${mode^}"
update_sed "$CONFIG_DIR/gtk-3.0/settings.ini" "gtk-icon-theme-name=.*" "gtk-icon-theme-name=$icon_theme"
update_sed "$HOME/.xsettingsd" "Net/IconThemeName .*" "Net/IconThemeName \"$icon_theme\""

# Update BSPWM user options
update_sed "$CONFIG_DIR/bspwm/user/options" "bsp_color=.*" "bsp_color=$color"

# Restart services
xsettingsd &
bspc wm -r
pkill -USR1 -x sxhkd
killall -SIGUSR1 kitty
killall dunst && dunst &
polybar-msg cmd restart

sleep 1
notify-send "🎨 Applied colorscheme" "Color: $color"

echo "Theme updated successfully to $color!"
