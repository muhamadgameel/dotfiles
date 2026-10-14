-- Bind options (3rd arg): locked, repeating, non_consuming, mouse, description and more;
-- HL.BindOptions in /usr/share/hypr/stubs/hl.meta.lua has the full list.

local theme = require("settings.theme")
local apps = theme.apps

local mod = "SUPER"

-- A bind made with bind() is also listed in the command palette (SUPER+P); hl.bind makes one that is not.
local palette = {}

local function bind(keys, action, opts)
	hl.bind(keys, action, opts)
	palette[#palette + 1] = { opts.description, keys, action }
end

-- ── Apps ─────────────────────────────────────────────────────────────

bind(mod .. " + Return", hl.dsp.exec_cmd(apps.terminal), { description = "Terminal" })
bind(
	mod .. " + SHIFT + Return",
	hl.dsp.exec_cmd(apps.terminal .. " -e sh -c 'tmux attach || tmux new'"),
	{ description = "Terminal on the last tmux session" }
)
bind(mod .. " + E", hl.dsp.exec_cmd(apps.fileManager), { description = "File manager" })
bind(mod .. " + B", hl.dsp.exec_cmd(apps.browser), { description = "Browser" })

-- Toggle: second press closes the launcher.
bind(mod .. " + D", hl.dsp.exec_cmd("pkill " .. apps.menu .. " || " .. apps.menu), { description = "App launcher" })

-- wl-copy with nothing to copy empties the clipboard, so it runs only after a pick.
bind(
	mod .. " + V",
	hl.dsp.exec_cmd(
		"sel=$(cliphist list | "
			.. apps.menu
			.. " -d --only-match --placeholder='Clipboard history…'); "
			.. '[ -n "$sel" ] && printf \'%s\' "$sel" | cliphist decode | wl-copy'
	),
	{ description = "Clipboard history" }
)

bind(
	mod .. " + SHIFT + V",
	hl.dsp.exec_cmd(
		"voxtype record toggle || notify-send -a Dictation -- 'No dictation' 'The voxtype service is not running.'"
	),
	{ description = "Dictation on and off" }
)

-- ── Windows ──────────────────────────────────────────────────────────

bind(mod .. " + Q", hl.dsp.window.close(), { description = "Close window" })
bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "Fullscreen" })
bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized" }), { description = "Maximize" })
bind(mod .. " + T", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating" })
bind(mod .. " + C", hl.dsp.window.center(), { description = "Center window" })
bind(mod .. " + J", hl.dsp.layout("togglesplit"), { description = "Toggle split (dwindle)" })

-- Picture-in-picture the active window; a second press puts it back.
local pip_saved = {} -- window address -> where a floating window was

bind(mod .. " + X", function()
	local window = hl.get_active_window()
	if not window then
		return
	end

	if window.pinned then
		local saved = pip_saved[window.address]
		pip_saved[window.address] = nil
		hl.dispatch(hl.dsp.window.pin({ action = "disable" }))
		hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 0, client = 0 }))
		if saved then
			hl.dispatch(hl.dsp.window.resize({ x = saved.w, y = saved.h }))
			hl.dispatch(hl.dsp.window.move({ x = saved.x, y = saved.y }))
		else
			hl.dispatch(hl.dsp.window.float({ action = "disable" }))
		end
		return
	end

	local monitor = window.monitor
	if not monitor then
		return
	end
	if window.floating then
		pip_saved[window.address] = { x = window.at.x, y = window.at.y, w = window.size.x, h = window.size.y }
	end

	local pip = theme.layout.pip
	local margin = theme.layout.border_size
	-- Rounded: the scale is stored as 1.3333334, and floor would lose a pixel.
	local x = monitor.x + math.floor(monitor.width / monitor.scale + 0.5) - pip.w - margin
	local y = monitor.y + math.floor(monitor.height / monitor.scale + 0.5) - pip.h - margin

	-- client = 2 tells the app it is fullscreen, so a video fills the small window.
	hl.dispatch(hl.dsp.window.float({ action = "enable" }))
	hl.dispatch(hl.dsp.window.pin({ action = "enable" }))
	hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 0, client = 2 }))
	hl.dispatch(hl.dsp.window.resize({ x = pip.w, y = pip.h }))
	hl.dispatch(hl.dsp.window.move({ x = x, y = y }))
end, { description = "Picture-in-picture" })

-- ── Focus / move ─────────────────────────────────────────────────────
local resize_step =
	{ left = { x = -40, y = 0 }, right = { x = 40, y = 0 }, up = { x = 0, y = -40 }, down = { x = 0, y = 40 } }

for _, dir in ipairs({ "left", "right", "up", "down" }) do
	bind(mod .. " + " .. dir, hl.dsp.focus({ direction = dir }), { description = "Move focus" })
	bind(mod .. " + SHIFT + " .. dir, hl.dsp.window.move({ direction = dir }), { description = "Move window" })
	bind(
		mod .. " + CTRL + " .. dir,
		hl.dsp.window.resize({ x = resize_step[dir].x, y = resize_step[dir].y, relative = true }),
		{ repeating = true, description = "Resize window" }
	)
end
bind(mod .. " + U", hl.dsp.focus({ urgent_or_last = true }), { description = "Focus urgent or last" })

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
	bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }), { description = "Go to workspace" })
	bind(
		mod .. " + SHIFT + " .. key,
		hl.dsp.window.move({ workspace = i, follow = false }),
		{ description = "Send window to workspace" }
	)
	bind(
		mod .. " + ALT + " .. key,
		hl.dsp.window.move({ workspace = i, follow = true }),
		{ description = "Send window to workspace and follow" }
	)
end

-- Cycle through open workspaces.
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "Previous workspace" })
bind(mod .. " + bracketright", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
bind(mod .. " + bracketleft", hl.dsp.focus({ workspace = "e-1" }), { description = "Previous workspace" })

-- Scratchpad.
bind(mod .. " + S", hl.dsp.workspace.toggle_special("magic"), { description = "Toggle scratchpad" })
bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), { description = "Send to scratchpad" })

-- ── Monitors ─────────────────────────────────────────────────────────
bind(mod .. " + comma", hl.dsp.focus({ monitor = "-1" }), { description = "Focus previous monitor" })
bind(mod .. " + period", hl.dsp.focus({ monitor = "+1" }), { description = "Focus next monitor" })
bind(
	mod .. " + SHIFT + comma",
	hl.dsp.window.move({ monitor = "-1", follow = true }),
	{ description = "Move window to previous monitor" }
)
bind(
	mod .. " + SHIFT + period",
	hl.dsp.window.move({ monitor = "+1", follow = true }),
	{ description = "Move window to next monitor" }
)

-- ── Screenshots ──────────────────────────────────────────────────────

-- The shell's service names the file and tracks the last shot; plain grim only when the shell is down.
local function screenshot(action, mode)
	local grim = mode == "screen" and "grim " or 'g=$(slurp) && grim -g "$g" '
	local fallback = action == "copy" and grim .. "- | wl-copy"
		or 'd="$(xdg-user-dir PICTURES)/Screenshots" && mkdir -p "$d" && '
			.. grim
			.. '"$d/$(date +%Y-%m-%d_%H-%M-%S).png"'
	return hl.dsp.exec_cmd(("qs ipc call screenshot %s %s || { %s; }"):format(action, mode, fallback))
end

bind("Print", screenshot("capture", "region"), { description = "Screenshot region to file" })
bind("SHIFT + Print", screenshot("capture", "screen"), { description = "Screenshot to file" })
bind(mod .. " + Print", screenshot("copy", "region"), { description = "Screenshot region to clipboard" })
bind(mod .. " + SHIFT + Print", screenshot("copy", "screen"), { description = "Screenshot to clipboard" })
-- Window mode: click the window to capture.
bind("ALT + Print", screenshot("capture", "window"), { description = "Screenshot a window to file" })
bind(
	mod .. " + CTRL + Print",
	hl.dsp.exec_cmd("qs ipc call screenshot capture text"),
	{ description = "Copy the text in a region" }
)

-- ── Recording ───────────────────────────────────────────────────────

-- The same key stops it. The recorder is a unit of its own, so systemctl can stop it when the shell is down.
local function record(mode)
	return hl.dsp.exec_cmd(("qs ipc call recorder toggle %s || systemctl --user stop quickshell-recorder"):format(mode))
end

bind("CTRL + Print", record("region"), { description = "Record a region, or stop recording" })
bind("CTRL + SHIFT + Print", record("screen"), { description = "Record the screen, or stop recording" })

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
	bind(mod .. " + SHIFT + " .. key, hl.dsp.global("quickshell:" .. panel[1]), { description = panel[2] })
end

-- G is the system stats panel, so game mode sits on ALT.
bind(mod .. " + ALT + G", hl.dsp.global("quickshell:toggleGameMode"), { description = "Toggle game mode" })

-- Dismiss whatever is open.
bind(mod .. " + grave", hl.dsp.global("quickshell:panelClose"), { description = "Close any shell panel" })

-- ── System ───────────────────────────────────────────────────────────

bind(mod .. " + Escape", hl.dsp.exec_cmd(apps.lock), { description = "Lock screen" })
-- Every keyboard at once; the XKB toggle only switched the one it was pressed on.
bind(
	mod .. " + space",
	hl.dsp.exec_cmd("hyprctl switchxkblayout all next"),
	{ locked = true, description = "Switch keyboard layout" }
)
-- uwsm stop, not hl.dsp.exit(), so the session shuts down in order. Three modifiers and no palette entry, so it
-- isn't hit by accident.
hl.bind(mod .. " + CTRL + SHIFT + Escape", hl.dsp.exec_cmd("uwsm stop"), { description = "Log out" })

-- ── Brightness ───────────────────────────────────────────────────────
-- Linear (no -e4), to match the shell's slider (hypr/README.md).
bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("brightnessctl -n2 set 5%+"),
	{ locked = true, repeating = true, description = "Brightness up" }
)
bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("brightnessctl -n2 set 5%-"),
	{ locked = true, repeating = true, description = "Brightness down" }
)

-- ── Volume ───────────────────────────────────────────────────────────
bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true, description = "Volume up" }
)
bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true, description = "Volume down" }
)
bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, description = "Mute" }
)
bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, description = "Mute microphone" }
)

-- ── Media ────────────────────────────────────────────────────────────
bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play/pause" })
bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play/pause" })
bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, description = "Next track" })
bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, description = "Previous track" })
bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true, description = "Stop playback" })

bind(
	mod .. " + XF86AudioNext",
	hl.dsp.exec_cmd("playerctl position 5+"),
	{ locked = true, description = "Seek forward 5 s" }
)
bind(
	mod .. " + XF86AudioPrev",
	hl.dsp.exec_cmd("playerctl position 5-"),
	{ locked = true, description = "Seek back 5 s" }
)

-- ── Utility ──────────────────────────────────────────────────────────

bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"), { description = "Color picker" })

-- "10 call Ahmed", "90s tea" or "2h": a bare number is minutes. The timer is the user manager's, so it outlives
-- the shell but not the session. Left to itself systemd fires it up to a minute late, and takes a text that
-- starts with $ for a variable and drops it.
local remind = [=[set -f; set -- $(%s -d --prompt-only='Remind me in ' --placeholder='10 call Ahmed')
[ $# -gt 0 ] || exit 0
when=$1; shift; what=$*
case $when in *[!0-9]*) ;; *) when=${when}m ;; esac
if systemd-run --user --quiet --unit="reminder-$(date +%%s)" --on-active="$when" \
	--timer-property=AccuracySec=1s --expand-environment=no \
	notify-send -u critical -t 0 -a Reminder -- "${what:-Time is up}"; then
	notify-send -t 3000 -a Reminder -- "Reminder in $when" "$what"
else
	notify-send -a Reminder -- "No reminder set" 'Start with the time: "10 call Ahmed", "90s tea" or "2h".'
fi]=]

bind(mod .. " + R", hl.dsp.exec_cmd(remind:format(apps.menu)), { description = "Set a reminder" })

-- Every emoji that is one character in the emoji font, under Python's name for it. Flags and skin tones are
-- sequences, so they are not in the list.
local emoji = [=[sel=$(fc-match -f '%{charset}' 'Noto Color Emoji' | python3 -c '
import sys, unicodedata
rows = []
for part in sys.stdin.read().split():
	low, _, high = part.partition("-")
	for cp in range(int(low, 16), int(high or low, 16) + 1):
		name = unicodedata.name(chr(cp), "")
		# Not the letters flags are made of, the skin tones, the joiner, keycap and selector, or the tags.
		parts = 0x1F1E6 <= cp <= 0x1F1FF or 0x1F3FB <= cp <= 0x1F3FF or cp in (0x200D, 0x20E3, 0xFE0F) or cp >= 0xE0000
		if cp > 0xFF and name and not parts:
			rows.append((not 0x1F600 <= cp <= 0x1F64F, cp, name.lower()))
# Faces first. Below U+1F000 a selector follows, or the character is drawn as plain text.
for _, cp, name in sorted(rows):
	print(chr(cp) + ("\ufe0f" if cp < 0x1F000 else ""), name, sep="\t")
' | ]=] .. apps.menu .. [=[ -d --only-match --accept-nth=1 --placeholder='Emoji…')
[ -n "$sel" ] && printf %s "$sel" | wl-copy]=]

bind(mod .. " + semicolon", hl.dsp.exec_cmd(emoji), { description = "Emoji picker" })

-- Python as a calculator: sqrt(2), sin(pi / 4), and _ for the last answer. rules.lua floats the window.
bind(
	mod .. " + equal",
	hl.dsp.exec_cmd(apps.terminal .. [[ --class calculator -T Calculator -e python3 -q -i -c "from math import *"]]),
	{ description = "Calculator" }
)

-- Cycle the tiling layout.
local layouts = { "dwindle", "master", "scrolling" }

bind(mod .. " + L", function()
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

-- ── Command palette ──────────────────────────────────────────────────

local function keyless(description, call)
	palette[#palette + 1] = { description, "", hl.dsp.exec_cmd("qs ipc call " .. call) }
end

keyless("Check for updates", "updates check")
keyless("Clear notifications", "notifications clear")
keyless("Shuffle the wallpaper", "wallpaper shuffle")
-- The names in the shell's core/Themes.qml.
for _, name in ipairs({
	"catppuccin-latte",
	"catppuccin-macchiato",
	"catppuccin-mocha",
	"tokyo-night",
	"tokyo-night-storm",
}) do
	keyless("Theme: " .. name, "theme set " .. name)
end

-- Sorted, so the list keeps its order from one reload to the next; pairs() above does not.
table.sort(palette, function(a, b)
	return a[1] .. "\t" .. a[2] < b[1] .. "\t" .. b[2]
end)

local list = os.getenv("XDG_RUNTIME_DIR") .. "/hypr-palette"
local file = assert(io.open(list, "w"))
for _, entry in ipairs(palette) do
	file:write(entry[1], "\t", entry[2], "\n")
end
file:close()

-- The menu answers with the line's number, counted from 0, and run() below takes it.
local pick = [=[i=$(column -t -s "$(printf '\t')" %s | %s -d --index --only-match -w 66 --placeholder='Run a command…'); ]=]
	.. [=[[ -n "$i" ] && hyprctl eval "package.loaded['settings.keybinds'].run($i)"]=]

hl.bind(mod .. " + P", hl.dsp.exec_cmd(pick:format(list, apps.menu)), { description = "Command palette" })

return {
	run = function(index)
		hl.dispatch(palette[index + 1][3])
	end,
}
