-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║                       INPUT AND GESTURES                          ║
-- ╚═══════════════════════════════════════════════════════════════════╝

hl.config({
	input = {
		-- ── Keyboard ─────────────────────────────────────────────────
		kb_layout = "us,ara",
		kb_options = "grp:win_space_toggle",
		numlock_by_default = true,

		repeat_rate = 50,
		repeat_delay = 300,

		-- ── Mouse ────────────────────────────────────────────────────
		follow_mouse = 1, -- focus follows mouse
		mouse_refocus = true,
		sensitivity = 0.4, -- -1.0 to 1.0, 0 = unmodified
		accel_profile = "adaptive", -- "flat" or "adaptive"
		scroll_factor = 1.4,

		-- ── Touchpad ─────────────────────────────────────────────────
		touchpad = {
			disable_while_typing = true,
			natural_scroll = true,
			scroll_factor = 0.8,
			tap_to_click = true, -- was `tap-to-click` in hyprlang
			tap_and_drag = true,
			drag_lock = false,
			middle_button_emulation = true,
		},
	},
})

-- ── Gestures ─────────────────────────────────────────────────────────
-- Three fingers left/right: switch workspaces.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Two-finger pinch out: zoom the cursor area.
-- The hyprlang name was `cursorZoom` with a positional argument; in Lua the
-- action is `cursor_zoom` and the factor is the named `zoom_level`.
hl.gesture({ fingers = 2, direction = "pinchout", action = "cursor_zoom", zoom_level = 3 })
