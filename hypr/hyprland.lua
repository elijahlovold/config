-- https://wiki.hypr.land/Configuring/
-- https://alejandrominaya.github.io/hyprland-lua-docs/


-- Default configurations --
require("hyprland.env")
require("hyprland.start")
require("hyprland.monitors")
require("hyprland.rules")
-- require("hyprland.colors")
require("hyprland.keybinds")
require("hyprland.input")
require("hyprland.appearance")


-----------------
--- PERMISSIONS ---
-----------------

-- See https://wiki.hypr.land/Configuring/Permissions/
-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
