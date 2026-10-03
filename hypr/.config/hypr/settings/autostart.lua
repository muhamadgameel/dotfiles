-- The daemons and the shell are systemd user units (hypr/README.md), not started here.
hl.on("hyprland.start", function()
	-- Polkit agent (GUI privilege prompts)
	hl.exec_cmd("uwsm app -- /usr/lib/polkit-kde-authentication-agent-1")

	-- File manager daemon
	hl.exec_cmd("uwsm app -- thunar --daemon")

	-- Clipboard history: keep entries after the source app exits.
	-- These watch for the whole session and belong to the compositor, not to an app.
	hl.exec_cmd("wl-paste --type text  --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
