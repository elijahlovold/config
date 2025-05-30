if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval $(dbus-launch --sh-syntax)
fi

setxkbmap -option caps:swapescape

# picom --config "$XDG_CONFIG_HOME/picom/picom.conf" &

# set background
feh --bg-scale "$XDG_CONFIG_HOME/i3/background.png"

exec i3
