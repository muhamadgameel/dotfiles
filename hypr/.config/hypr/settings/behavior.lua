hl.config({
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		font_family = "Roboto", -- the shell's fontFamily (quickshell config/Config.qml)

		vrr = 2,

		mouse_move_enables_dpms = true,
		key_press_enables_dpms = true,

		-- If hyprlock dies while locked, a new one may take over instead of a dead lock screen.
		allow_session_lock_restore = true,
	},

	ecosystem = {
		no_update_news = true,
		no_donation_nag = true,
	},

	cursor = {
		inactive_timeout = 5,
		hide_on_key_press = true,
	},

	render = {
		direct_scanout = 2,
	},

	xwayland = {
		-- XWayland apps draw at native pixels and scale themselves; otherwise the
		-- compositor upscales them 1.333x and they blur.
		force_zero_scaling = true,
	},

	binds = {
		workspace_back_and_forth = true,
		allow_workspace_cycles = true,
		scroll_event_delay = 100,
		hide_special_on_workspace_change = true,
	},
})
