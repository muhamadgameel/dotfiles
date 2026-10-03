-- Flags (3rd arg): locked, release, repeating, non_consuming, mouse,
--                  transparent, ignore_mods, long_press, description

local theme = require("settings.theme")
local apps = theme.apps

local mod = "SUPER"

-- ── Apps ─────────────────────────────────────────────────────────────

hl.bind(mod .. " + Return", hl.dsp.exec_cmd(apps.terminal), { description = "Terminal" })
hl.bind(mod .. " + E", hl.dsp.exec_cmd(apps.fileManager), { description = "File manager" })
hl.bind(mod .. " + B", hl.dsp.exec_cmd(apps.browser), { description = "Browser" })

-- Toggle: second press closes the launcher.
hl.bind(mod .. " + D", hl.dsp.exec_cmd("pkill " .. apps.menu .. " || " .. apps.menu), { description = "App launcher" })

hl.bind(
	mod .. " + V",
	hl.dsp.exec_cmd("cliphist list | " .. apps.menu .. " -d --placeholder='Clipboard history…' | cliphist decode | wl-copy"),
	{ description = "Clipboard history" }
)

-- ── Windows ──────────────────────────────────────────────────────────

hl.bind(mod .. " + Q", hl.dsp.window.close(), { description = "Close window" })
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "Fullscreen" })
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized" }), { description = "Maximize" })
hl.bind(mod .. " + T", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating" })
hl.bind(mod .. " + C", hl.dsp.window.center(), { description = "Center window" })
hl.bind(mod .. " + J", hl.dsp.layout("togglesplit"), { description = "Toggle split (dwindle)" })

-- Picture-in-picture the active window.
hl.bind(mod .. " + X", function()
	local monitor = hl.get_active_monitor()
	if not monitor then
		return
	end

	local raw_screen_w = monitor.width
	local raw_screen_h = monitor.height
	local scale = monitor.scale or 1.0 -- Falls back safely to 1.0 if scale is unset

	local logical_screen_w = math.floor(raw_screen_w / scale)
	local logical_screen_h = math.floor(raw_screen_h / scale)

	local target_w = 640
	local target_h = 360

	local dest_x = logical_screen_w - target_w - theme.layout.border_size
	local dest_y = logical_screen_h - target_h - theme.layout.border_size

	hl.dispatch(hl.dsp.window.float({ action = "set" }))
	hl.dispatch(hl.dsp.window.pin({ action = "enable" }))
	hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 0, client = 2 }))
	hl.dispatch(hl.dsp.window.resize({ x = target_w, y = target_h }))
	hl.dispatch(hl.dsp.window.move({ x = dest_x, y = dest_y }))
end, { description = "Picture-in-picture" })

-- ── Focus / move ─────────────────────────────────────────────────────
for _, dir in ipairs({ "left", "right", "up", "down" }) do
	hl.bind(mod .. " + " .. dir, hl.dsp.focus({ direction = dir }), { description = "Move focus" })
	hl.bind(mod .. " + SHIFT + " .. dir, hl.dsp.window.move({ direction = dir }), { description = "Move window" })
end
hl.bind(mod .. " + U", hl.dsp.focus({ urgent_or_last = true }), { description = "Focus urgent or last" })

-- ── Mouse ────────────────────────────────────────────────────────────
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Drag window" })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })

-- Clicking outside an open shell panel closes it; non_consuming, so the click still lands.
hl.bind("mouse:272", hl.dsp.global("quickshell:panelDismiss"), {
	non_consuming = true,
	description = "Dismiss an open shell panel",
})

-- ── Workspaces ───────────────────────────────────────────────────────

for i = 1, 10 do
	local key = i % 10 -- workspace 10 lives on key 0
	hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }), { description = "Go to workspace" })
	hl.bind(
		mod .. " + SHIFT + " .. key,
		hl.dsp.window.move({ workspace = i, follow = false }),
		{ description = "Send window to workspace" }
	)
	hl.bind(
		mod .. " + ALT + " .. key,
		hl.dsp.window.move({ workspace = i, follow = true }),
		{ description = "Send window to workspace and follow" }
	)
end

-- Cycle through open workspaces.
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "Previous workspace" })
hl.bind(mod .. " + bracketright", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
hl.bind(mod .. " + bracketleft", hl.dsp.focus({ workspace = "e-1" }), { description = "Previous workspace" })

-- Scratchpad.
hl.bind(mod .. " + S", hl.dsp.workspace.toggle_special("magic"), { description = "Toggle scratchpad" })
hl.bind(
	mod .. " + SHIFT + S",
	hl.dsp.window.move({ workspace = "special:magic" }),
	{ description = "Send to scratchpad" }
)

-- ── Monitors ─────────────────────────────────────────────────────────
hl.bind(mod .. " + comma", hl.dsp.focus({ monitor = "-1" }), { description = "Focus previous monitor" })
hl.bind(mod .. " + period", hl.dsp.focus({ monitor = "+1" }), { description = "Focus next monitor" })
hl.bind(
	mod .. " + SHIFT + comma",
	hl.dsp.window.move({ monitor = "-1", follow = true }),
	{ description = "Move window to previous monitor" }
)
hl.bind(
	mod .. " + SHIFT + period",
	hl.dsp.window.move({ monitor = "+1", follow = true }),
	{ description = "Move window to next monitor" }
)

-- ── Screenshots ──────────────────────────────────────────────────────

-- mkdir -p so the bind still works if ~/Pictures/Screenshots is ever missing;
-- grim would otherwise fail silently.
local shotDir = '"$(xdg-user-dir PICTURES)/Screenshots"'
local shotFile = shotDir .. '/"$(date +%Y%m%d_%H%M%S)".png'
local mkdir = "mkdir -p " .. shotDir .. " && "

hl.bind(
	"Print",
	hl.dsp.exec_cmd(mkdir .. 'grim -g "$(slurp)" ' .. shotFile),
	{ description = "Screenshot region to file" }
)
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(mkdir .. "grim " .. shotFile), { description = "Screenshot to file" })
hl.bind(
	mod .. " + Print",
	hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'),
	{ description = "Screenshot region to clipboard" }
)
hl.bind(mod .. " + SHIFT + Print", hl.dsp.exec_cmd("grim - | wl-copy"), { description = "Screenshot to clipboard" })


-- ── Shell panels ─────────────────────────────────────────────────────
-- Global shortcuts the running shell registers (hypr/README.md); SUPER+letter stays with apps.

local panels = {
	A = { "panelAudio", "Audio panel" },
	B = { "panelBluetooth", "Bluetooth panel" },
	D = { "toggleDnd", "Toggle do not disturb" },
	E = { "panelSettings", "Settings panel" },
	G = { "panelSystemStats", "System stats panel" },
	I = { "toggleIdleInhibit", "Toggle stay awake" },
	K = { "panelCalendar", "Calendar panel" },
	L = { "toggleNightLight", "Toggle night light" },
	M = { "panelMedia", "Media panel" },
	N = { "panelNotifications", "Notifications panel" },
	P = { "panelPower", "Power panel" },
	Q = { "panelQuickSettings", "Quick settings panel" },
	W = { "panelNetwork", "Network panel" },
	-- Not Print: SUPER+SHIFT+Print is already screenshot-to-clipboard.
	X = { "panelScreenshot", "Screenshot panel" },
	-- No mnemonic left: every letter in "wallpaper" is taken.
	Y = { "panelWallpaper", "Wallpaper panel" },
}

for key, panel in pairs(panels) do
	hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.global("quickshell:" .. panel[1]), { description = panel[2] })
end

-- Dismiss whatever is open. Not SUPER+SHIFT+Escape -- that is Log out.
hl.bind(mod .. " + grave", hl.dsp.global("quickshell:panelClose"), { description = "Close any shell panel" })

-- ── System ───────────────────────────────────────────────────────────

hl.bind(mod .. " + Escape", hl.dsp.exec_cmd(apps.lock), { description = "Lock screen" })
-- uwsm stop, not hl.dsp.exit(), so the session shuts down in order.
hl.bind(mod .. " + SHIFT + Escape", hl.dsp.exec_cmd("uwsm stop"), { description = "Log out" })

-- ── Brightness ───────────────────────────────────────────────────────
-- Linear (no -e4), to match the shell's slider (hypr/README.md).
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("brightnessctl -n2 set 5%+"),
	{ locked = true, repeating = true, description = "Brightness up" }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("brightnessctl -n2 set 5%-"),
	{ locked = true, repeating = true, description = "Brightness down" }
)

-- ── Volume ───────────────────────────────────────────────────────────
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true, description = "Volume up" }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true, description = "Volume down" }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, description = "Mute" }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, description = "Mute microphone" }
)

-- ── Media ────────────────────────────────────────────────────────────
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play/pause" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play/pause" })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, description = "Next track" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, description = "Previous track" })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true, description = "Stop playback" })

hl.bind(
	mod .. " + XF86AudioNext",
	hl.dsp.exec_cmd("playerctl position 5+"),
	{ locked = true, description = "Seek forward 5 s" }
)
hl.bind(
	mod .. " + XF86AudioPrev",
	hl.dsp.exec_cmd("playerctl position 5-"),
	{ locked = true, description = "Seek back 5 s" }
)

-- ── Utility ──────────────────────────────────────────────────────────

hl.bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"), { description = "Color picker" })

-- Every described bind, searchable; the digit and arrow rows fold into one line each.
local cheatsheet = [=[hyprctl binds -j | jq -r '
	def m($bit; $name): if (.modmask / $bit | floor) % 2 == 1 then $name else empty end;
	[.[] | select(.has_description)
		| .key |= (if test("^[0-9]$") then "1-0" elif test("^(left|right|up|down)$") then "arrows" else . end)
		| ([m(64; "SUPER"), m(4; "CTRL"), m(8; "ALT"), m(1; "SHIFT"), .key] | join(" + ")) + "\t" + .description]
	| unique[]' | column -t -s "$(printf '\t')" | ]=] .. apps.menu .. " -d --placeholder='Keybinds…'"

hl.bind(mod .. " + F1", hl.dsp.exec_cmd(cheatsheet), { description = "Keybind cheat sheet" })

-- Cycle the tiling layout.
local layouts = { "dwindle", "master", "scrolling" }

hl.bind(mod .. " + L", function()
	local current = hl.get_config("general.layout")
	local nextIdx = 1
	for i, name in ipairs(layouts) do
		if name == current then
			nextIdx = (i % #layouts) + 1
			break
		end
	end
	local nextLayout = layouts[nextIdx]
	hl.config({ general = { layout = nextLayout } })
	hl.notification.create({ text = "Layout: " .. nextLayout, timeout = 1500, icon = "ok" })
end, { description = "Cycle layout" })
