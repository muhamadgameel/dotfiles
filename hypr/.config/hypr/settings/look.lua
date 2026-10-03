local theme = require("settings.theme")
local colors = theme.colors

hl.config({
	general = {
		border_size = theme.layout.border_size,
		gaps_in = 4,
		gaps_out = 8,

		col = {
			active_border = colors.accent,
			inactive_border = colors.inactive,
		},

		-- Drag borders and gaps to resize.
		resize_on_border = true,

		-- Only takes effect on windows carrying the `immediate` rule.
		-- See the tearing section in settings/rules.lua.
		allow_tearing = true,

		snap = {
			enabled = true,
		},
	},

	decoration = {
		rounding = 12,

		blur = {
			size = 4,
			passes = 2,
			noise = 0.02,
			vibrancy = 0.2,
			popups = true,
		},

		shadow = {
			range = 20,
			offset = { 0, 4 },
		},

		dim_inactive = true,
		dim_strength = 0.15,
		dim_special = 0.3,
	},
})

-- ── Layout: dwindle ──────────────────────────────────────────────────
hl.config({
	dwindle = {
		preserve_split = true,
		force_split = 2, -- always split to the right / bottom
	},
})

-- ── Layout: master ───────────────────────────────────────────────────
hl.config({
	master = {
		new_status = "master",
		mfact = 0.6, -- master window takes 60% of the screen
	},
})
