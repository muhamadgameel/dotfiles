hl.config({
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,

		vrr = 2, -- adaptive sync: 0 off, 1 on, 2 fullscreen only, 3 fullscreen video

		-- Wake the display on input.
		mouse_move_enables_dpms = true,
		key_press_enables_dpms = true,

		initial_workspace_tracking = 1,
		middle_click_paste = true,
	},

	cursor = {
		inactive_timeout = 5,
		hide_on_key_press = true,
		hide_on_touch = true,
	},

	render = {
		direct_scanout = 2, -- reduces latency for fullscreen apps
	},

	xwayland = {
		-- Render XWayland apps at native resolution instead of letting them
		-- scale themselves. Important on this 1.333x fractional-scale panel.
		force_zero_scaling = true,
	},

	binds = {
		workspace_back_and_forth = true,
		allow_workspace_cycles = true,
		scroll_event_delay = 100,
	},
})
