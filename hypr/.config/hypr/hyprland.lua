-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║                     HYPRLAND CONFIGURATION                        ║
-- ╚═══════════════════════════════════════════════════════════════════╝
-- Hyprland >= 0.55 uses Lua; hyprlang is dropped in 0.57.
--
-- Docs:  https://wiki.hypr.land/Configuring/Start/
-- Stubs: /usr/share/hypr/stubs/hl.meta.lua  (wired up via .luarc.json)
--
-- Each require() is its own error-isolated scope: a runtime error in one file
-- aborts that file only, and the rest still load.

require("settings.theme") -- module: colors + app names (returns a table)
require("settings.env") -- environment variables
require("settings.monitors") -- outputs
require("settings.look") -- borders, gaps, decoration, layouts
require("settings.behavior") -- misc, cursor, render, xwayland, binds
require("settings.animations")
require("settings.input") -- keyboard, mouse, touchpad, gestures
require("settings.rules") -- window / layer / workspace rules
require("settings.keybinds")
require("settings.autostart")
