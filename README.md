## Installation 

install requirements: 
`./setup/install_reqs.sh`

setup with:  
`./setup/setup.sh`

source the local `bashrc.sh` in your actual `.bashrc` by adding this line: 
`source /home/elijah/.config/config/bashrc.sh`

## configure i3/config
* configure displays
```
xrandr
```

* configure trackpad input device
```
xinput list
```

## Requirements

### Ubuntu
```
# fix this to build from source instead
snap install alacritty --classic

# install i3
apt install i3 picom brightnessctl
pip install i3ipc

# install bumblebee-status and utils
pip install --user bumblebee-status
pip install pulsectl dbus-python speedtest-cli pygit2
apt install -y dbus
apt install xcwd playerctl pactl

# general utils
apt install git sxiv htop feh blueman

# zsh
apt install zsh zsh-syntax-highlighting

## figure out how I installed fastfetch
# wget https://github.com/fastfetch-cli/fastfetch/releases/tag/2.27.1
```

### Arch
