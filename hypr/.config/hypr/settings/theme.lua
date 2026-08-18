-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║                      THEME / SHARED VALUES                        ║
-- ╚═══════════════════════════════════════════════════════════════════╝
-- A plain Lua module. Other files pull it in with:
--     local theme = require("settings.theme")
-- Unlike hyprlang's `$vars` (global text substitution), this is a real table:
-- scoped, introspectable, and usable in expressions.

return {
	-- ── Colors (Tokyo Night) ─────────────────────────────────────────
	colors = {
		accent = "rgb(7aa2f7)",
		accentAlpha = "rgba(7aa2f7ee)",
		inactive = "rgb(565f89)",
		surface = "rgb(1a1b26)",
		text = "rgb(c0caf5)",
	},

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
		lock = "hyprlock",
	},
}
