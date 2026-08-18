-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║                      AUTO-START PROGRAMS                          ║
-- ╚═══════════════════════════════════════════════════════════════════╝
-- NOT started here (they are enabled systemd user services -- check with
-- `systemctl --user status hypridle hyprpaper`):
--     hypridle, hyprpaper
--
-- Long-lived apps are launched via `uwsm app --` so each lands in its own
-- systemd scope instead of being a bare child of the compositor. That gives
-- correct cgroup accounting and lets the OOM killer pick the app rather than
-- the whole session.

hl.on("hyprland.start", function()
	-- Shell / panel
	hl.exec_cmd("uwsm app -- qs")

	-- Polkit agent (GUI privilege prompts)
	hl.exec_cmd("uwsm app -- /usr/lib/polkit-kde-authentication-agent-1")

	-- File manager daemon
	hl.exec_cmd("uwsm app -- thunar --daemon")

	-- Clipboard history: keep entries after the source app exits.
	-- These are short-lived watchers tied to the compositor, not apps.
	hl.exec_cmd("wl-paste --type text  --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
