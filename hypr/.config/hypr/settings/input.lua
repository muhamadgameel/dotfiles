hl.config({
	input = {
		-- ── Keyboard ─────────────────────────────────────────────────
		kb_layout = "us,ara",
		numlock_by_default = true,

		repeat_rate = 50,
		repeat_delay = 300,

		-- ── Mouse ────────────────────────────────────────────────────
		sensitivity = 0.4, -- -1.0 to 1.0, 0 = unmodified
		accel_profile = "adaptive", -- "flat" or "adaptive"
		scroll_factor = 1.4,

		-- ── Touchpad ─────────────────────────────────────────────────
		touchpad = {
			natural_scroll = true,
			scroll_factor = 0.8,
			middle_button_emulation = true,
		},
	},
})

-- ── Gestures ─────────────────────────────────────────────────────────
-- Three fingers left/right: switch workspaces.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Two-finger pinch out: zoom the cursor area.
hl.gesture({ fingers = 2, direction = "pinchout", action = "cursor_zoom", zoom_level = 3 })
