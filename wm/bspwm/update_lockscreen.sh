sp_color=$(grep '^bsp_color=' "$HOME/.config/bspwm/config" | cut -d'=' -f2)
betterlockscreen -u "$HOME/dotfiles/theme/colors/$bsp_color/wall" --fx blur
