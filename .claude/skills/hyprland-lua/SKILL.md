---
name: hyprland-lua
description: Working on the Hyprland Lua config in hypr/ - finding the real hl.* API in the stub file, probing argument names and live state with hyprctl eval, adding keybinds with descriptions and regenerating the README table, window and layer rules, hypridle and hyprlock, and testing binds with real key presses from a virtual keyboard. Use it for any change under hypr/.config/hypr/, whenever a dispatcher's arguments are not known for certain, and before pressing or simulating keys or pointer input on the live session.
---

# The Hyprland Lua config

`~/.config/hypr` is a symlink into `hypr/.config/hypr/`, so saving a file reloads
Hyprland. `hyprland.lua` requires each `settings/*.lua`, and an error in one module
aborts only that module.

## Find the API, do not recall it

`/usr/share/hypr/stubs/hl.meta.lua` lists every function, config option, event name and
bind option of the installed version. Read it before writing: `hyprland.conf` syntax
from memory is wrong here. (`hypridle.conf`, `hyprlock.conf` and `hyprpaper.conf` do
use the older syntax.)

The stub types every dispatcher as `fun(...)`, so argument names are not in it. Take
them from the wiki, from the error strings in the binary
(`strings "$(command -v Hyprland)" | grep 'hl.dsp.window'`), or by probing. Already
probed on 0.56.2:

- `window.float` and `window.pin` take `action = "enable" | "disable" | "toggle"`.
  `"set"` and `"unset"` are not errors there; they silently toggle.
- `window.fullscreen_state({ internal, client })` sets exactly what is passed.
- `window.resize({ x, y })` and `window.move({ x, y })` are absolute; add
  `relative = true` for a step.
- A dispatcher takes a selector, `{ …, window = "class:foo" }` or `"address:0x…"`.
  `hl.get_window("class:foo")` reads one window; `hl.get_windows({ class = "foo" })`
  compares the class exactly.
- A rule's `move` is a string of expressions (`"monitor_w-642 monitor_h-362"`). In a
  rule that also sets `size`, `window_w` and `window_h` are the window's original size.
- `release = true` is a bind option. A modifier's state can change between a press and
  its release, so a hold-to-act pair belongs on a key without modifiers.
- `hl.on("input.keyboard.key", fn)` hands `fn` a key code, a time in ms and a state
  (1 down, 0 up) for every keyboard device.
- `hl.dispatch(x)` runs a dispatcher object or a function, also from `hyprctl eval`. A
  dispatcher object is a plain value: the one handed to `hl.bind` can be kept in a
  table and dispatched again and again. `hl.dsp.global` dispatched this way sends a
  press each time, with no release, and the shell acts on every one.

## Probe the live compositor

`hyprctl eval '<lua>'` runs in the config's own Lua state and prints only `ok`. To read
a value, write it to a file:

```bash
hyprctl eval "local f = io.open('$SCRATCH/out.txt', 'w'); f:write(tostring(hl.get_active_window().class)); f:close()"
```

- The config's modules are visible there (`package.loaded["settings.theme"]`).
- A reload, by `hyprctl reload` or by saving any config file, starts from a fresh Lua
  state. Everything added through `eval` is gone after it: binds, rules, event
  handlers, globals. That makes `eval` the place to try a rule or a bind first.
- Without Lua: `hyprctl getoption <section:name>`, `hyprctl binds -j`,
  `hyprctl clients -j`, `hyprctl devices -j`, `hyprctl getprop class:foo no_dim`.
- A real window that never shows: add
  `hl.window_rule({ match = { class = "qsprobe" }, workspace = "special:qsprobe silent" })`
  through `eval`, then start the app with that class. Close it by its address from
  `hyprctl clients -j`. Do not `pkill -f <pattern>`: the pattern matches the shell
  that runs it.
- Hyprland floats a fixed-size window by itself. Read `floating`, `size` and `at` of a
  hidden probe window before proposing a float rule.

## After an edit

```bash
hyprctl configerrors     # must print nothing
stylua --check --allow-hidden --search-parent-directories hypr/.config/hypr/settings/keybinds.lua
```

Tabs, per `.editorconfig`. Without `--allow-hidden` stylua skips `.config` and checks
no file.

## Keybinds and the session

- Every bind has a `description`. The command palette (SUPER+P) and the table in
  `hypr/README.md` are built from them; regenerate the table with the command printed
  under it. In `settings/keybinds.lua` the local `bind()` makes a bind and lists it in
  the palette; `hl.bind` makes one that is not listed.
- Check a change to `settings/keybinds.lua` outside Hyprland first:
  `XDG_RUNTIME_DIR=<scratch> lua .claude/skills/hyprland-lua/scripts/bindcheck.lua <file>`
  prints every `hl.bind` call, so a `diff` of the output for two versions shows which
  binds a change touched, and it fails when a palette line would run another entry's
  action. Live, compare `hyprctl binds -j` from before and after the save.
- `fuzzel -d --index` prints the picked line's place in its input, counted from 0, also
  while the list is filtered. `--search=<text> --auto-select` picks without a key when
  one line matches, which tests a menu's command without the owner's hands.
- SUPER+letter starts an app. SUPER+SHIFT+letter opens a shell panel or flips a shell
  toggle through `hl.dsp.global("quickshell:<name>")`, where `<name>` is a key of
  `shortcuts` in `quickshell/.config/quickshell/modules/ipc/Shortcuts.qml`. Find free
  keys in `hyprctl binds -j`, not by eye.
- A bind that can end the session carries three modifiers.
- Session variables go in `uwsm/.config/uwsm/env`, not `hl.env()`. Daemons are systemd
  user units, not autostart entries.
- Locking goes through `loginctl lock-session`. hypridle's `lock_cmd` is the one place
  that starts hyprlock, after closing the shell's open panel and resetting the layout,
  and hypridle reads its config only at start (`systemctl --user restart hypridle`).
  A `lock_cmd` that fails to parse or run leaves the screen unlocked, so try a new one
  without locking: run it under `/bin/sh -c` with stand-ins for its programs first on
  PATH, then give the same text to a second `hypridle -v -c <scratch conf>` as the
  `on-timeout` of a `listener` with `timeout = 1` and `ignore_inhibit = true`, under
  `dbus-run-session` and the same PATH, and stop it once the stand-ins were called.
- A game is known by its window class: `games` in `settings/rules.lua` and
  `_gameClass` in `quickshell/.config/quickshell/services/GameMode.qml` hold the same
  pattern.

## Real key presses without the owner's hands

`.claude/skills/hyprland-lua/scripts/vkbd.py` creates a virtual keyboard through
`/dev/uinput` (writable here through an ACL) and presses real keys:

```bash
python3 .claude/skills/hyprland-lua/scripts/vkbd.py SUPER+F2
python3 .claude/skills/hyprland-lua/scripts/vkbd.py 240 400    # hold an inert key for 400 ms
```

- A key that no bind takes goes to whichever window has focus. Press only what is
  bound, or key 240, which types nothing. Read `hyprctl activewindow` before a key an
  app could act on.
- For a sequence, or two keyboards at once, import `Kbd` from the script. A new device
  needs about two seconds before Hyprland sees it.
- Pointer and touchpad input is harder. Position with `hl.dsp.cursor.move`, never with
  relative moves, which acceleration distorts; then move 3 px away and back, because
  Hyprland re-checks pointer focus only when the whole-pixel position changes. Inject
  nothing unless the target itself reports hover, and ask the owner first to keep
  their hands off for those seconds: a block appearing under their pointer makes them
  move it.
- Hyprland acts on a touchpad gesture without taking it from the app underneath, also
  with a modifier held. `direction = "pinchout"` fires when the fingers move together.
