hl.monitor({
    output = "DP-1",
    mode = "1920x1080@60",
    position = "0x0",
    scale = 1,
    transform = 3,
})

hl.monitor({
    output = "DP-2",
    mode = "3840x2160@60",
    position = "auto",
    scale = "auto",
})

-- hl.monitor({
--     output = "HDMI-A-1",
--     mode = "1920x1080@60",
--     position = "auto",
--     scale = "auto",
-- })

hl.monitor({ output = "HDMI-A-1", disabled = true })

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})
