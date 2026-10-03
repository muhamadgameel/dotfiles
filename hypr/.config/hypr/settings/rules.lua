-- Rules are evaluated top to bottom; for overlapping matches the LAST one wins.
-- Regexes use RE2. Prefix with "negative:" to invert a match.

local theme = require("settings.theme")

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

-- ── Picture-in-picture ───────────────────────────────────────────────

-- `move` sees the window's original size, not the one set here, so the corner uses the target size.
local pip = theme.layout.pip
local margin = theme.layout.border_size
hl.window_rule({
	name = "browser-pip",
	match = { title = "^Picture[- ]in[- ][Pp]icture$" },
	float = true,
	pin = true,
	keep_aspect_ratio = true,
	size = { pip.w, pip.h },
	move = ("monitor_w-%d monitor_h-%d"):format(pip.w + margin, pip.h + margin),
})

hl.window_rule({ name = "pinned-no-dim", match = { pin = true }, no_dim = true })

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
-- Keep in step with `_gameClass` in quickshell/services/GameMode.qml (hypr/README.md).
local games = { "^steam_app_[0-9]+$", "^gamescope$" }

for _, class in ipairs({ "mpv", "chromium", "org.gnome.Loupe", table.unpack(games) }) do
	hl.window_rule({ match = { class = class }, idle_inhibit = "fullscreen" })
end

-- ── Tearing ──────────────────────────────────────────────────────────
-- allow_tearing (look.lua) is only the master switch; delete this loop for plain vsync.
for _, class in ipairs(games) do
	hl.window_rule({ match = { class = class }, immediate = true })
end

-- ── Layer rules ──────────────────────────────────────────────────────

-- fuzzel
hl.layer_rule({ match = { namespace = "launcher" }, blur = true, animation = "slide" })

-- quickshell surfaces are larger than their bodies; the transparent margin holds the shadow.
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
