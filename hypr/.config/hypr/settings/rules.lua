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
hl.window_rule({ match = { class = "org.kde.polkit-kde-authentication-agent-1" }, float = true })
hl.window_rule({ match = { class = "^(protonvpn-app|proton\\.vpn\\.app\\.gtk)$" }, float = true, center = true })

hl.window_rule({
	name = "pavucontrol",
	match = { class = "org.pulseaudio.pavucontrol" },
	float = true,
	size = { 800, 600 },
})

-- ── Floating: dialogs and prompts ────────────────────────────────────

-- The portal's file dialogs have no parent window, so Hyprland doesn't float them itself.
hl.window_rule({ match = { class = "^xdg-desktop-portal-gtk$" }, float = true })
hl.window_rule({
	match = { class = "^xdg-desktop-portal-gtk$", title = "^(Open|Save|Select)" },
	size = { 900, 600 },
})
hl.window_rule({ match = { class = "^[Tt]hunar$", title = "^Rename" }, float = true })

hl.window_rule({
	name = "password-prompts",
	match = { class = "^(gcr-prompter|org\\.gnupg\\.pinentry-.*|pinentry-.*)$" },
	float = true,
	center = true,
	stay_focused = true,
})
hl.window_rule({ match = { class = "^zenity$" }, float = true, center = true })

-- ── Floating: desktop apps ───────────────────────────────────────────

for _, class in ipairs({ "org.gnome.Loupe", "org.gnome.FileRoller" }) do
	hl.window_rule({ match = { class = class }, float = true })
end

-- ── Privacy ──────────────────────────────────────────────────────────

hl.window_rule({ match = { class = "^(?i)bitwarden$" }, no_screen_share = true })

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

-- ── Games and idle ───────────────────────────────────────────────────
-- The same pattern as `_gameClass` in quickshell/services/GameMode.qml (hypr/README.md).
local games = "^(steam_app_[0-9]+|gamescope)$"

-- Fullscreen video and games keep the screen awake even when paused; the apps only ask while playing.
for _, class in ipairs({ "mpv", "chromium", "org.gnome.Loupe", games }) do
	hl.window_rule({ match = { class = class }, idle_inhibit = "fullscreen" })
end

-- ── Tearing ──────────────────────────────────────────────────────────
-- allow_tearing (look.lua) is only the master switch; delete this rule for plain vsync.
hl.window_rule({ match = { class = games }, immediate = true })

-- ── Layer rules ──────────────────────────────────────────────────────

-- fuzzel
hl.layer_rule({ match = { namespace = "launcher" }, blur = true, animation = "slide" })

-- slurp and hyprpicker: grim captures the moment they exit, and a fading overlay would be in the shot.
hl.layer_rule({ match = { namespace = "^(selection|hyprpicker)$" }, no_anim = true })

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
