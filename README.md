# Installation

install this repo to `$XDG_CONFIG_HOME`

static link:
* `$XDG_CONFIG_HOME/profile` to `~/.profile`
* `$XDG_CONFIG_HOME/zprofile` to `~/.zprofile`
* `$XDG_CONFIG_HOME/bashrc` to `~/.bashrc`

change shell to zsh (after installing of course):
`chsh -s $(which zsh)`

## Groups
`tty docker video optical input wheel dialout`

## Requirements

### Arch-Based
```
# yay
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# dbus before anything else
yay -S dbus

yay -S grub-theme-minegrub-world-selection-git
# follow the setup steps after the install

# general apps
yay -S alacritty zathura firefox
yay -S spotify steam
yay -S ncspot

# plugins and thumbnailer for thunar
yay -S gvfs
yay -S tumbler thunar-volman ffmpegthumbnailer poppler-glib

# yazi and plugins
yay -S yazi ffmpeg 7zip jq poppler ripgrep fzf zoxide resvg imagemagick

# zsh
yay -S zsh zsh-syntax-highlighting

# X11, i3
yay -S xorg xorg-xinit xorg-xrandr xclip xdotool numlockx
yay -S i3 i3status-rust picom rofi rofi-themes-collection-git

# wayland, toolkits, hyprland, tools
yay -S wayland wlroots xorg-xwayland \
 qt5-wayland qt6-wayland gtk3 \
 hyprland waybar wofi \
 wl-clipboard cliphist hyprpaper mpvpaper

# session services/utils
yay -S dunst xdg-utils xdg-user-dirs
yay -S rofimoji redshift
yay -S noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra

# audio
yay -S pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber

# installing, moving, compressing
yay -S wget openssh uv rsync pigz zip unzip

yay -S man man-pages man-db glibc

# file editing and searching
yay -S neovim bat jq ripgrep fzf xxd obsidian
# lsps
yay -S pyright rust-analyzer lua-language-server clang marksman svlangserver

# hw interfacing
yay -S btop lshw blueman nmap speedtest-rs fastfetch

# media
yay -S ffmpeg mpv feh nsxiv flameshot
yay -S vlc vlc-plugins-all makemkv mkvtoolnix-cli
    sudo modprobe sg gpu-screen-recorder-ui

# social
yay -S discord slack signal-desktop session-desktop

# webcam
yay -S iriunwebcam-bin android-tools

# fonts (consider using this in future: ttf-firacode-nerd)
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraCode.zip
unzip FiraCode.zip
mv FiraCode/*.ttf ~/.local/share/fonts/
fc-cache -fv

# xwinwrap custom branch
git clone https://github.com/mmhobi7/xwinwrap.git
cd xwinwrap
make
sudo make install

# optional fun packages
yay -S ttyper openrgb-git glow cbonsai-git pipes.sh cava

# games
yay -S piu-piu-sh-git mcpelauncher

# dev tools
yay -S npm nodejs
# cpp
yay -S gcc valgrind pahole ninja cmake codelldb-bin stdman
yay -S docker docker-compose
# pip libs
pip install debugpy qt6-tools

# design software
yay -S blender bambustudio-bin fstl
# HIP backend for blender GPU compute on AMD devices:
yay -S rocm-hip-runtime rocm-opencl-runtime

# electronics software
yay -S ltspice kicad saleae-logic2

```

### Debian-Based
```
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

## configure i3/config
* configure displays
```
xrandr
```

* configure trackpad input device
```
xinput list
```

