# zsh

Interactive zsh with a small plugin manager (zpm), cached tool start-up and the
starship prompt. Everything lives in `~/.config/zsh` except `~/.zshenv`. With
warm caches a new shell starts in about 30 ms on the performance power
profile and 60 ms on balanced.

## Startup order

1. **`~/.zshenv`** runs for every zsh, scripts included. It only sets the XDG
   base directories and `ZDOTDIR=~/.config/zsh`, so zsh looks for the rest
   there.
2. **`.zshrc`** runs for interactive shells. It sets up the profiling hook,
   the cache directories and starship's paths, then sources `init.zsh`.
3. **`init.zsh`** adds `completions/` and `functions/` to `fpath`, autoloads the
   functions, and sources the `core/` files in this order:

   | File | Holds |
   |---|---|
   | `core/settings.zsh` | Shell options and history. |
   | `core/cache.zsh` | `cached-eval` (see [Cached start-up](#cached-start-up)). |
   | `core/input.zsh` | Key bindings, with sequences for both terminal key modes. |
   | `core/aliases.zsh` | Aliases and `sys-update` for each OS. |
   | `core/env.zsh` | PATH, an `EDITOR` fallback for the console and SSH, the man pager (bat), `GPG_TTY`, the Android SDK and fnm. |
   | `core/fzf.zsh` | fzf defaults, previews and key bindings. |

   Then it loads zpm and the plugins. The order there matters:
   zsh-completions adds to `fpath`, so it loads before `core/completion.zsh`
   runs compinit; zoxide and fzf-tab need compinit, zoxide to register its
   `cd` completion; fast-syntax-highlighting wraps every widget, so it loads
   last. starship comes at the very end, with its empty
   right prompt removed: rendering it cost about 5 ms per prompt for nothing.

`functions/` holds autoloaded functions (`archive`, `unarchive`, `lsarchive`),
and `completions/` their completions plus zpm's.

## Plugins (zpm)

`zpm.zsh` is a small plugin manager in the style of Zap. Each `Plug` line in
`init.zsh` clones its repository into `~/.local/share/zpm/plugins` on first use
and sources it:

```zsh
Plug "owner/repo"                 # GitHub shorthand
Plug "owner/repo" "v1.2.0"        # pinned to a tag, branch or commit
Plug "https://example.com/x.git"  # any git URL
Plug "~/code/my-plugin"           # local directory, never cloned or updated
```

| Command | Does |
|---|---|
| `zpm list` | List the declared plugins. |
| `zpm update` | Update every plugin in parallel, skipping pinned ones. |
| `zpm clean` | Remove plugins that are no longer declared. |
| `zpm compile` | Rebuild the `.zwc` byte-code cache. |
| `zpm doctor` | Report problems with the setup. |

The plugins are zsh-completions, fzf-tab, zsh-autosuggestions,
zsh-history-substring-search and fast-syntax-highlighting.

## Cached start-up

`eval "$(tool init zsh)"` starts the tool on every new shell just to print the
same code again. `cached-eval <name> <command...>` saves that output to
`~/.cache/zsh/init/<name>.zsh`, compiles it and sources the file instead. It
regenerates the file when the tool's binary is newer than the cache or the
command changes. starship, zoxide and fzf start this way. `zsh-cache-clear`
deletes the cache, and the next shell rebuilds it.

Don't cache output that depends on the session: `fnm env` embeds a per-shell
directory under `/run/user`, so it runs live.

## Profiling

```zsh
ZSH_PROFILE=1 zsh -i -c exit             # zprof: time spent in each function
for i in {1..8}; do time zsh -i -c exit; done
starship timings                         # cost of each prompt module
```

## Keys

Emacs mode. On top of zsh's defaults:

| Keys | Does |
|---|---|
| Up / Down | Search history for lines that start with what's typed. |
| Tab | Completion menu in fzf (fzf-tab). Shift+Tab goes back. |
| Ctrl+R | Search history in fzf. Ctrl+Y copies the selected command. |
| Ctrl+T | Insert a path picked in fzf. |
| Alt+C | `cd` into a directory picked in fzf. |
| Ctrl+Space | Expand aliases, global ones included. |
| Alt+Up | `cd ..` |
| Alt+Left | Back to the previous directory. |
| Ctrl+X Ctrl+E | Edit the command line in `$EDITOR`. |
| Alt+Q | Park the current line, run another command, then get it back. |
| Alt+M | Repeat the previous word. |
| Alt+E | Expand the command name to its full path. |
| Alt+K | Delete to the start of the line. |
| Ctrl+Left / Ctrl+Right | Move by word. |
| Space | Expand history references such as `!!` and `!$`. |

Inside fzf, Ctrl+/ toggles the preview, Alt+Up and Alt+Down scroll it, and
Alt+A selects everything. F1–F12, Page Up, Page Down and Insert do nothing
rather than typing a `~`.

`cd` itself is zoxide: `cd foo` jumps to the most-used directory matching
`foo`, `cd foo` then Space and Tab lists every match to pick from, and `cdi`
picks one in fzf.
