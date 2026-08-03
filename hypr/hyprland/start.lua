hl.on("hyprland.start", function()
    hl.exec_cmd("pipewire")
    hl.exec_cmd("wireplumber")
    hl.exec_cmd("pipewire-pulse")
    hl.exec_cmd("openrgb --server")

    hl.exec_cmd("dunst")

    -- hl.exec_cmd("toggle-monitors --reset") -- X11/xrandr script - needs a wlr-randr/hyprctl rewrite

    -- hl.exec_cmd("hyprpaper")
    hl.exec_cmd("wallpaper-picker")

    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    hl.exec_cmd("quickshell")
    -- No polkit agent is currently installed - install one and uncomment, see notes.
    -- hl.exec_cmd("hyprpolkitagent")
end)
