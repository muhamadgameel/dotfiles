# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Dotfiles for one Arch Linux laptop (Hyprland under uwsm, with a Quickshell
shell), plus a smaller set for macOS. Each top-level directory is a GNU stow
package that mirrors `$HOME`. `setup.sh` and `setup/` bootstrap the machine
and aren't stowed.

[README.md](README.md) has the package table and the system changes. `hypr/`,
`quickshell/`, `zsh/` and `gitconfig/` each have a README of their own: read
it before changing that package.

## The repo is the running system

- Stow has linked the packages into `~`, most of them as whole directories
  (`~/.config/hypr`, `~/.config/quickshell`, `~/.config/nvim`). Saving a file
  here changes the live desktop at once: Hyprland and Quickshell reload on
  save.
- Apps write into those directories too, so an untracked file, or a diff
  nobody made, can be an app's doing. `.gitignore` covers the known state
  files.
- `setup/system/` is copied to `/etc` and `/usr/local`, not linked. An edit
  there changes nothing until `./setup.sh install system`.
- A package root holds its `$HOME` mirror and an optional `README.md`, nothing
  else. Stow skips the README but links other entries into `~`, such as a
  notes file, a nested `CLAUDE.md` or a stray `.claude/`. Keep the working
  directory at the repo root and don't `cd` into a package.

## Commands

```bash
./setup.sh                  # check: report what's missing; changes nothing
./setup.sh lint             # bash -n, shellcheck, shfmt, zsh -n, stylua, qs-fmt
./setup.sh install [step]   # fix what check reports; runs sudo, pacman, yay
```

`install`, and anything else that installs packages or needs sudo, is the
user's to run: list the commands and wait.

There is no test suite. To check one file:

```bash
quickshell/.config/quickshell/qs-fmt --strict services/Audio.qml
stylua --check --search-parent-directories nvim/.config/nvim/init.lua
shfmt -d -i 2 -ci setup.sh && shellcheck setup.sh
zsh -n zsh/.config/zsh/core/aliases.zsh
```

`qs-fmt` takes a path inside the shell's directory, and `qs-fmt -w` is how QML
gets formatted: the Qt 6 tools it wraps aren't on PATH. Given a directory,
stylua skips the hidden `.config` inside it unless it gets `--allow-hidden`,
as the lint passes.

After an edit, check what reloaded:

- Hyprland: `hyprctl configerrors` prints nothing.
- Quickshell: `journalctl --user -u quickshell -n 50` shows a new
  `Configuration Loaded`. A failed reload keeps the old config running, and a
  replaced file can go unnoticed;
  [quickshell/README.md](quickshell/README.md#editing-and-hot-reload) has the
  remedies. Restart it with `systemctl --user restart quickshell`, never
  `pkill qs`.
- The other daemons: `journalctl --user -u <unit>`.

`.claude/skills/` has the recipes and helper scripts for trying a change away
from the live session:

- `quickshell-dev`: where a shell feature goes, a throwaway offscreen instance
  that renders to a PNG (`qsrig`), and a check that the live shell reloaded
  (`qs-reloaded`).
- `hyprland-lua`: the stub file, `hyprctl eval` probes, and a virtual keyboard
  for real key presses (`vkbd.py`).
- `setup-and-stow`: packages, stow packages, system files, units, and what is
  the user's to run.
- `zsh-nvim-testing`: an isolated interactive zsh in a pty (`ptyshell.py`),
  scratch XDG directories for Neovim, and proving a removal is a no-op.

## How the pieces fit

**`setup.sh`** is a list of `item <label> <check> <fix>` lines. Each check and
fix is a small function, and a fix runs its commands through `run`, which only
prints them in check mode. Managing something new takes one `item` line and
two functions, in the step it belongs to: pacman, packages, stow, aur, system,
user or services. Its data is in `setup/`: `packages/<group>.txt` (an `aur/`
prefix marks an AUR package), `services.txt` (units to enable) and `system/`
(a mirror of `/`). `real_dirs` names the directories that must be real before
stow runs, so that apps and `systemctl --user enable` never write into the
repo. `mac()` is the macOS path; bat, btop, gitconfig, lazygit, mpv, nvim,
starship, tmux and zsh are stowed on both systems and have to work on both.

**The session.** uwsm starts Hyprland. Session environment variables go in
`uwsm/.config/uwsm/env`, not in `hl.env()`. The daemons (awww-daemon, hypridle,
hyprsunset, quickshell and the rest of `setup/services.txt`) are systemd user
units, not Hyprland autostart entries. The units this repo ships are symlinks:
`enable` them, and never `disable` or `reenable` one, which deletes the link.

**Hyprland** (`hypr/`) uses the Lua config. `hyprland.lua` requires
`settings/*.lua`, and the API is `hl.*`: read
`/usr/share/hypr/stubs/hl.meta.lua` instead of writing `hyprland.conf` syntax
from memory. `hypridle.conf` and `hyprlock.conf` do use that older syntax.
Every bind has a `description`, and the keybind table in
[hypr/README.md](hypr/README.md#keybinds) is generated from them; the command
is under the table. A bind made with the local `bind()` in
`settings/keybinds.lua` is also an entry in the command palette on SUPER+P;
`hl.bind` makes one that is not.

**Quickshell** (`quickshell/`) is the bar, the panels, the OSD and the
notifications, in QML. `shell.qml` builds the bar (one window per screen,
which owns the panels) and the popups; everything else is a singleton created
on first use. `config/Config.qml` declares every setting with its default
inline and reads through `Settings.qml`, a watched JSON file in
`~/.local/state/quickshell/`. `services/` has one singleton per system
concern. Services import `core/` and `config/` and never a component or a
module, and they run one-shot programs through `core/Command.qml`.
`services/Panels.qml` is the registry of the one open panel: bar widgets,
`qs ipc` and the global shortcuts open panels through it, and `BarWindow`
loads a panel only while it is open.

**Across packages.** A change to one side of these needs the other:

- Theme colours: `services/ThemeSync.qml` writes `hyprland-colors.lua`,
  `hyprlock-colors.conf`, `alacritty-colors.toml` and `fuzzel-colors.ini` into
  `~/.local/state/quickshell/`, and `settings/theme.lua`, `hyprlock.conf`,
  `alacritty.toml` and `fuzzel.ini` read them. fuzzel won't start while its
  file is missing, so `setup.sh` seeds an empty one. A theme switch recolours
  Hyprland live through `paint()` in `settings/look.lua`, so a new colour
  option goes in that function.
- Theme names: the command palette's list in `settings/keybinds.lua` repeats
  the themes of `core/Themes.qml`.
- Shell keys: a bind calls `hl.dsp.global("quickshell:<name>")` in
  `settings/keybinds.lua`, and `<name>` is a key of `shortcuts` in
  `modules/ipc/Shortcuts.qml`.
- `qs ipc call <target> <function>`: the targets are in `modules/ipc/Ipc.qml`,
  and `qs ipc show` lists them.
- Games: `games` in `settings/rules.lua` and `_gameClass` in
  `services/GameMode.qml` hold the same regex.
- Session entry: uwsm launches
  `setup/system/usr/local/share/wayland-sessions/hyprland.desktop`, so that
  file must keep its `Exec` line.

**zsh** runs `.zshenv`, `.zshrc`, then `init.zsh`, which sources `core/*.zsh`
and the zpm plugins in an order that matters
([zsh/README.md](zsh/README.md#startup-order)). **Neovim** is `init.lua`,
`lua/core/` and one lazy.nvim spec per file in `lua/plugins/`, lazy by
default. `lua/plugins/lsp.lua` lists the language servers, and each one's
settings are in `after/lsp/<name>.lua`; most servers are system packages from
`setup/packages/`, and mason installs only what those lack.

## Conventions

- Formatting follows `.editorconfig`: two spaces, tabs in `hypr/**.lua`, four
  spaces in the hypr and pipewire `.conf` files. Neovim's Lua has its own
  `.stylua.toml`.
- Where an app reads drop-ins (`*.conf.d/`), change single keys there. Never
  copy a whole packaged config into `~/.config`: the copy stops following the
  package.
- Comment only what the code can't show: a trap, a platform quirk, an ordering
  dependency. Why a change was made goes in the commit message.
- Commit subjects are `<package>: <lowercase imperative summary>`, with
  several packages comma-separated (`setup, quickshell: …`). The body says
  why, with the measurements if there were any.
- Keep the docs in step with a change: the package and system-changes tables
  in `README.md`, the keybind table in `hypr/README.md`, and the package's own
  README.
- "Considered and not installed" in `README.md` lists the tools and features
  already declined. Don't propose them again.
