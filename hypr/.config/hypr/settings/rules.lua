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

-- ── Games && Idle inhibition ──────────────────────────
-- hypridle dims at 5 min and locks at 20 min. Apps that speak the Wayland
-- idle-inhibit protocol (Chromium during playback) are already honored via
-- hypridle's `ignore_dbus_inhibit = false`; this covers the ones that aren't,
-- and only while they are actually fullscreen.

-- Window classes that are games. Proton titles are steam_app_<id>; gamescope
-- nests anything run inside it. Native Linux games use their own class - add
-- them here as they come up.
--
-- Keep in step with `_gameClass` in quickshell/services/GameMode.qml, which
-- uses the same classes to spot a fullscreen game not launched via gamemoderun.
local games = { "^steam_app_[0-9]+$", "^gamescope$" }

for _, class in ipairs({ "mpv", "chromium", "org.gnome.Loupe", table.unpack(games) }) do
	hl.window_rule({ match = { class = class }, idle_inhibit = "fullscreen" })
end

-- ── Tearing ──────────────────────────────────────────────────────────
-- `general.allow_tearing` (look.lua) is only a master switch: a window tears
-- only if it also carries `immediate`. Games get it, so a fullscreen game can
-- put a frame on screen as soon as it is ready instead of waiting for vsync -
-- lower input latency, at the cost of possible tear lines.
--
-- To go back to plain vsync, delete this loop; allow_tearing can stay on, it
-- does nothing without it.
for _, class in ipairs(games) do
	hl.window_rule({ match = { class = class }, immediate = true })
end

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
