pragma Singleton
import QtQuick
import Quickshell

// QML port of ~/.config/keytree/config.toml's [commands]/[layout]/[keys.*].
// Colors live in qs.modules.theme's Theme singleton instead (wallust-
// overridable, see modules/theme/Theme.qml). Editing the tree/layout here
// is the equivalent of editing the TOML.
Singleton {
    id: root

    readonly property var keybindings: ({
        back: "Escape",
        quit: "q",
        search: "/"
    })

    readonly property var layout: ({
        type: "ring",              // "ring" or "spiral"
        shape: "circle",           // "rect" or "circle"
        ringThreshold: 12,
        spiralThreshold: 12,
        gapPixels: 20,
        // Single knobs instead of hand-tuning many pixel constants:
        // ringScale multiplies the popup's overall window/ring-radius size;
        // nodeScale multiplies the card (circle/rect) size independently of
        // ring spacing; fontScale multiplies every text size in both the
        // radial and search views. 1.0 = the original tuned-by-hand look
        // for each. If nodeScale grows much past ringScale, cards will
        // start crowding the outer ring - bump ringScale too if so.
        ringScale: 1.2,
        nodeScale: 1.6,
        fontScale: 1.2
    })

    readonly property var trees: ({
      "default": {
        "b": {
          label: "Bookmarks/",
          icon: "  ",
          children: {
            "c": { icon: "  ", label: "Calendar",   cmd: "firefox --new-window https://calendar.google.com/calendar/u/0/r" },
            "d": { icon: "󰺄  ", label: "Dictionary", cmd: "firefox --new-window https://www.dictionary.com/" },
            "g": { icon: "󰊤  ", label: "Github",     cmd: "firefox --new-window https://github.com/elijahlovold?tab=repositories" },
            "l": { icon: "󰌻  ", label: "Linkedin",   cmd: "firefox --new-window https://www.linkedin.com/feed/" },
            "m": { icon: "󰇮  ", label: "Mail",       cmd: "firefox --new-window https://mail.google.com/mail/u/0/#inbox" },
            "n": { icon: "󰼭  ", label: "Monkeytype", cmd: "firefox --new-window https://monkeytype.com/" },
            "t": { icon: "󰧑  ", label: "ChatGPT",    cmd: "firefox --new-window https://chatgpt.com/" },
            "w": { icon: "󰖬  ", label: "Wikipedia",  cmd: "firefox --new-window https://www.wikipedia.org/" },
            "y": { icon: "󰗃  ", label: "Youtube",    cmd: "firefox --new-window https://youtube.com/" },
          }
        },
        "c": { icon: "  ", label: "Chrome", cmd: "google-chrome" },
        "d": {
          label: "Design/",
          icon: "   ",
          children: {
            "b": { icon: "  ", label: "Blender", cmd: "blender" },
            "g": { icon: "  ", label: "Godot",   cmd: "godot" },
            "i": { icon: "  ", label: "Gimp",    cmd: "gimp" },
            "l": { icon: "󰐋  ", label: "LTSpice", cmd: "ltspice" },
            "u": { icon: "󰹛  ", label: "Bambu",   cmd: "bambu-studio" },
          }
        },
        "e": {
          label: "EE/",
          icon: "  ",
          children: {
            "d": { icon: "󰬋  ", label: "Digikey",  cmd: "firefox --new-window https://www.digikey.com/" },
            "e": { icon: "󰬰  ", label: "EDN",      cmd: "firefox --new-window https://www.edn.com/" },
            "n": { icon: "󰎖  ", label: "Nordic",   cmd: "firefox --new-window https://devzone.nordicsemi.com/" },
            "o": { icon: "  ", label: "Octopart", cmd: "firefox --new-window https://octopart.com/" },
          }
        },
        "f": {
          label: "Config",
          icon: "  ",
          children: {
            "a": { icon: "󱍵  ", label: "Aliases",   cmd: "alacritty -e nvim +'cd ~/.config/' ~/.config/aliases" },
            "b": { icon: "  ", label: "Btop",      cmd: "alacritty -e nvim +'cd ~/.config/btop/' ~/.config/btop/btop.conf" },
            "c": { icon: "󰧑  ", label: "cl-wrap",   cmd: "alacritty -e nvim +'cd ~/.config/scripts/' ~/.config/scripts/cl-wrap.sh" },
            "e": { icon: "󰇧  ", label: "Env",       cmd: "alacritty -e nvim +'cd ~/.config/' ~/.config/env" },
            "h": { icon: "󱇙  ", label: "Hypr",      cmd: "alacritty -e nvim +'cd ~/.config/hypr/' ~/.config/hypr/" },
            "i": { icon: "󱇙  ", label: "i3wm",      cmd: "alacritty -e nvim +'cd ~/.config/i3/' ~/.config/i3/config" },
            "j": { icon: "  ", label: "QKeytree",  cmd: "alacritty -e nvim +'cd ~/.config/quickshell/modules/keytree/' ~/.config/quickshell/modules/keytree/KeytreeConfig.qml" },
            "k": { icon: "  ", label: "Keytree",   cmd: "alacritty -e nvim +'cd ~/.config/keytree/' ~/.config/keytree/config.toml" },
            "l": { icon: "🅰  ", label: "Alacritty", cmd: "alacritty -e nvim +'cd ~/.config/alacritty/' ~/.config/alacritty/alacritty.toml" },
            "m": { icon: "󰣆  ", label: "Mimes",     cmd: "alacritty -e nvim +'cd ~/.config/' ~/.config/mimeapps.list" },
            "n": { icon: "  ", label: "Nvim",      cmd: "alacritty -e nvim +'cd ~/.config/nvim/lua/' ~/.config/nvim/lua/" },
            "p": { icon: "  ", label: "Picom",     cmd: "alacritty -e nvim +'cd ~/.config/picom/' ~/.config/picom/picom.conf" },
            "s": { icon: "  ", label: "i3 Status", cmd: "alacritty -e nvim +'cd ~/.config/i3status-rust/' ~/.config/i3status-rust/config.toml" },
            "u": { icon: "  ", label: "Qksh",      cmd: "alacritty -e nvim +'cd ~/.config/quickshell/' ~/.config/quickshell/" },
            "w": { icon: "󰏘  ", label: "Wallust",   cmd: "alacritty -e nvim +'cd ~/.config/wallust/' ~/.config/wallust/wallust.toml" },
            "z": { icon: "󰏘  ", label: "zsh",       cmd: "alacritty -e nvim +'cd ~/.config/zsh/' ~/.config/zsh/.zshrc" },
          }
        },
        "g": {
          label: "Games/",
          icon: "  ",
          children: {
            "a": { icon: "󰓥  ", label: "AoE2",          cmd: "steam -applaunch 813780" },
            "f": { icon: "  ", label: "Factorio",      cmd: "steam -applaunch 427520" },
            "h": { icon: "󰷟  ", label: "Hollow Knight", cmd: "steam -applaunch 4183110" },
            "j": { icon: "󰓎  ", label: "Just Cause 2",  cmd: "steam -applaunch 8190" },
            "k": { icon: "󱇫  ", label: "Silksong",      cmd: "steam -applaunch 1030300" },
            "m": { icon: "󰍳  ", label: "Minecraft",     cmd: "mcpelauncher-ui-qt" },
            "r": { icon: "󰰞  ", label: "R2ModMan",      cmd: "r2modman" },
            "s": { icon: "  ", label: "Steam",         cmd: "steam" },
            "t": { icon: "󰔱  ", label: "Terraria",      cmd: "steam -applaunch 105600" },
            "v": { icon: "󰷚  ", label: "Vim-Sweeper",   cmd: "alacritty -e vim-sweeper" },
          }
        },
        "h": {
          label: "Work/",
          icon: "󰸖  ",
          children: {
            "b": { icon: "  ", label: "Bitbucket", cmd: "google-chrome https://bitbucket.org/cadenceneuro/workspace/overview/" },
            "c": { icon: "  ", label: "Calendar",  cmd: "google-chrome https://calendar.google.com/calendar/u/0/r" },
            "d": { icon: "  ", label: "Drive",     cmd: "google-chrome https://drive.google.com/drive/home" },
            "i": { icon: "  ", label: "Iriun",     cmd: "iriunwebcam" },
            "j": { icon: "  ", label: "Jira",      cmd: "google-chrome https://cadenceneuro.atlassian.net/jira/software/c/projects/SWS/boards/129/backlog" },
            "m": { icon: "󰇮  ", label: "Mail",      cmd: "google-chrome https://mail.google.com/mail/u/0/#inbox" },
            "o": { icon: "  ", label: "Obsidian",  cmd: "obsidian \"obsidian://open?vault=Shared-Vault\"" },
            "w": { icon: "󰧑  ", label: "Wiki",      cmd: "google-chrome https://sites.google.com/cadenceneuro.com/team/home?pli=1" },
          }
        },
        "k": { icon: "  ", label: "Bible",    cmd: "alacritty -e nvim ~/dox/bible_kjv.txt" },
        "l": { icon: "  ", label: "Download", cmd: "xdg-open \"$HOME/dl/$(ls -t $HOME/dl | head -n 1)\"" },
        "m": { icon: "󰄛  ", label: "CaH",      cmd: "mupdf -r 180 ~/dox/books/The\\ Complete\\ Calvin\\ \\&\\ Hobbes.pdf $((1 + RANDOM % 1350))" },
        "o": { icon: "  ", label: "Obsidian", cmd: "obsidian \"obsidian://open?vault=vault\"" },
        "p": { icon: "  ", label: "Python",   cmd: "alacritty -e python3.14" },
        "s": {
          label: "Social/",
          icon: "  ",
          children: {
            "d": { icon: "  ", label: "Discord", cmd: "discord" },
            "g": { icon: "󰘊  ", label: "Signal",  cmd: "signal-desktop" },
            "n": { icon: "󰿌  ", label: "Session", cmd: "session-desktop" },
            "p": { icon: "  ", label: "Phone",   cmd: "firefox --new-window https://messages.google.com/web/conversations" },
            "s": { icon: "󰒱  ", label: "Slack",   cmd: "slack" },
          }
        },
        "v": {
          label: "Services/",
          icon: "  ",
          children: {
            "i": { label: "Immich",    cmd: "firefox http://edel:2283/",            icon: "  " },
            "j": { label: "Jellyfin",  cmd: "firefox http://edel:8096/",            icon: "󰿎  " },
            "p": { label: "Portainer", cmd: "firefox https://edel:9443/",           icon: "󰡨  " },
            "s": { label: "Stirling",  cmd: "firefox http://edel:8080/",            icon: "  " },
            "t": { label: "TailScale", cmd: "firefox https://login.tailscale.com/", icon: "󰖂  " },
          }
        },
        "w": { icon: "󰸉  ", label: "Wallpaper", cmd: "qs ipc call imagepicker toggle" },
        "y": { icon: "󱇯  ", label: "Stator",    cmd: "qs ipc call keytree toggle stator" },
      },

      "stator": {
        "b": { icon: "󱎫  ", label: "Break",      cmd: "stator-rs --set-state break" },
        "c": { icon: "  ", label: "Chillin",    cmd: "stator-rs --set-state chill" },
        "d": { icon: "  ", label: "Dist",       cmd: "alacritty -e zsh -c 'stator-rs --dist; exec sh'" },
        "i": { icon: "󰦖  ", label: "Idle",       cmd: "stator-rs --set-state idle" },
        "l": { icon: "  ", label: "Logs",       cmd: "alacritty -e zsh -c 'stator-rs --log; exec sh'" },
        "p": { icon: "  ", label: "Projects",   cmd: "stator-rs --set-state proj" },
        "r": { icon: "  ", label: "Read/Write", cmd: "stator-rs --set-state rw" },
        "w": { icon: "󰦑  ", label: "Work",       cmd: "stator-rs --set-state work" },
      }
    })
}
