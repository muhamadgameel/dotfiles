local theme = require("settings.theme")

-- Every colour option. The shell's ThemeSync calls it through hyprctl eval when the theme changes.
local function paint(colors)
	local active = { colors = { colors.accent, colors.accentAlt }, angle = 45 }
	hl.config({
		general = {
			col = { active_border = active, inactive_border = colors.inactive },
		},
		-- The groupbar redraws its tabs only when these border colours are set, so both go in one call.
		group = {
			col = { border_active = active, border_inactive = colors.inactive },
			groupbar = {
				col = { active = colors.accent, inactive = colors.surface },
				text_color = colors.surface,
				text_color_inactive = colors.text,
			},
		},
	})
end

hl.config({
	general = {
		border_size = theme.layout.border_size,
		gaps_in = 4,
		gaps_out = 8,

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
		},

		shadow = {
			range = 20,
			offset = { 0, 4 },
		},

		motion_blur = {
			enabled = true,
		},

		dim_inactive = true,
		dim_strength = 0.15,
		dim_special = 0.6,
	},
})

-- ── Window groups ────────────────────────────────────────────────────
-- Tabs filled with the colours from paint(); the indicator under each can't go below 1 px.
hl.config({
	group = {
		groupbar = {
			font_size = 11,
			height = 22,
			gradients = true,
			gradient_rounding = 6,
			gradient_round_only_edges = false,
			gaps_in = 4,
			gaps_out = 4,
			indicator_height = 0,
		},
	},
})

paint(theme.colors)

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

return { paint = paint }
