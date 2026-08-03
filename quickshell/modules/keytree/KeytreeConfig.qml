pragma Singleton
import QtQuick
import Quickshell

// QML port of ~/.config/keytree/config.toml's [commands]/[layout]/[keys.*].
// Colors live in qs.modules.common's Theme singleton instead (wallust-
// overridable, see modules/common/Theme.qml). Editing the tree/layout here
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
                icon: "  ",
                children: {
                    "g": { label: "Github", cmd: "firefox --new-window https://github.com/elijahlovold?tab=repositories", icon: "  " },
                    "y": { label: "Youtube", cmd: "firefox --new-window https://youtube.com/", icon: "  " },
                    "t": { label: "ChatGPT", cmd: "firefox --new-window https://chatgpt.com/", icon: "󰧑  " },
                    "w": { label: "Wikipedia", cmd: "firefox --new-window https://www.wikipedia.org/", icon: "󰖬  " },
                    "d": { label: "Dictionary", cmd: "firefox --new-window https://www.dictionary.com/", icon: "  " },
                    "l": { label: "Linkedin", cmd: "firefox --new-window https://www.linkedin.com/feed/", icon: "  " },
                    "m": { label: "Mail", cmd: "firefox --new-window https://mail.google.com/mail/u/0/#inbox", icon: "󰇮  " },
                    "c": { label: "Calendar", cmd: "firefox --new-window https://calendar.google.com/calendar/u/0/r", icon: "  " },
                    "n": { label: "Monkeytype", cmd: "firefox --new-window https://monkeytype.com/", icon: "󰼭  " }
                }
            },
            "c": { label: "Chrome", cmd: "google-chrome", icon: "  " },
            "d": {
                label: "Design/",
                icon: "   ",
                children: {
                    "b": { label: "Blender", cmd: "blender", icon: "  " },
                    "g": { label: "Godot", cmd: "godot", icon: "  " },
                    "l": { label: "LTSpice", cmd: "ltspice", icon: "󰐋  " },
                    "u": { label: "Bambu", cmd: "bambu-studio", icon: "󰹛  " },
                    "i": { label: "Gimp", cmd: "gimp", icon: "  " }
                }
            },
            "e": {
                label: "EE/",
                icon: "  ",
                children: {
                    "d": { label: "Digikey", cmd: "firefox --new-window https://www.digikey.com/", icon: "󰬋  " },
                    "o": { label: "Octopart", cmd: "firefox --new-window https://octopart.com/ ", icon: "  " },
                    "n": { label: "Nordic", cmd: "firefox --new-window https://devzone.nordicsemi.com/ ", icon: "󰎖  " },
                    "e": { label: "EDN", cmd: "firefox --new-window https://www.edn.com/ ", icon: "󰬰  " }
                }
            },
            "f": {
                label: "Config",
                icon: "  ",
                children: {
                    "a": { label: "Aliases", cmd: "alacritty -e nvim ~/.config/aliases", icon: "󱍵  " },
                    "b": { label: "Btop", cmd: "alacritty -e nvim ~/.config/btop/btop.conf", icon: "  " },
                    "c": { label: "cl-wrap", cmd: "alacritty -e nvim ~/.config/scripts/cl-wrap.sh", icon: "󰧑  " },
                    "e": { label: "Env", cmd: "alacritty -e nvim ~/.config/env", icon: "󰇧  " },
                    "h": { label: "Hypr", cmd: "alacritty -e nvim ~/.config/hypr", icon: "󱇙  " },
                    "i": { label: "i3wm", cmd: "alacritty -e nvim ~/.config/i3/config", icon: "󱇙  " },
                    "j": { label: "QKeytree", cmd: "alacritty -e nvim ~/.config/quickshell/modules/keytree/KeytreeConfig.qml", icon: "  " },
                    "k": { label: "Keytree", cmd: "alacritty -e nvim ~/.config/keytree/config.toml", icon: "  " },
                    "l": { label: "Alacritty", cmd: "alacritty -e nvim ~/.config/alacritty/alacritty.toml", icon: "🅰  " },
                    "m": { label: "Mimes", cmd: "alacritty -e nvim ~/.config/mimeapps.list", icon: "󰣆  " },
                    "p": { label: "Picom", cmd: "alacritty -e nvim ~/.config/picom/picom.conf", icon: "  " },
                    "s": { label: "i3 Status", cmd: "alacritty -e nvim ~/.config/i3status-rust/config.toml", icon: "  " },
                    "u": { label: "Qksh", cmd: "alacritty -e nvim ~/.config/quickshell", icon: "  " },
                    "w": { label: "Wallust", cmd: "alacritty -e nvim ~/.config/wallust/wallust.toml", icon: "󰏘  " },
                    "z": { label: "zsh", cmd: "alacritty -e nvim ~/.config/zsh/.zshrc", icon: "󰏘  " }
                }
            },
            "g": {
                label: "Games/",
                icon: "  ",
                children: {
                    "r": { label: "R2ModMan", cmd: "r2modman", icon: "󰰞  " },
                    "v": { label: "Vim-Sweeper", cmd: "alacritty -e vim-sweeper", icon: "󰷚  " },
                    "s": { label: "Steam", cmd: "steam", icon: "  " },
                    "f": { label: "Factorio", cmd: "steam -applaunch 427520", icon: "  " },
                    "m": { label: "Minecraft", cmd: "mcpelauncher-ui-qt", icon: "󰍳  " },
                    "t": { label: "Terraria", cmd: "steam -applaunch 105600", icon: "󰔱  " },
                    "h": { label: "Hollow Knight", cmd: "steam -applaunch 4183110", icon: "󰷟  " },
                    "k": { label: "Silksong", cmd: "steam -applaunch 1030300", icon: "󱇫  " },
                    "a": { label: "AoE2", cmd: "steam -applaunch 813780", icon: "󰓥  " },
                    "j": { label: "Just Cause 2", cmd: "steam -applaunch 8190", icon: "󰓎  " }
                }
            },
            "h": {
                label: "Work/",
                icon: "󰸖  ",
                children: {
                    "o": { label: "Obsidian", cmd: "obsidian \"obsidian://open?vault=Shared-Vault\"", icon: "  " },
                    "i": { label: "Iriun", cmd: "iriunwebcam", icon: "  " },
                    "w": { label: "Wiki", cmd: "google-chrome https://sites.google.com/cadenceneuro.com/team/home?pli=1", icon: "󰧑  " },
                    "b": { label: "Bitbucket", cmd: "google-chrome https://bitbucket.org/cadenceneuro/workspace/overview/", icon: "  " },
                    "j": { label: "Jira", cmd: "google-chrome https://cadenceneuro.atlassian.net/jira/software/c/projects/SWS/boards/129/backlog", icon: "  " },
                    "d": { label: "Drive", cmd: "google-chrome https://drive.google.com/drive/home", icon: "  " },
                    "m": { label: "Mail", cmd: "google-chrome https://mail.google.com/mail/u/0/#inbox", icon: "󰇮  " },
                    "c": { label: "Calendar", cmd: "google-chrome https://calendar.google.com/calendar/u/0/r", icon: "  " }
                }
            },
            "k": { label: "Bible", cmd: "alacritty -e nvim ~/dox/bible_kjv.txt", icon: "  " },
            "l": { label: "Download", cmd: "xdg-open \"$HOME/dl/$(ls -t $HOME/dl | head -n 1)\"", icon: "  " },
            "m": { label: "CaH", cmd: "mupdf -r 180 ~/dox/books/The\\ Complete\\ Calvin\\ \\&\\ Hobbes.pdf $((1 + RANDOM % 1350))", icon: "󰄛  " },
            "o": { label: "Obsidian", cmd: "obsidian \"obsidian://open?vault=vault\"", icon: "  " },
            "p": { label: "Python", cmd: "alacritty -e python3.14", icon: "  " },
            "s": {
                label: "Social/",
                icon: "  ",
                children: {
                    "p": { label: "Phone", cmd: "firefox --new-window https://messages.google.com/web/conversations", icon: "  " },
                    "d": { label: "Discord", cmd: "discord", icon: "  " },
                    "s": { label: "Slack", cmd: "slack", icon: "  " },
                    "n": { label: "Session", cmd: "session-desktop", icon: "󰿌  " },
                    "g": { label: "Signal", cmd: "signal-desktop", icon: "󰘊  " }
                }
            },
            "v": {
                label: "Services/",
                icon: "  ",
                children: {
                    "i": { label: "Immich", cmd: "firefox http://edel:2283/", icon: "  " },
                    "j": { label: "Jellyfin", cmd: "firefox http://edel:8096/", icon: "󰿎  " },
                    "t": { label: "TailScale", cmd: "firefox https://login.tailscale.com/", icon: "󰖂  " },
                    "p": { label: "Portainer", cmd: "firefox https://edel:9443/", icon: "󰡨  " },
                    "s": { label: "Stirling", cmd: "firefox http://edel:8080/", icon: "  " }
                }
            },
            "w": { label: "Wallpaper", cmd: "qs ipc call imagepicker toggle", icon: "󰸉  " },
            "y": { label: "Stator", cmd: "qs ipc call keytree toggle stator", icon: "󱇯   " }
        },
        "stator": {
            "i": { label: "Idle", cmd: "stator-rs --set-state idle", icon: "󰦖  " },
            "p": { label: "Projects", cmd: "stator-rs --set-state proj", icon: "  " },
            "w": { label: "Work", cmd: "stator-rs --set-state work", icon: "󰦑  " },
            "r": { label: "Read/Write", cmd: "stator-rs --set-state rw", icon: "  " },
            "b": { label: "Break", cmd: "stator-rs --set-state break", icon: "󱎫  " },
            "c": { label: "Chillin", cmd: "stator-rs --set-state chill", icon: "  " },
            "l": { label: "Logs", cmd: "alacritty -e zsh -c 'stator-rs --log; exec sh'", icon: "  " },
            "d": { label: "Dist", cmd: "alacritty -e zsh -c 'stator-rs --dist; exec sh'", icon: "  " }
        }
    })
}
