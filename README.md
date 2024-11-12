# install alacritty
```
sudo snap install alacritty --classic
```

# install picom and i3 
```
sudo apt install i3 picom feh blueman
pip install i3ipc
```

# install bumblebee-status into ~/.local/bin/bumblebee-status
```
pip install --user bumblebee-status
mv ~/.local/bin/bumblebee-status ~/.config/i3/bumblebee-status
```

# append config notes to .config/i3/config modules: 
```
pip install pulsectl dbus-python speedtest-cli pygit2
sudo apt install -y dbus
sudo apt install xcwd playerctl pactl brightnessctl
```

# configure i3/config
* configure xrandr

* configure trackpad input device
```
xinput list
```

# nvim setup in the nvim directory repo


# setup bash settings
## first install fastfetch 
```
wget https://github.com/fastfetch-cli/fastfetch/releases/tag/2.27.1
```

## add these to ~/.bashrc
```
export EDITOR="nvim"
export VISUAL="nvim"

export PICO_SDK_PATH=~/repos/pico-sdk/

fastfetch

function cd() {
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
```
