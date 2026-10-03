-- The daemons and the shell are systemd user units (hypr/README.md), not started here.
hl.on("hyprland.start", function()
	-- File manager daemon
	hl.exec_cmd("uwsm app -- thunar --daemon")
end)
