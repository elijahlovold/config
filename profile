# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# load up default colors
[ "$(tty)" = "/dev/tty1" ] && openrgb -p default.orp --noautoconnect &

# source env vars
[ -f "$HOME/.config/env" ] && . "$HOME/.config/env"

# if running bash and .bashrc if it exists
[ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"

# update PATH if possible
[ -d "$HOME/bin" ] && PATH="$HOME/bin:$PATH"
[ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"
[ -d "$HOME/.config/scripts" ] && PATH="$HOME/.config/scripts:$PATH"

# source cargo env
# . "/home/elijah/.cache/cargo/env"
