# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# # load up default colors
# [ "$(tty)" = "/dev/tty1" ] && openrgb -p default.orp --noautoconnect &

# source env vars
[ -f "$HOME/.config/env" ] && . "$HOME/.config/env"
[ -f "$HOME/.config/.env" ] && . "$HOME/.config/.env"
[ -f "$HOME/.config/aliases" ] && . "$HOME/.config/aliases"

if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
    exec dbus-run-session start-hyprland
fi
