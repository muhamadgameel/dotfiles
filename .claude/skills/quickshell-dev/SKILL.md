---
name: quickshell-dev
description: How to change the Quickshell desktop shell in this repo (quickshell/) without breaking the live desktop - where a new service, bar widget, panel, setting, shortcut or IPC function goes, formatting and lint with qs-fmt, trying a change in a throwaway offscreen instance and rendering it to a PNG, and confirming that the live shell really reloaded. Use it for any edit to a QML file under quickshell/, when a change "does not show up", before describing how something will look, and before restarting the shell.
---

# Changing the Quickshell shell

`~/.config/quickshell` is a symlink into `quickshell/.config/quickshell/`, so saving a
QML file changes the running bar at once. The owner reviews each step by clicking, so
keep a step to one or two files and try it somewhere else first.

Paths below are under `quickshell/.config/quickshell/` unless they start with `.claude/`.

## Where a new thing goes

| Adding | Touch |
|---|---|
| A system concern (state, a program to run) | One singleton `services/<Name>.qml` and a line in `services/qmldir`. Services import `core/` and `config/`, never `components/` or `modules/`. Run programs through `core/Command.qml` (`onDone: (code, out, err) =>`). |
| A bar widget | `modules/bar/widgets/<Name>.qml`, a line in its `qmldir`, its place in `modules/bar/Bar.qml`. A show/hide flag `barShow<Name>` in `config/Config.qml`, its key in `barKeys` in `modules/panels/SettingsPanel.qml`, and in `barNotes` there if the widget also hides itself. |
| A panel | `modules/panels/<Name>Panel.qml` on `components/SlidingPanel`, a line in that `qmldir`, its id in `ids` in `services/Panels.qml`, a `LazyLoader` in `modules/bar/BarWindow.qml`. |
| A way into a panel that has no bar widget | A `PanelButton` in the first row of `modules/panels/QuickSettingsPanel.qml`, beside Settings, Wallpaper, Screenshot and Power, and a `panel<Name>` shortcut. The bar keeps one button for Quick Settings. |
| A setting | `config/Config.qml`: `readonly property … : Settings.get("key", default)` with the default inline, and a setter if something writes it. `~/.local/state/quickshell/settings.json` holds only the values that differ from their default, so a changed default reaches everyone who never changed that setting. |
| A key | A name in the `shortcuts` table of `modules/ipc/Shortcuts.qml`. The bind is in Hyprland (`hl.dsp.global("quickshell:<name>")`; see the hyprland-lua skill). |
| A `qs ipc` function | `modules/ipc/Ipc.qml`. Return a string that says what happened. `qs ipc show` lists them. |

Then the docs: the IPC examples and the shortcut count in `quickshell/README.md`, and
the keybind table in `hypr/README.md`.

## Try it away from the live shell first

`.claude/skills/quickshell-dev/scripts/qsrig` runs a second instance on a copy of the
config, offscreen: no bar, no panels, nothing on the screen, its own state directory.

```bash
qsrig new   <scratch>/rig                               # the copy, a probe shell.qml, an empty Scene.qml
qsrig start <scratch>/rig
qsrig call  <scratch>/rig js 'Services.Time.timeShort'  # any one expression
qsrig call  <scratch>/rig grab <scratch>/out.png        # Scene.qml at three times its size
qsrig stop  <scratch>/rig
```

- Edit files in `<rig>/cfg/`; the instance reloads when a loaded file's content
  changes. Put what you want to look at in `cfg/Scene.qml` (real components, real
  fonts) and Read the PNG. `grab` answers before the PNG is written, so wait a second
  before `stop`. Describe a visible effect only after rendering it; otherwise say
  "not measured".
- To compare, build two rigs, today's code and the candidate, and make the same calls
  on both.
- A service starts on first use, and its first answer is often empty: call once, wait
  two seconds, call again.
- Replace a service that acts on the session before anything in the rig reads it:
  `Notification` claims the session's notification name, `Wallpaper` stops hyprpaper's
  rotation, others call `hyprctl`, `brightnessctl` or `systemctl`. A stand-in is a
  singleton with the same properties and functions that only records its calls.
  Never click a real bar widget against its real service: a left click on Brightness
  sets 50%, a middle click on Network turns Wi-Fi off.
- A stand-in proves only what its author assumed about the real object. When a result
  rests on what a real property returns, make the calls once on a real object too.
  `dbus-run-session -- bash <script>` gives the rig and throwaway programs a private
  session bus that the live shell never sees. Inside it, start the rig, then for
  media players, silent and windowless:
  `mpv --no-config --script=/etc/mpv/scripts/mpris.so --idle=yes --no-video --ao=null --force-window=no --force-media-title=P1 av://lavfi:sine=d=900 &`
- A real screen share, with no picker on the screen and no frame copied: inside
  `dbus-run-session`, start a second `/usr/lib/xdg-desktop-portal-hyprland` with a
  stand-in `hyprland-share-picker` first on PATH that prints
  `[SELECTION]/screen:<monitor>`, then ask it for a stream:

  ```bash
  o=/org/freedesktop/portal/desktop
  call() { busctl --user call org.freedesktop.impl.portal.desktop.hyprland $o org.freedesktop.impl.portal.ScreenCast "$@"; }
  call CreateSession 'oosa{sv}' $o/request/t/r1 $o/session/t/s1 t 0
  call SelectSources 'oosa{sv}' $o/request/t/r2 $o/session/t/s1 t 2 types u 1 multiple b false
  call Start 'oossa{sv}' $o/request/t/r3 $o/session/t/s1 t '' 0
  ```

  The stream stays suspended while nothing reads it. `Close` on the session's path
  (`org.freedesktop.impl.portal.Session`) removes it, and so does killing that backend.
- `qs ipc call` splits an argument at commas, so pass no JSON and no expression with a
  comma. A function named `show` is never called: `qs ipc call <target> show` lists
  the target instead.
- Offscreen cannot load anything built on `PanelWindow`: the bar, panels, popups, the
  OSD. Lift the part under test into `Scene.qml`, or replace
  `components/SlidingPanel.qml` in the copy with a window-less stand-in that has the
  same properties. `QSRIG_PLATFORM=wayland qsrig start` uses the real platform when
  layer-shell behaviour is the question; the probe's window then stays hidden.
- Offscreen wheel events come from a mouse device. On the real session every wheel
  event comes from a touchpad-type device, so a `WheelHandler` needs
  `acceptedDevices: PointerDevice.AllDevices`; reuse `components/WheelSteps.qml`.
- After a failed reload a rig answers "Not ready to accept queries yet". Stop it and
  start it again.

## Format and lint

```bash
quickshell/.config/quickshell/qs-fmt -w services/Audio.qml         # format in place
quickshell/.config/quickshell/qs-fmt --strict services/Audio.qml   # must exit 0
```

`qs-fmt` takes paths inside the shell's directory. `./setup.sh lint` runs
`--strict` on everything.

- The formatter joins an array of arrays into one line and expands an object literal
  one key per line. A table that should keep one row per line is a keyed object:
  `({ name: [a, () => b()] })`, as in `modules/ipc/Shortcuts.qml`.
- The lint catches a deleted member of a singleton that something still reads. It
  does not catch a name passed as a string (`icon: "bell"`, a setting key, a panel
  id): grep for the literal before removing one, with `grep -o` so that a long line
  cannot hide the match. `barKeys` in `modules/panels/SettingsPanel.qml` is one such
  line: a key left there shows as a dead switch.
- Comment only a trap, a quirk or an ordering dependency. The reason for a change
  goes in the commit message.

## After a live edit: confirm the reload

```bash
.claude/skills/quickshell-dev/scripts/qs-reloaded quickshell/.config/quickshell/services
```

It prints what the shell logged in the last 30 seconds and exits 0 only when the last
reload says `Configuration Loaded`. The argument is the edited file's directory.

- **No reload at all.** A file written by rename (the Edit tool, `sed -i`, git) can be
  missed by the file watcher. The script nudges it by creating and deleting a file in
  that directory. `touch` on the edited file does nothing, and neither does writing
  the same content again.
- **`Failed to load configuration`.** The old config keeps running, and the cause is on
  the next line. A popup at the top left of the screen stays while the pointer is on
  it, and `qs ipc` answers "Not ready" until it is gone. Fix the file; do not restart
  the shell to clear it.
- **A reload that failed because a file was missing is not tried again** when the file
  appears: Quickshell compares the contents of the files it tracks, and a new file or a
  `qmldir` is not among them, so the nudge does nothing either. Change the content of a
  tracked file, such as a blank line at the end of the file that names the new one, and
  take it out again. Better, never get there: write a new file before the `qmldir` and
  the files that name it, and chain the writes with `&&` so a failed step stops the rest.
- **After many files at once,** restart instead: `systemctl --user restart quickshell`.
  Never `pkill qs`: Quickshell does not stop its children, the unit's cgroup does. A
  restart clears the notification history and Stay Awake, so look for "Stay Awake is
  on" in `systemd-inhibit --list` first and turn it back on with
  `qs ipc call idle toggle`. A config that is broken at a restart exits at once, and
  the unit starts it again every two seconds until the file loads: fix the file, do
  not start the unit by hand.
- To see whether the live shell answers, use `qs ipc show`, never a call that changes
  something.

## Traps

- **A reload or a restart kills the shell's child processes.** Anything that must
  outlive a saved QML file, such as an upgrade running in a terminal or a recording,
  runs in its own unit: `Quickshell.execDetached(["uwsm-app", "--", …])` or
  `systemd-run --user`.
- **What survives a reload** is what sits in a `PersistentProperties` block, and only
  strings, numbers and booleans do; carry a list as JSON. A restart keeps nothing but
  `settings.json`.
- **A change handler also fires for the first value,** at start and at every reload.
  Do not log or act from `onFooChanged` as if the user did something;
  `services/OSD.qml` ignores its first two seconds for this reason.
- **A `Process` remembers `running = true` set while it runs** and starts once more
  when it exits. For something a user closes, toggle with `running = !running`.
- **A program that cannot be started** emits no `exited`, so `Command.onDone` never
  fires for it.
- **A setting is written 400 ms after it changes;** a reload inside that window reads
  the old value.
- **Icon glyphs are private-use characters** that tools drop silently. Use
  `Core.Icons.get(name)`; when a literal is needed, check its code point.
- **Text from outside is shown as plain text.** Window titles, network and device
  names and notification text can carry markup, and a `Text` in its default format
  would render it, an `<img>` included. `components/Text.qml` sets
  `textFormat: Text.PlainText`; a raw `Text` that shows such a string needs the same.
- **A layout of centred items does not grow.** A `ColumnLayout` whose children only set
  `Layout.alignment: Qt.AlignHCenter` is as wide as its widest child at most, so
  `Layout.fillWidth` on it does nothing and a row of such columns bunches up at the left.
  Give the labels `Layout.fillWidth: true` with `horizontalAlignment: Text.AlignHCenter`,
  and the row `uniformCellSizes: true` for equal columns. Only a render shows it.
- **Do not name a property `on` plus a capital letter.** In `Battery.qml`, which has a
  `battery` property, `readonly property bool onBattery: UPower.onBattery` stayed false
  whatever its source said; the same line named `isOnBattery` works. Neither the lint
  nor the log mentions it, so drive a new flag both ways in a rig before using it.
- **A session lock stops the shell's windows being drawn.** An animation in flight
  freezes and finishes after unlocking: a panel sliding out was caught 80% closed.
  hyprlock starts about 80 ms after the lock request and a slide takes 250, so what
  must be gone before a lock is removed with `Services.Panels.closeNow()`, not slid out.
- **`MprisPlayer.uniqueId` names the current track,** not the player: it counts up with
  each track, and every player starts at the same number. A player is known by its
  `dbusName`.
- **A PipeWire stream's node is named after its client,** not after the stream. Unless
  the client sets `node.name`, PipeWire uses the client's application name; the stream's
  own name lands in `media.name`, which a `PwNode` shows only once a `PwObjectTracker`
  has bound it. The portal's share is the video source named
  `xdg-desktop-portal-hyprland`; `xdph-streaming-<id>` is its `media.name`. A made-up
  node proves nothing about a name: read it off a real one.
- **Several live files written within one reload** can leave the last one unread. Compare
  the reload's start time in the journal with the files' write times, and nudge the
  directory if a write came later: a reload then means the file had been missed.
