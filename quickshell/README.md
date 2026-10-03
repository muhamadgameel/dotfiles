# Quickshell

The desktop shell: the bar, the sliding panels, the OSD, notifications and the
tooltip, written in QML for Quickshell 0.3.1. It runs as a systemd user unit.
Hyprland reaches it through global shortcuts, and scripts through `qs ipc`.

## Layout

| Path | Holds |
|---|---|
| `shell.qml` | The entry point: the bar (one window per screen, which owns the panels), the OSD, the notification popups, the shared tooltip, and the IPC and shortcut surfaces. |
| `config/` | `Config.qml` declares every setting with its default inline; `Settings.qml` is the JSON file behind it. |
| `core/` | Singletons that don't touch the system: the active theme and its palettes, design tokens (`Style`), icons, logging and helpers. |
| `services/` | One singleton per system concern: audio, network, Bluetooth, brightness, display, media, notifications, night light, wallpaper, theme sync, game mode, idle, power, screenshots and system stats. |
| `components/` | Reusable controls: buttons, toggles, sliders, cards and the sliding panel frame. |
| `modules/bar/` | `BarWindow` and the bar widgets. |
| `modules/panels/` | The 12 sliding panels. |
| `modules/popups/` | The OSD, the notification popups and the tooltip window. |
| `modules/ipc/` | The `qs ipc` targets and the Hyprland global shortcuts. |
| `qs-fmt` | Formatting, parse checks and lint; see [qs-fmt](#qs-fmt). |
| `../systemd/user/quickshell.service` | The unit; see [Running it](#running-it). |

The network service has two backends, nmcli and Quickshell.Networking
("native"). `qs ipc call network backend nmcli` switches between them.

## Running it

- `systemctl --user restart quickshell` restarts the shell. Don't use
  `pkill qs`: Quickshell doesn't stop its child processes on SIGTERM, but the
  unit's cgroup does. Before the unit existed, pkill restarts left orphaned
  `nmcli monitor` processes and a `systemd-inhibit` that blocked sleep.
- The unit runs in `session.slice` with the compositor, the slice systemd
  keeps for the session's own parts. Apps live in `app.slice`, so a limit or
  an OOM policy set there never lands on the shell.
- The unit restarts the shell if it exits with an error. Quickshell 0.3.1's
  networking module has a use-after-free (upstream issue #1021) that can crash
  it. Most crashes restart in place instead: Quickshell re-runs
  itself and shows a "Quickshell has crashed" dialog, and systemd never notices.
- Logs: `journalctl --user -u quickshell -f`, or `qs log -f` for the running
  instance's own log. Set `"debugMode": true` in `settings.json` for debug
  lines; it applies without a restart.

## Editing and hot reload

Quickshell reloads the config when a QML file changes. Three things to know:

- **A failed reload keeps the old config running**, with nothing visible on
  screen. After an edit, check `journalctl --user -u quickshell -n 50` for a
  fresh `Configuration Loaded`, or `Failed to load configuration` with the
  cause underneath.
- **A replaced file can be missed.** Editors and git write a new file and
  rename it over the old one, and Quickshell sometimes loses track of it. If no
  reload shows up, create and delete a file in the same directory:
  `touch dir/.qs-probe && rm dir/.qs-probe`. Touching the edited file itself
  does nothing, because Quickshell compares contents, not timestamps.
- **After many edits at once, restart** with
  `systemctl --user restart quickshell` rather than trusting each reload.

nvim uses qmlls6 for QML, and Code - OSS uses the Qt extension pointed at Qt 6
(see the `editors` package).

## qs-fmt

`./qs-fmt` formats, parse-checks and lints the QML. It takes qmlformat, qmldom
and qmllint from Qt 6's bin directory (`/usr/lib/qt6/bin`), which isn't on
PATH.

```bash
./qs-fmt              # check formatting, parse errors and lint warnings
./qs-fmt -w           # rewrite files in place
./qs-fmt --diff       # check, and print the formatting changes
./qs-fmt --strict     # also fail on lint warnings; ./setup.sh lint runs this
./qs-fmt components   # limit the run to a directory or a file
```

qmllint reports gaps in Quickshell's own type descriptions as warnings
(`PanelWindow` margins, `onExited` parameter types and a few more); qs-fmt
filters those out. It exits 0 when clean, 1 when something needs fixing and 2
when the Qt 6 tools are missing.

## Settings and state

`~/.local/state/quickshell/` holds:

- `settings.json`: every setting changed from its default, such as the theme,
  the wallpaper, night light and which bar widgets show. The shell watches the
  file, so a hand edit applies at once; delete a key to fall back to the
  default in `config/Config.qml`.
- `hyprland-colors.lua` and `hyprlock-colors.conf`: the active theme's colours,
  written by `services/ThemeSync.qml` for Hyprland and hyprlock (see
  [hypr/README.md](../hypr/README.md#theme-colours)).

## Controlling it

`qs ipc show` lists every target and function. A few examples:

```bash
qs ipc call panel toggle audio          # audio, network, bluetooth, systemstats, notifications,
                                        # media, calendar, power, screenshot, quicksettings,
                                        # wallpaper, settings
qs ipc call theme set tokyo-night       # catppuccin-mocha, catppuccin-macchiato,
                                        # catppuccin-latte, tokyo-night, tokyo-night-storm
qs ipc call screenshot capture region   # region, window, output or screen;
                                        # `copy` puts it on the clipboard instead
qs ipc call nightlight toggle
qs ipc call wallpaper shuffle
qs ipc call notifications toggleDnd
```

Hyprland's SUPER+SHIFT keys go through global shortcuts instead
(`modules/ipc/Shortcuts.qml`; see [hypr/README.md](../hypr/README.md#keybinds)).
`hyprctl globalshortcuts` lists the 19 the shell registers.
