-- ── Colors (Tokyo Night) ─────────────────────────────────────────
-- The shell's hyprland-colors.lua overrides these key by key; a bad file keeps them.
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
		terminal = "uwsm-app -- alacritty", -- its own systemd scope, not the compositor's
		fileManager = "thunar",
		browser = "chromium",
		menu = "fuzzel",
		lock = "pidof hyprlock || hyprlock", -- same guard as hypridle's lock_cmd
	},
}
