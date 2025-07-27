# ~/.zshrc: executed by zsh for non-login shells.
# Customize it to fit your preferences

# Enable colors and change prompt:
autoload -U colors && colors
# Git branch function
parse_git_branch() {
    git branch 2> /dev/null | sed -n -e 's/^\* \(.*\)/[\1]/p'
}
# setopt prompt_subst
# PS1="%B${VIRTUAL_ENV:+($VIRTUAL_ENV:t)}$fg[green]%}%n%{$fg[white]%}:%{$fg[blue]%}%1~$reset_color"'$(parse_git_branch)$ '
PS1="%B%${VIRTUAL_ENV:+($VIRTUAL_ENV:t)}{$fg[green]%}%n%{$fg[white]%}:%{$fg[blue]%}%~%{$reset_color%}$%b "

# Basic auto/tab complete:
fpath=(/usr/share/zsh/vendor-completions $fpath)
autoload -U compinit
zstyle ':completion:*' menu no  # or: menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)		# Include hidden files.

# History settings
HISTSIZE=10000 # In-memory history size (for current session)
SAVEHIST=10000 # Max lines saved to $HISTFILE
setopt append_history inc_append_history  # append to history file
setopt hist_ignore_all_dups  # ignore duplicate commands
setopt hist_expire_dups_first  # remove older duplicates first

bindkey -s "^O" "^Ucd -\n"
bindkey "^A" beginning-of-line
bindkey "^K" kill-line
bindkey "^P" redisplay
bindkey "^R" history-incremental-search-backward
bindkey "^U" backward-kill-line
bindkey "^Y" yank
bindkey "^\b" backward-kill-word

# vi mode
bindkey -v
export KEYTIMEOUT=1

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char

# Change cursor shape for different vi modes.
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[5 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.

# Source aliases if exists
[ -f "$XDG_CONFIG_HOME/aliases" ] && . "$XDG_CONFIG_HOME/aliases"

# Source custom trident script if it exists
[ -f "$XDG_CONFIG_HOME/trident/trident.sh" ] && . "$XDG_CONFIG_HOME/trident/trident.sh"

# Load zsh-syntax-highlighting; should be last.
. /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

fastfetch
