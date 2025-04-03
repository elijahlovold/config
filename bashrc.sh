export VISUAL=nvim
export EDITOR="$VISUAL"

export PICO_SDK_PATH=~/repos/pico-sdk/

alias :q='exit'
alias logcat='cat "$(ls -t | head -n1)"'

bind '"\C-o":"cd -\n"'

# PS1='\[\e[1;32m\]\u:\[\e[1;34m\]\W\[\e[0m\]\$ '

set -o vi

bind -m vi-insert '"\C-v": "\e\ev"'  # open in vim buffer

# clear escape binding
bind -m vi-insert '"\e": nop'
bind -m vi-insert '"\e\e": vi-movement-mode'

bind 'set show-mode-in-prompt on'
bind 'set vi-ins-mode-string \1\e[2 q\2'   # Block
bind 'set vi-cmd-mode-string \1\e[1 q\2'   # Blink Block cursor in normal mode

function fastfetch() {
    command fastfetch --color Blue --logo-color-2 Blue --logo-color-1 White
}

fastfetch

clears() {
    clear
    fastfetch
}

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

acm0() {
    minicom -b 115200 -o -D /dev/ttyACM0
}

[ -f ~/.config/trident/trident.sh ] && source ~/.config/trident/trident.sh
