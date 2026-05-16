.dotfiles for arch-based installation

Init and update submodules:
```sh
git submodule init
git submodule update
```

Install yay and packages:
```sh
./install/install-yay.sh
./install/install-packages.sh
./install/build-xwinwrap.sh
```

## Shell Links

### zsh

```sh
ln -s $XDG_CONFIG_HOME/zsh/.zshenv ~/
```

### bash

```sh
ln -s $XDG_CONFIG_HOME/profile ~/.profile
ln -s $XDG_CONFIG_HOME/bashrc ~/.bashrc
```

## Groups

```sh
usermod -aG tty,docker,video,optical,input,wheel,dialout $USER
```

## Per-Machine i3 Configuration
* configure displays and status bars
```
xrandr
```

* configure trackpad input device
```
xinput list
```

## Grub

```sh
yay -S grub-theme-minegrub-world-selection-git
# or
yay -S grub-theme-hollow-knight
```
Follow steps after to set the theme, then rebuild grub
