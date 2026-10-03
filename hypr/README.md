# Hyprland

Hyprland 0.56 with its Lua config, started by uwsm. Quickshell draws the bar
and panels. hypridle, hyprlock, hyprpaper and hyprsunset run alongside it as
systemd user units.

## Files

| File | Holds |
|---|---|
| `hyprland.lua` | The entry point. It requires each module below; an error in one module aborts only that module. |
| `settings/theme.lua` | Shared values: colours, border size, default apps. |
| `settings/monitors.lua` | Outputs. `hyprctl monitors all` lists them. |
| `settings/look.lua` | Borders, gaps, decoration, and the dwindle, master and scrolling layouts. |
| `settings/behavior.lua` | misc, cursor, render, XWayland and bind options. |
| `settings/animations.lua` | Curves and animations. |
| `settings/input.lua` | Keyboard, mouse, touchpad and gestures. |
| `settings/rules.lua` | Window, layer and workspace rules. |
| `settings/keybinds.lua` | Every keybind, each with a description. |
| `settings/autostart.lua` | The few programs that start with the compositor. |
| `hypridle.conf` | Dim after 5 minutes, lock after 20, screen off after 30. |
| `hyprlock.conf` | The lock screen. |
| `hyprpaper.conf` | Wallpaper rotation. |
| `.luarc.json` | Points lua-language-server at Hyprland's API stubs. |
| `../systemd/user/hyprsunset.service` | See [Services](#services). |

## Day to day

- Saving a file reloads Hyprland. `hyprctl reload` forces a reload, and
  `hyprctl configerrors` should print nothing.
- SUPER+F1 lists every keybind.
- `./setup.sh lint`, run from the repo root, checks these files with stylua.
- The Lua API is in `/usr/share/hypr/stubs/hl.meta.lua`, which
  lua-language-server reads through `.luarc.json`, and on the
  [wiki](https://wiki.hypr.land/Configuring/Start/).
- Logs: `journalctl --user -u wayland-wm@hyprland.desktop` for the compositor,
  and `journalctl --user -u hypridle -u hyprpaper -u hyprsunset` for the
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
`autostart.lua`: hypridle, hyprpaper, hyprsunset, quickshell and
wayland-pipewire-idle-inhibit. `systemctl --user status hypridle hyprpaper
hyprsunset quickshell` shows them, and `systemctl --user restart quickshell`
restarts the shell together with its child processes.

hyprsunset runs from this package's unit instead of the packaged one, only to
start it with `--identity`. Without that flag the daemon starts at 6000 K and
tints the screen from login.
[`services/NightLight.qml`](../quickshell/.config/quickshell/services/NightLight.qml)
in the shell decides when the filter applies and how warm it is, so a session
without the shell stays neutral. The unit is a replacement rather than a
drop-in because a drop-in directory would be a stow symlink, and systemd
doesn't follow those.

`autostart.lua` starts the polkit agent, the Thunar daemon and the clipboard
watchers. Long-lived apps go through `uwsm app --`, so each runs in its own
systemd scope and the OOM killer can pick the app instead of the session.
fuzzel does the same through its `launch-prefix`, and so does the terminal
keybind, with the faster `uwsm-app` client.

SUPER+SHIFT+Escape logs out with `uwsm stop`. `hl.dsp.exit()` would pull the
compositor out from under its clients and skip the orderly shutdown.

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

The media keys call playerctl rather than the shell, so they keep working while
the shell restarts. Brightness steps are linear because
[`services/Brightness.qml`](../quickshell/.config/quickshell/services/Brightness.qml)
writes and reads a linear percentage; an exponential curve here would move the
shell's slider by uneven amounts.

A browser's picture-in-picture window floats in the bottom-right corner at
640x360, stays on every workspace and isn't dimmed. SUPER+X does the same to
any window, and a second press puts it back where it was.

| Keys | Action |
|---|---|
| `Print` | Screenshot region to file |
| `SHIFT + Print` | Screenshot to file |
| `SUPER + 1-0` | Go to workspace |
| `SUPER + ALT + 1-0` | Send window to workspace and follow |
| `SUPER + B` | Browser |
| `SUPER + C` | Center window |
| `SUPER + D` | App launcher |
| `SUPER + E` | File manager |
| `SUPER + Escape` | Lock screen |
| `SUPER + F1` | Keybind cheat sheet |
| `SUPER + F` | Fullscreen |
| `SUPER + J` | Toggle split (dwindle) |
| `SUPER + L` | Cycle layout |
| `SUPER + Print` | Screenshot region to clipboard |
| `SUPER + Q` | Close window |
| `SUPER + Return` | Terminal |
| `SUPER + SHIFT + 1-0` | Send window to workspace |
| `SUPER + SHIFT + A` | Audio panel |
| `SUPER + SHIFT + B` | Bluetooth panel |
| `SUPER + SHIFT + C` | Color picker |
| `SUPER + SHIFT + D` | Toggle do not disturb |
| `SUPER + SHIFT + E` | Settings panel |
| `SUPER + SHIFT + Escape` | Log out |
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
| `SUPER + SHIFT + S` | Send to scratchpad |
| `SUPER + SHIFT + W` | Network panel |
| `SUPER + SHIFT + X` | Screenshot panel |
| `SUPER + SHIFT + Y` | Wallpaper panel |
| `SUPER + SHIFT + arrows` | Move window |
| `SUPER + SHIFT + comma` | Move window to previous monitor |
| `SUPER + SHIFT + period` | Move window to next monitor |
| `SUPER + S` | Toggle scratchpad |
| `SUPER + T` | Toggle floating |
| `SUPER + U` | Focus urgent or last |
| `SUPER + V` | Clipboard history |
| `SUPER + XF86AudioNext` | Seek forward 5 s |
| `SUPER + XF86AudioPrev` | Seek back 5 s |
| `SUPER + X` | Picture-in-picture |
| `SUPER + arrows` | Move focus |
| `SUPER + bracketleft` | Previous workspace |
| `SUPER + bracketright` | Next workspace |
| `SUPER + comma` | Focus previous monitor |
| `SUPER + grave` | Close any shell panel |
| `SUPER + mouse:272` | Drag window |
| `SUPER + mouse:273` | Resize window |
| `SUPER + mouse_down` | Next workspace |
| `SUPER + mouse_up` | Previous workspace |
| `SUPER + period` | Focus next monitor |
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
broken file leaves the defaults in place.

## Wallpapers

hyprpaper rotates through `~/Pictures/Wallpapers` every hour. Keep the images
at 3840x2160 or smaller: hyprpaper uploads each one as a GPU texture at its full
size, whatever the screen resolution or `fit_mode`, and 0.8.4 has no setting to
limit that ([hyprwm/hyprpaper#345](https://github.com/hyprwm/hyprpaper/issues/345)).

Its IPC has two commands, `listactive` and `wallpaper <monitor>,<path>`, and
three traps:

- A comma in a file name breaks the path.
- `hyprctl` exits 0 even when hyprpaper refuses, so check the result with
  `hyprctl hyprpaper listactive`.
- Setting a wallpaper over IPC stops that monitor's rotation until hyprpaper
  restarts.

## Games

`settings/rules.lua` recognises games by window class: `steam_app_<id>` for
Proton, and `gamescope` for anything running inside it. Native games need
their class added, and the list has to match `_gameClass` in
[`services/GameMode.qml`](../quickshell/.config/quickshell/services/GameMode.qml).

- **Idle:** games, mpv, Chromium and Loupe keep the screen awake while
  fullscreen. Apps that use the idle-inhibit protocol, like Chromium during
  playback, are honoured anyway; the rule covers the ones that don't.
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
