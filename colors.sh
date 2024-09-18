#!/bin/bash

# Rofi Based Ricing script for i3 Window Manager
# Developed by Matthew Weber AKA The Linux Cast
# Version 0.3
# Last Updated 07 Aug 2022

#Variables & Paths
#IMPORTANT! Change these paths to the appropriate paths on your system. They won't be the same as mine. !IMPORTANT
i3p="$HOME/myrepo/i3/themes"
i3t="$HOME/myrepo/i3/theme.conf"
ptconf="$HOME/myrepo/polybar/themes/configs"
pconf="$HOME/myrepo/polybar/config.ini"
ptcolor="$HOME/myrepo/polybar/themes/colors"
pcolor="$HOME/myrepo/polybar/themes/theme.ini"
mods="$HOME/myrepo/polybar/themes/modules"
pmods="$HOME/myrepo/polybar/themes/modules/modules.ini"
alconf="$HOME/myrepo/alacritty/"
rofi="$HOME/myrepo/rofi/"
walls="$HOME/Pictures/walls/otherwalls/ricewalls"
piconf="$HOME/myrepo/picom/picom.conf"
dunst="$HOME/myrepo/dunst/dunstrc.d/"

declare -a options=(
"polyriver"
"kanagawa"
"cyberpunk"
"dracula"
"catppuccin"
"snowfall"
"everforest"
"pink"
"gruvbox"
"xfce_gruv"
"gruvbox_powerline"
"nord"
"ocean"
"onedark"
#"papercolor" WIP
#"papercolordark" WIP
"tokyonight"
"moonfly"
"sonokai"
"tomorrow-night"
"map"
"adaptive"
"dwm"
"dwm_gruvbox"
"bouquet"
"beach"
"keyboards"
"kiss"
"landscape"
"slime"
"manhattan"
"arrows"
"nxc"
"solarized"
"quit"
)

choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -i -l 20 -p 'Themes')

if [ $choice = 'quit' ]; then
    echo "No theme selected"
    exit
fi

#Copy Config Files to the Appropriate Places. Placeholder files must exist.
cp $i3p/$choice.conf $i3t 
cp $ptconf/$choice $pconf 
cp $mods/$choice.ini $pmods 
cp $ptcolor/$choice.ini $pcolor 
cp $rofi/$choice.rasi $rofi/theme.rasi
cp $dunst/01-$choice.conf $dunst/99-theme.conf
cp $alconf/colorschemes/$choice.yml $alconf/colors.yml

i3-msg restart

# Toggles Gaps off for gruvbox powerline & gruvbox & Nord
if [ $choice = 'gruvbox_powerline' ] || [ $choice = 'dwm_gruvbox' ] || [ $choice = 'gruvbox' ] || [ $choice = 'nord' ] || [ $choice = 'tomorrow-night' ]; then
    i3-msg gaps inner all set 1, gaps outer all set 1
elif [ $choice = 'adaptive' ]; then
    i3-msg gaps inner all set 5, gaps outer all set 5
fi

if [ $choice = 'xfce_gruv' ]; then
    polybar-msg cmd quit
    exec xfce4-panel --disable-wm-check &
else
    killall xfce4-panel
fi

# Toggles Rounded Borders for Catppuccin (coming soon)
#if [ $choice = 'catppuccin' ] || [ $choice = 'onedark' ]
#then
#    sed -i "/corner-radius/c\corner-radius = 15;" $piconf
#elif 
#    sed -i "/corner-radius/c\corner-radius = 0;" $piconf
#fi


# Set Wallpapers
feh --bg-fil $walls/$choice.jpg

# Change vim color scheme (coming soon)

#Dunst (Disable if you do not use dunst)
killall dunst
while pgrep -u $UID -x dunst >/dev/null; do sleep 1; done
