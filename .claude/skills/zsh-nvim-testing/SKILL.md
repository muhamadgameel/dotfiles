---
name: zsh-nvim-testing
description: Testing changes to the zsh and Neovim configs (zsh/, nvim/) without touching the owner's history, caches, sessions, zoxide data or plugin installs - scratch XDG directories, a pty harness for interactive zsh and Neovim, A/B runs of two config versions, start-up timing, and proving that a removed option or plugin setting was a no-op. Use it for any edit under zsh/ or nvim/, for start-up time questions, and before claiming that a removal changes nothing.
---

# Testing zsh and Neovim changes

Both configs are live through stow links, and both write state as they run. A test
that starts the real shell or the real editor carelessly leaves history lines, a
session or installed parsers behind. Isolate first, then measure old against new.

## zsh

`.claude/skills/zsh-nvim-testing/scripts/ptyshell.py` starts an interactive zsh in a
pty, with its cache, history and zoxide data in a scratch directory. Each argument is
typed and its output printed:

```bash
python3 -u .claude/skills/zsh-nvim-testing/scripts/ptyshell.py 'echo $ZSH_CONF_DIR' 'alias ls'
```

As a module (`from ptyshell import Pty, isolated_env`) it sends keys (`\t`, `\r`,
`\x03` for Ctrl+C, `\x15` to clear the line) and reads what the terminal shows.

- **What is isolated:** `XDG_CACHE_HOME` (the completion dump and the cached-eval
  files), `XDG_STATE_HOME` (history) and `_ZO_DATA_DIR` (zoxide). Plugins come from
  `~/.local/share/zpm/plugins` and are shared; for anything that types `zpm …`, set
  `ZPM_PLUGIN_DIR` to a copy.
- **Two versions side by side:** copy `zsh/.config/zsh` to a scratch directory, with
  the old files from `git show HEAD:<path>`, and start with `ZDOTDIR=<copy>`.
  `ZDOTDIR` is already exported in the tool's environment, so `~/.zshenv` is not read
  there and an `XDG_CONFIG_HOME` override does nothing. Print `$ZSH_CONF_DIR` inside
  the shell under test to prove which config ran, and run an A/A control.
- **Never let it hang.** An open fzf or fzf-tab menu swallows keys, the final `exit`
  included. Leave a menu with Ctrl+C, not Escape; run under `timeout`; `Pty.close()`
  hangs up and then kills. `starship config` opens an editor.
- **Timing depends on the power profile:** about 30 ms on performance; on balanced it
  is bimodal, about 36 or 62 ms per batch. Compare within one interleaved batch, and
  repeat. `ZSH_PROFILE=1 zsh -i -c exit` prints zprof.
- **Probes:** `${_comps[cmd]}` names the function that completes a command;
  `zsh -f -c 'set -o'` lists the defaults, to show that a removed `setopt` only
  restated one.
- **In the tool's own zsh,** `$var` is not word-split, and an inline `zsh -i -c '…'`
  can be refused: put the commands in a file. `zsh -i -c` without a terminal prints
  `can't change option: zle`, which is fzf's init and not a fault.
- Syntax alone: `zsh -n <file>`; `./setup.sh lint` runs it on every file.

## Neovim

- **Isolate the config, and know what stays real.** Seed a scratch `XDG_CONFIG_HOME`
  with `git archive HEAD nvim/.config/nvim | tar -x -C <scratch>` (or a copy that
  carries the change), and point `XDG_CACHE_HOME` and `XDG_STATE_HOME` at scratch too.
  Plugin data stays in the real `~/.local/share/nvim`.
- **Install-on-start lists** (nvim-treesitter's parsers, mason-tool-installer's tools)
  install at every start. After editing such a list, do not start the real config:
  test with `install_dir = '<scratch>'` in a scratch copy, and leave the real download
  to the owner's next start.
- **Start outside `~/Projects`.** auto-session saves per directory, and a start there
  can overwrite a saved session. `-i NONE` keeps shada out. Every start in a new
  directory makes harpoon write `~/.local/share/nvim/harpoon/<sha256 of the cwd>.json`;
  delete the one the test made.
- **Driving it:** start `nvim --listen $XDG_RUNTIME_DIR/<short>.sock` inside the pty (a
  socket under a long scratch path fails with E247), send keys through the pty, and
  read state with
  `nvim -u NONE --headless --server <sock> --remote-expr "luaeval(\"…\")"` returning
  `vim.json.encode{…}`. Read `:messages` as well as the notifier's history: an
  autocmd that errors shows only there.
- **Proving a removal is a no-op.** Measure the "after" before editing: switch a
  required module off with `--cmd "lua package.loaded['core.x'] = true"`, an autocmd
  group with `-c "autocmd! Group"`. For an option that restates a default, quote the
  plugin's own default from `~/.local/share/nvim/lazy/<plugin>/`, file and line. For
  anything that touches behaviour, dump state from a scratch copy before and after
  (plugins, commands, LSP configs, autocmd groups) and diff.
- **Timing:** 20 interleaved headless starts with `--startuptime`; jitter on the
  balanced profile is about 2 ms.
- **Test files under `/tmp` keep no marks or cursor position,** because the default
  `shada` excludes it. Use `$XDG_RUNTIME_DIR`.
- **Try a new or replaced picker on this repo's layout,** not on a toy folder: nearly
  everything here sits under hidden `.config` directories.
- Format: `stylua --check --search-parent-directories nvim/.config/nvim/init.lua`; the
  config has its own `.stylua.toml`.
