hl.workspace_rule({
    workspace = "m[DP-2]",
    layout_opts = {
        direction = "right",
    },
})

hl.workspace_rule({
    workspace = "m[DP-1]",
    layout_opts = {
        direction = "down",
    },
})

hl.window_rule({
    name = "float-ui-service",
    match = { class = "^(ui_service\\.py|launch_workstation\\.py)$" },
    float = true,
})

hl.window_rule({
    match = {
        class = "(?i)^(nsxiv|com.gabm.satty|mpv|org.pulseaudio.pavucontrol)$"
    },
    float = true,
    center = true,
    size = { "(monitor_w*0.65)", "(monitor_h*0.70)" },
})

hl.window_rule({
    match = {
        class = "^btop$"
    },
    float = true,
    center = true,
    size = { "(monitor_w*0.90)", "(monitor_h*0.70)" },
})

-- -- Real compositor blur for Keytree's disc (see
-- -- quickshell/modules/keytree/KeytreeWindow.qml's BackgroundEffect.blurRegion).
-- -- ignore_alpha is required: the disc content is a mostly-transparent tint
-- -- rectangle, and without it Hyprland renders that as an opaque fallback
-- -- square instead of blurring through it.
-- hl.layer_rule({
--     match = { namespace = "^quickshell:keytree$" },
--     blur = true,
--     ignore_alpha = 0.01,
-- })
