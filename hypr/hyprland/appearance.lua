hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,

        border_size = 0,
        resize_on_border = false,
        allow_tearing = false,
        layout = "scrolling",
    },
    dwindle = {
        force_split = 2,
    },
    master = {
        new_status = "master",
    },
    scrolling = {
        direction = "right", -- overridden in rules.lua
        column_width = 0.49,
        wrap_swapcol = false,
    },

    decoration = {
        -- corner-radius = 12 in picom.conf
        rounding = 12,
        rounding_power = 2,

        -- active-opacity = 1 / inactive-opacity = 0.6 in picom.conf
        active_opacity = 1.0,
        inactive_opacity = 0.6,

        -- i3 setup toggled picom for shadow/blur (see `toggle-picom` bind in old config).
        -- Hyprland's compositor replaces picom outright, so these give the same eye-candy
        -- natively; mod+SHIFT+c flips blur on/off instead.
        shadow = {
            enabled = true,
            range = 2,
            render_power = 1,
            offset = { 1, 1 },
            color = "rgba(0a0a0a8f)",
        },

        blur = {
            enabled = true,
            size = 4,
            passes = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = false,
        disable_splash_rendering = true,
        vrr = 2,
        allow_session_lock_restore = true,
    },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } }, })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } }, })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } }, })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } }, })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } }, })

hl.animation({ leaf = "global",         enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",         enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",        enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",      enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 60%" })
hl.animation({ leaf = "windowsOut",     enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",         enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",        enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",           enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",         enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",       enabled = true, speed = 2.0,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",      enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",   enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut",  enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",     enabled = true, speed = 2.0, bezier = "easeInOutCubic", style = "slidevert" })

