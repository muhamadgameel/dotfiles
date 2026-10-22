# Hyprland

Hyprland 0.56 with its Lua config, started by uwsm. Quickshell draws the bar
and panels. hypridle, hyprlock, hyprsunset and awww run alongside it as
systemd user units.

## Files

| File | Holds |
|---|---|
| `hyprland.lua` | The entry point. It requires each module below; an error in one module aborts only that module. |
| `settings/theme.lua` | Shared values: colours, border size, default apps. |
| `settings/monitors.lua` | Outputs. `hyprctl monitors all` lists them. |
| `settings/look.lua` | Borders, gaps, decoration, the groupbar, and the dwindle and master layouts. |
| `settings/behavior.lua` | misc, cursor, render, XWayland and bind options. |
| `settings/animations.lua` | Curves and animations. |
| `settings/input.lua` | Keyboard, mouse, touchpad and gestures. |
| `settings/rules.lua` | Window, layer and workspace rules. |
| `settings/keybinds.lua` | Every keybind, each with a description. |
| `settings/autostart.lua` | The Thunar daemon, the only program started with the compositor. |
| `hypridle.conf` | Dim after 5 minutes, lock after 10, screen off a minute into any lock. |
| `hyprlock.conf` | The lock screen. |
| `.luarc.json` | Points lua-language-server at Hyprland's API stubs. |
| `../systemd/user/hyprsunset.service`, `awww-daemon.service`, `cliphist@.service` | See [Services](#services). |

## Day to day

- Saving a file reloads Hyprland. `hyprctl reload` forces a reload, and
  `hyprctl configerrors` should print nothing.
- SUPER+P is the command palette: every keybind, searchable, and Enter runs
  the one you pick.
- `./setup.sh lint`, run from the repo root, checks these files with stylua.
- The Lua API is in `/usr/share/hypr/stubs/hl.meta.lua`, which
  lua-language-server reads through `.luarc.json`, and on the
  [wiki](https://wiki.hypr.land/Configuring/Start/).
- Logs: `journalctl --user -u wayland-wm@hyprland.desktop` for the compositor,
  and `journalctl --user -u hypridle -u awww-daemon -u hyprsunset` for the
  daemons.

## Environment

Every session variable lives in
[`~/.config/uwsm/env`](../uwsm/.config/uwsm/env): PATH, the default apps, the
cursor and the toolkit settings. uwsm sources it before the compositor starts,
so the variables reach the systemd and D-Bus activation environment, where
apps started by a portal or by D-Bus see them. `hl.env()` would only reach
processes Hyprland starts itself, so the config doesn't use it.

## Services

These systemd user units start with the graphical session, not from
`autostart.lua`: awww-daemon, hypridle, hyprpolkitagent, hyprsunset, quickshell,
wayland-pipewire-idle-inhibit and the clipboard watchers `cliphist@text` and
`cliphist@image`. systemd restarts any of them that crashes.
`systemctl --user status awww-daemon hypridle hyprsunset quickshell` shows them,
and `systemctl --user restart quickshell` restarts the shell together with its
child processes.

hyprsunset runs from this package's unit instead of the packaged one, only to
start it with `--identity`. Without that flag the daemon starts at 6000 K and
tints the screen from login.
[`services/NightLight.qml`](../quickshell/.config/quickshell/services/NightLight.qml)
in the shell decides when the filter applies and how warm it is, so a session
without the shell stays neutral. The unit is a replacement rather than a
drop-in because a drop-in directory would be a stow symlink, and systemd
doesn't follow those.

awww-daemon runs from this package's unit too, because awww ships none.

The clipboard watchers come from this package's `cliphist@.service`, one
instance per type, and SUPER+V reads what they store. The packaged
`cliphist.service` runs a single untyped watcher instead. When a copy offers
both text and an image, as a browser's "Copy image" does, that watcher keeps
only the text.

Bitwarden doesn't mark a copied password as secret, so the history keeps it
like any other copy, even after Bitwarden clears the clipboard. After pasting
one, "Forget the last clipboard entry" in the palette deletes the newest entry
and empties the clipboard.

`autostart.lua` starts only the Thunar daemon, which is what mounts drives as
they're plugged in. Thunar's own unit can't be enabled, only started over
D-Bus. The daemon goes through `uwsm app --`, so it runs in its own systemd
scope and the OOM killer can pick the app instead of the session. fuzzel does
the same through its `launch-prefix`, and so does the terminal keybind, with
the faster `uwsm-app` client.

SUPER+Escape locks through logind (`loginctl lock-session`). hypridle answers
the lock request by starting hyprlock, the same way it does after 10 idle
minutes and before sleep, so hyprlock is only ever started from one place.
Just before, it closes the shell's open panel, which would keep sampling behind
the lock, and puts every keyboard on the first layout, so the password is typed
in English. The panel goes with no slide: a lock stops the shell being drawn, so
a slide in flight would freeze part-way and finish after unlocking.

Playing audio holds the dim and the idle lock off
(wayland-pipewire-idle-inhibit), and so do the shell's Stay Awake toggle and
the fullscreen rules under [Games](#games). A locked screen ignores all of
them: it turns off after a minute without input, and a key or the mouse
brings it back. If the screen never dims, look for a stream still marked
`[active]` in `wpctl status`, or for Stay Awake in `systemd-inhibit --list`.

SUPER+CTRL+SHIFT+Escape logs out with `uwsm stop`. `hl.dsp.exit()` would pull
the compositor out from under its clients and skip the orderly shutdown.

## Keybinds

SUPER+SHIFT+letter opens a shell panel or flips a toggle. These are global
shortcuts the shell registers
([`modules/ipc/Shortcuts.qml`](../quickshell/.config/quickshell/modules/ipc/Shortcuts.qml)):
`hl.dsp.global` reaches the running shell without starting a process, and the
shell answers from its own state, so the same key closes the panel again. When
the shell isn't running the shortcuts aren't registered and the keys do
nothing; `hyprctl globalshortcuts` lists what is registered.

SUPER+grave closes whatever panel is open, and so does a click anywhere outside
it. That left-click bind is non-consuming, so the click still reaches whatever
it was aimed at.

SUPER+Return opens a terminal in the focused terminal's directory, or in your
home directory from any other window.

SUPER+S shows the scratchpad. When it is empty, a terminal drops down over the
top of the screen; other windows there tile as on any workspace, and switching
workspace hides the scratchpad again.

SUPER+P opens the command palette, a fuzzel list of every bind made with the
local `bind()` in `settings/keybinds.lua`, and of a few actions that have no
key: the update check, clearing the notifications, a wallpaper shuffle, each
theme, and restarting the shell or the audio. The list is written to
`$XDG_RUNTIME_DIR/hypr-palette` when the config loads, and the pick runs
through `hyprctl eval`, in the config's own Lua state, so it does exactly what
the key does. A bind made with `hl.bind` stays off the list: the mouse binds,
and Log out, which one Enter should not reach. Restart and shut down stay
behind the Power panel, which the power button opens too: logind only acts on a
five-second hold.

SUPER+R asks for a reminder: a time, then the text, as in `10 call Ahmed`. A
bare number is minutes; `90s`, `2h` and `1h30m` work too, and the text may be
left out. It becomes a systemd user timer that raises a critical notification,
which stays until you dismiss it and gets through do not disturb.
`systemctl --user list-timers 'reminder-*'` lists the pending ones, and
`systemctl --user stop` with a timer's name drops it. They outlive a shell
restart, not a logout.

SUPER+semicolon lists the emoji; type part of a name and Enter copies the
one picked. The list is every emoji that is a single character in the emoji
font, under the name Python's Unicode table has for it, so the red heart is
"heavy black heart", and flags and skin tones, which are sequences, are not
in it.

SUPER+equal opens a calculator: a small floating terminal running Python with
the names of its `math` module loaded, so `sqrt(2)`, `sin(pi / 4)` and `2**10`
work, and `_` is the last answer. Ctrl+D closes it.

SUPER+SHIFT+Return opens a terminal on the tmux session used last, and starts
one when there is none; SUPER+Return stays a plain terminal. A session
outlives its window, but not the desktop session: the tmux server runs in the
scope of the terminal that started it, and those end with Hyprland.

SUPER+SHIFT+V starts dictation and the same key stops it. voxtype turns the
speech into text on this machine, with Whisper's English base model, and wtype
types it into the window that has focus; a recording stops by itself after a
minute. Keys that wtype types never reach Hyprland's binds, measured with a
modifier held on another keyboard, so voxtype's own submap workaround for
held modifiers is not needed here.

The media keys call playerctl rather than the shell, so they keep working while
the shell restarts. The Print keys go through the shell's screenshot service,
which names the file and tracks the last shot, and fall back to plain grim when
the shell isn't running. CTRL+Print records a region and CTRL+SHIFT+Print the
screen, with the desktop's sound, into `~/Pictures/Recordings`; the same key
stops it, also while the shell is down, because the recorder runs in a unit of
its own. It captures below the compositor, so the `no_screen_share` rules do
not apply: Bitwarden and the password prompts are recorded like any other
window, though a screen share shows them black. SUPER+CTRL+Print
reads the text in a region you drag, in English and Arabic, and puts it on the
clipboard; tesseract does the reading, and the key does nothing while the
shell is down. Brightness steps are linear because
[`services/Brightness.qml`](../quickshell/.config/quickshell/services/Brightness.qml)
writes and reads a linear percentage; an exponential curve here would move the
shell's slider by uneven amounts.

A browser's picture-in-picture window floats in the bottom-right corner at
640x360, stays on every workspace and isn't dimmed. SUPER+X does the same to
any window, and a second press puts it back where it was.

SUPER+G turns the focused window into a group, one tile that holds windows as
tabs, and a second press splits the group up again. While a group has focus, a
window you open joins it as a new tab, unless it floats: dialogs and the
calculator open on their own. SUPER+Tab and SUPER+SHIFT+Tab step through the
tabs, and SUPER+ALT+Tab and SUPER+ALT+SHIFT+Tab move the focused tab one place
right or left; at the end of the bar it swaps with the tab at the other end.
SUPER+ALT+arrows moves a window into the group on that side, or out of its own
group that way. With the mouse, a window dragged onto a group joins
it, a tab dragged off the bar leaves it, the wheel over the bar switches tabs,
and a middle click closes one.

On the touchpad, a three-finger horizontal swipe switches workspace, a
three-finger swipe up shows or hides the scratchpad, and SUPER + two-finger
pinch toggles a 3x zoom at the cursor. Hyprland acts on a
gesture without taking it from the app under the pointer, so the zoom needs
SUPER: a plain pinch is the app's own zoom. With SUPER held, a browser page
under the pointer still zooms along.

| Keys | Action |
|---|---|
| `ALT + Print` | Screenshot a window to file |
| `CTRL + Print` | Record a region, or stop recording |
| `CTRL + SHIFT + Print` | Record the screen, or stop recording |
| `Print` | Screenshot region to file |
| `SHIFT + Print` | Screenshot to file |
| `SUPER + 1-0` | Go to workspace |
| `SUPER + ALT + 1-0` | Send window to workspace and follow |
| `SUPER + ALT + G` | Toggle game mode |
| `SUPER + ALT + SHIFT + Tab` | Move tab back in group |
| `SUPER + ALT + Tab` | Move tab forward in group |
| `SUPER + ALT + arrows` | Move window into or out of group |
| `SUPER + B` | Browser |
| `SUPER + CTRL + ALT + Z` | Reset zoom |
| `SUPER + CTRL + Print` | Copy the text in a region |
| `SUPER + CTRL + SHIFT + Escape` | Log out |
| `SUPER + CTRL + Z` | Zoom in |
| `SUPER + CTRL + arrows` | Resize window |
| `SUPER + C` | Center window |
| `SUPER + D` | App launcher |
| `SUPER + E` | File manager |
| `SUPER + Escape` | Lock screen |
| `SUPER + F` | Fullscreen |
| `SUPER + G` | Toggle group |
| `SUPER + J` | Toggle split (dwindle) |
| `SUPER + L` | Cycle layout |
| `SUPER + P` | Command palette |
| `SUPER + Print` | Screenshot region to clipboard |
| `SUPER + Q` | Close window |
| `SUPER + R` | Set a reminder |
| `SUPER + Return` | Terminal |
| `SUPER + SHIFT + 1-0` | Send window to workspace |
| `SUPER + SHIFT + A` | Audio panel |
| `SUPER + SHIFT + B` | Bluetooth panel |
| `SUPER + SHIFT + C` | Color picker |
| `SUPER + SHIFT + D` | Toggle do not disturb |
| `SUPER + SHIFT + E` | Settings panel |
| `SUPER + SHIFT + F` | Maximize |
| `SUPER + SHIFT + G` | System stats panel |
| `SUPER + SHIFT + I` | Toggle stay awake |
| `SUPER + SHIFT + K` | Calendar panel |
| `SUPER + SHIFT + L` | Toggle night light |
| `SUPER + SHIFT + M` | Media panel |
| `SUPER + SHIFT + N` | Notifications panel |
| `SUPER + SHIFT + P` | Power panel |
| `SUPER + SHIFT + Print` | Screenshot to clipboard |
| `SUPER + SHIFT + Q` | Quick settings panel |
| `SUPER + SHIFT + Return` | Terminal on the last tmux session |
| `SUPER + SHIFT + S` | Send to scratchpad |
| `SUPER + SHIFT + Tab` | Previous window in group |
| `SUPER + SHIFT + V` | Dictation on and off |
| `SUPER + SHIFT + W` | Network panel |
| `SUPER + SHIFT + X` | Screenshot panel |
| `SUPER + SHIFT + Y` | Wallpaper panel |
| `SUPER + SHIFT + arrows` | Move window |
| `SUPER + SHIFT + comma` | Move window to previous monitor |
| `SUPER + SHIFT + period` | Move window to next monitor |
| `SUPER + S` | Toggle scratchpad |
| `SUPER + T` | Toggle floating |
| `SUPER + Tab` | Next window in group |
| `SUPER + U` | Focus urgent or last |
| `SUPER + V` | Clipboard history |
| `SUPER + XF86AudioNext` | Seek forward 5 s |
| `SUPER + XF86AudioPrev` | Seek back 5 s |
| `SUPER + X` | Picture-in-picture |
| `SUPER + arrows` | Move focus |
| `SUPER + bracketleft` | Previous workspace |
| `SUPER + bracketright` | Next workspace |
| `SUPER + comma` | Focus previous monitor |
| `SUPER + equal` | Calculator |
| `SUPER + grave` | Close any shell panel |
| `SUPER + mouse:272` | Drag window |
| `SUPER + mouse:273` | Resize window |
| `SUPER + mouse_down` | Next workspace |
| `SUPER + mouse_up` | Previous workspace |
| `SUPER + period` | Focus next monitor |
| `SUPER + semicolon` | Emoji picker |
| `SUPER + space` | Switch keyboard layout |
| `XF86AudioLowerVolume` | Volume down |
| `XF86AudioMicMute` | Mute microphone |
| `XF86AudioMute` | Mute |
| `XF86AudioNext` | Next track |
| `XF86AudioPause` | Play/pause |
| `XF86AudioPlay` | Play/pause |
| `XF86AudioPrev` | Previous track |
| `XF86AudioRaiseVolume` | Volume up |
| `XF86AudioStop` | Stop playback |
| `XF86MonBrightnessDown` | Brightness down |
| `XF86MonBrightnessUp` | Brightness up |
| `XF86PowerOff` | Power panel |
| `mouse:272` | Dismiss an open shell panel |

Regenerate the table after changing binds:

```bash
hyprctl binds -j | jq -r '
  def m($bit; $name): if (.modmask / $bit | floor) % 2 == 1 then $name else empty end;
  [.[] | select(.has_description)
    | .key |= (if test("^[0-9]$") then "1-0" elif test("^(left|right|up|down)$") then "arrows" else . end)
    | "| `\([m(64; "SUPER"), m(4; "CTRL"), m(8; "ALT"), m(1; "SHIFT"), .key] | join(" + "))` | \(.description) |"]
  | unique[]'
```

## Theme colours

Tokyo Night is the default in `settings/theme.lua` and `hyprlock.conf`. When
you switch theme in the shell,
[`services/ThemeSync.qml`](../quickshell/.config/quickshell/services/ThemeSync.qml)
writes the active colours to `~/.local/state/quickshell/hyprland-colors.lua` and
`hyprlock-colors.conf`, which override the defaults key by key. A missing or
broken file leaves the defaults in place. The running compositor changes at
once: ThemeSync hands the same colours to `paint()` in `settings/look.lua`,
which sets the borders and the groupbar together.

## Wallpapers

awww draws the wallpaper and the shell chooses it from `~/Pictures/Wallpapers`:
a new one every hour, until you pick one in the Wallpaper panel. "Resume
cycling" keeps that one and starts the hourly changes again from it. Each
change uses the transition set under Appearance in the Settings panel, a
one-second fade by default, and at login awww shows the last image again
before the shell is up.

`awww query` says what is on the screen. `qs ipc call wallpaper set <path>`
pins one, and `qs ipc call wallpaper shuffle` does what "Resume cycling" does.

## Games

`settings/rules.lua` recognises games by window class: `steam_app_<id>` for
Proton, and `gamescope` for anything running inside it. Native games need
their class added, and the list has to match `_gameClass` in
[`services/GameMode.qml`](../quickshell/.config/quickshell/services/GameMode.qml).

- **Idle:** games, mpv, Chromium, its web apps and Loupe keep the screen awake
  while fullscreen. mpv and Chromium only ask for that themselves while a
  video is playing, so the rule is what keeps a paused one from dimming and
  locking.
- **Tearing:** `general.allow_tearing` is only a master switch. Games also get
  the `immediate` rule, so a fullscreen game shows each frame as soon as it's
  ready instead of waiting for vsync: lower input latency, possible tear lines.
  Delete that loop to go back to vsync.

## GPU

The laptop's MUX is set to discrete only: the RTX 4080 drives the panel and the
Intel iGPU is off (`lspci` lists only the NVIDIA card). With a single GPU,
Hyprland needs no multi-GPU or NVIDIA variables, and VA-API finds the NVIDIA
driver by itself.

Hybrid mode drives the panel from the iGPU and saves battery. It hasn't been
tried on this machine; the steps would be:

1. Switch the GPU mode to hybrid in the firmware setup (or Lenovo Vantage on
   Windows), and reboot.
2. Find the iGPU with `ls -l /dev/dri/by-path`; it is usually
   `pci-0000:00:02.0`. Aquamarine reads a colon-separated list of cards from
   `AQ_DRM_DEVICES`, and by-path names contain colons, so give both cards plain
   names with a udev rule in `/etc/udev/rules.d/99-gpu.rules`:

   ```
   KERNEL=="card*", KERNELS=="0000:00:02.0", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/igpu"
   KERNEL=="card*", KERNELS=="0000:01:00.0", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/dgpu"
   ```

   Then add `export AQ_DRM_DEVICES=/dev/dri/igpu:/dev/dri/dgpu` to
   `~/.config/uwsm/env`. The first card in the list renders.
3. Install `nvidia-prime`, and run games on the NVIDIA GPU with
   `prime-run %command%` as their Steam launch option.
4. Install `intel-media-driver` for hardware video decoding on the iGPU.
