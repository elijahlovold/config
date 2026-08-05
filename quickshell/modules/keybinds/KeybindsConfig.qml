pragma Singleton
import Quickshell

Singleton {
    readonly property string sourceFile: Quickshell.env("HOME") + "/.config/hypr/hyprland/keybinds.lua"
}
