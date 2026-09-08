-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║                  WINDOW / LAYER / WORKSPACE RULES                 ║
-- ╚═══════════════════════════════════════════════════════════════════╝
-- Rules are evaluated top to bottom; for overlapping matches the LAST one wins.
-- Regexes use RE2. Prefix with "negative:" to invert a match.

-- ── Global ───────────────────────────────────────────────────────────

hl.window_rule({
	name = "suppress-maximize",
	match = { class = ".*" },
	suppress_event = "maximize",
})

hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

-- ── Floating: system utilities ───────────────────────────────────────

hl.window_rule({ match = { class = "nm-connection-editor" }, float = true })
hl.window_rule({ match = { class = "blueman-manager" }, float = true })
hl.window_rule({ match = { class = "org.kde.polkit-kde-authentication-agent-1" }, float = true })

hl.window_rule({
	name = "pavucontrol",
	match = { class = "org.pulseaudio.pavucontrol" },
	float = true,
	size = { 800, 600 },
})

-- ── Floating: file dialogs ───────────────────────────────────────────

for _, title in ipairs({ "^(Open File)(.*)$", "^(Save File)(.*)$" }) do
	hl.window_rule({ match = { title = title }, float = true, size = { 900, 600 } })
end

for _, title in ipairs({ "^(Open Folder)(.*)$", "^(Select)(.*)$", "^(Rename)(.*)$" }) do
	hl.window_rule({ match = { title = title }, float = true })
end

-- ── Floating: desktop apps ───────────────────────────────────────────

for _, class in ipairs({ "imv", "org.gnome.Loupe", "org.gnome.FileRoller" }) do
	hl.window_rule({ match = { class = class }, float = true })
end

-- ── Steam ────────────────────────────────────────────────────────────

hl.window_rule({ match = { class = "steam", title = "^(Friends List)$" }, float = true })
hl.window_rule({ match = { class = "steam", title = "^(Steam Settings)$" }, float = true })

hl.window_rule({
	name = "steam-stay-focused",
	match = { class = "steam", title = "^()$" },
	stay_focused = true,
})

-- ── Transparency ─────────────────────────────────────────────────────
-- "active inactive" -- multiplied, not absolute (append " override" for absolute).

hl.window_rule({ match = { class = "Alacritty" }, opacity = "1.0 0.92" })

-- ── Idle inhibition ──────────────────────────────────────────────────
-- hypridle dims at 5 min and locks at 20 min. Apps that speak the Wayland
-- idle-inhibit protocol (Chromium during playback) are already honored via
-- hypridle's `ignore_dbus_inhibit = false`; this covers the ones that aren't,
-- and only while they are actually fullscreen.

for _, class in ipairs({ "mpv", "chromium", "org.gnome.Loupe" }) do
	hl.window_rule({ match = { class = class }, idle_inhibit = "fullscreen" })
end

-- ── Tearing ──────────────────────────────────────────────────────────
-- `general.allow_tearing` is a master switch only: tearing is applied per
-- window via the `immediate` rule. Without a rule like this, enabling it in
-- look.lua does nothing. Uncomment and adjust per game.
--
-- hl.window_rule({ match = { class = "^(steam_app_%d+)$" }, immediate = true })
-- hl.window_rule({ match = { class = "gamescope" },         immediate = true })

-- ── Layer rules ──────────────────────────────────────────────────────

-- fuzzel
hl.layer_rule({ match = { namespace = "launcher" }, blur = true, animation = "slide" })

-- quickshell: the bar, the OSD, the notification popups and the sliding panels
-- all draw a translucent rounded body inside a slightly larger transparent
-- window - that extra room is where their drop shadows land.
hl.layer_rule({
	match = { namespace = "^quickshell-" },
	blur = true,
	ignore_alpha = 0.4,
})

-- The panels run their own slide animation; a compositor animation on top of it
-- animates the open twice.
hl.layer_rule({ match = { namespace = "^quickshell-.*panel$" }, no_anim = true })

-- ── Workspace rules: smart gaps ──────────────────────────────────────
-- One tiled window (w[tv1]) or one fullscreen window (f[1]) gets no gaps,
-- no border and no rounding. `s[false]` excludes special workspaces.

for _, ws in ipairs({ "w[tv1]s[false]", "f[1]s[false]" }) do
	hl.workspace_rule({ workspace = ws, gaps_out = 0, gaps_in = 0 })
	hl.window_rule({
		match = { float = false, workspace = ws },
		border_size = 0,
		rounding = 0,
	})
end
