# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE= HISTFILESIZE= # infinite history

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# see the following for ANSI fmt:
#   https://en.wikipedia.org/wiki/ANSI_escape_code#:~:text=Select%20Graphic%20Rendition%20parameters
if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u:\w\$ '
fi
unset color_prompt force_color_prompt

set -o vi
bind -m vi-insert '"\C-v": "\e\ev"'  # open in vim buffer

# clear escape binding
bind -m vi-insert '"\e": nop'
bind -m vi-insert '"\e\e": vi-movement-mode'

bind 'set show-mode-in-prompt on'
bind 'set vi-ins-mode-string \1\e[2 q\2'   # Block
bind 'set vi-cmd-mode-string \1\e[1 q\2'   # Blink Block cursor in normal mode

bind '"\C-o":"\C-ucd -\n"'

# enable programmable completion features
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Source aliases if exists
[ -f "$XDG_CONFIG_HOME/aliases" ] && . "$XDG_CONFIG_HOME/aliases"

# Source custom trident script if it exists
[ -f "$XDG_CONFIG_HOME/trident/trident.sh" ] && . "$XDG_CONFIG_HOME/trident/trident.sh"

# ~/.bashrc
if [[ $- == *i* ]] && [ -t 1 ]; then
    sleep 0.01      # tiny delay to let terminal initialize
    fastfetch       # now Fastfetch reliably renders
fi
