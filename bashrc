# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

export VISUAL=nvim
export EDITOR="$VISUAL"

export PICO_SDK_PATH=~/repos/pico-sdk/

export PATH="$PATH:/$HOME/.config/config/tools"

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

shopt -s autocd  # allows auto cd by typing dir name

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u:\w\$ '
fi
unset color_prompt force_color_prompt

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

alias :q='exit'
alias logcat='cat "$(ls -t | head -n1)"'
alias cmake-dep='cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1 ..'
alias g='git'

# youtube audio downloader, -x is audio only
alias yta='yt-dlp --add-metadata -xic --audio-format mp3'

alias acm0='minicom -b 115200 -o -D /dev/ttyACM0'

set -o vi
bind -m vi-insert '"\C-v": "\e\ev"'  # open in vim buffer

# clear escape binding
bind -m vi-insert '"\e": nop'
bind -m vi-insert '"\e\e": vi-movement-mode'

bind 'set show-mode-in-prompt on'
bind 'set vi-ins-mode-string \1\e[2 q\2'   # Block
bind 'set vi-cmd-mode-string \1\e[1 q\2'   # Blink Block cursor in normal mode

bind '"\C-o":"cd -\n"'

logtail() {
    latest=$(ls -t | head -n 1)
    if [ -d "$latest" ]; then
        echo "$latest is a directory."
    else
        echo "tailing file: $latest"
        tail -f "$latest"
    fi
}

cd() {
  builtin cd "$@"

  if [[ -z "$VIRTUAL_ENV" ]] ; then
    ## If env folder is found then activate the vitualenv
      if [[ -d ./.venv ]] ; then
        source ./.venv/bin/activate
      fi
  else
    ## check the current folder belong to earlier VIRTUAL_ENV folder
    # if yes then do nothing
    # else deactivate
      parentdir="$(dirname "$VIRTUAL_ENV")"
      if [[ "$PWD"/ != "$parentdir"/* ]] ; then
        deactivate
      fi
  fi
}

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

if [ -f ~/.config/trident/trident.sh ]; then
    . ~/.config/trident/trident.sh
fi

. "$HOME/.cargo/env"

# ~/.bashrc
if [[ $- == *i* ]] && [ -t 1 ]; then
    sleep 0.01      # tiny delay to let terminal initialize
    fastfetch       # now Fastfetch reliably renders
fi
