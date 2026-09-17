-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║                      THEME / SHARED VALUES                        ║
-- ╚═══════════════════════════════════════════════════════════════════╝
-- A plain Lua module. Other files pull it in with:
--     local theme = require("settings.theme")
-- Unlike hyprlang's `$vars` (global text substitution), this is a real table:
-- scoped, introspectable, and usable in expressions.

-- ── Colors (Tokyo Night) ─────────────────────────────────────────
-- Used as-is until the shell has run. quickshell writes the active theme's
-- colours to hyprland-colors.lua (services/ThemeSync.qml), which overrides
-- these key by key. Guarded, so a missing or broken file keeps the defaults
-- rather than failing the whole config.
local colors = {
	accent = "rgb(7aa2f7)",
	accentAlpha = "rgba(7aa2f7ee)",
	inactive = "rgb(565f89)",
	surface = "rgb(1a1b26)",
	text = "rgb(c0caf5)",
}

local ok, generated = pcall(function()
	local state = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
	return dofile(state .. "/quickshell/hyprland-colors.lua")
end)
if ok and type(generated) == "table" then
	for key, value in pairs(generated) do
		colors[key] = value
	end
end

return {
	colors = colors,

	-- ── Layout ─────────────────────────────────────────
	layout = {
		border_size = 2,
	},

	-- ── Default applications ─────────────────────────────────────────
	apps = {
		terminal = "alacritty",
		fileManager = "thunar",
		browser = "chromium",
		menu = "fuzzel",
		lock = "pidof hyprlock || hyprlock", -- same guard as hypridle's lock_cmd
	},
}
