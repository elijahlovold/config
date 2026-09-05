hl.on("hyprland.start", function()
    hl.exec_cmd("openrgb --server")

    -- hl.exec_cmd("hyprpaper")
    hl.exec_cmd("wallpaper-picker")

    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    hl.exec_cmd("quickshell")
    -- hl.exec_cmd("hyprpolkitagent") -- DNE currently
end)
