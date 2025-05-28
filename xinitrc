if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval $(dbus-launch --sh-syntax)
fi

# setxkbmap -option caps:swapescape

picom --config /home/elijah/.config/picom/picom.conf &

toggle-monitors --reset
wallpaper-picker

exec i3
