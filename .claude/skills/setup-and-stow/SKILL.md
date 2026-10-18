---
name: setup-and-stow
description: How this dotfiles repo installs itself and what may be run - adding a package to setup/packages, a new stow package for an app's config, a system file under setup/system, a systemd unit, a launcher entry or a check in setup.sh, what stow links and which directories must stay real, and what only the owner runs. Use it whenever a change adds or removes a package, creates a config for another app, touches setup.sh, setup/ or anything that ends up in /etc, and before any command that installs, needs sudo or enables a unit.
---

# setup.sh and stow

Each top-level directory is a GNU stow package that mirrors `$HOME`. `setup.sh` and
`setup/` bring a machine in line and are not stowed. Stow has already linked the
packages, most of them as whole directories, so the repo is the running system.

## Who runs what

- **The owner runs** everything that installs or needs root:
  `./setup.sh install [step]`, `pacman`, `yay`, `sudo`. List the command and wait.
- **Never raise a password prompt.** A polkit prompt nobody answers counts as a failed
  login, and three lock sudo, polkit and the lock screen for ten minutes.
  `firewall-cmd --list-all` as a plain user does it: read `/etc/firewalld/zones/`
  instead, or ask the owner to run `sudo firewall-cmd`.
- **The owner commits.** End a step with a suggested message:
  `<package>: <lowercase imperative summary>`, several packages comma-separated, and
  the reason in the body, with the measurements if there were any.
- **Free to run:** `./setup.sh`, which reports what is missing and changes nothing
  (exit 0 nothing missing, 1 something missing), `./setup.sh lint`, and
  `systemctl --user daemon-reload`. Restart a user unit when the step needs it; for
  the shell, read the quickshell-dev skill first.

## Adding things

| Adding | Do |
|---|---|
| A package | A line in `setup/packages/<group>.txt` (`base`, `hardware`, `desktop`, `dev`, `gaming`, `apps`), with an `aur/` prefix for the AUR and the reason after `#` when it is not obvious. On macOS, `setup/macos/Brewfile`. |
| A config for an app | A new top-level directory that mirrors `$HOME` (`foo/.config/foo/…`). Add it to the table in `README.md`, and to `mac_packages` in `setup.sh` if macOS uses it too. `./setup.sh` then shows what stow would link. |
| A file for `/etc` or `/usr/local` | Under `setup/system/`, mirroring `/`. It is copied, not linked: nothing changes until the owner runs `./setup.sh install system`, which also rebuilds the initramfs, reloads sysctl or reloads firewalld when a file of that kind changed. Add a row to "System changes" in `README.md`. |
| A unit to enable | `setup/services.txt`, as `system <unit>` or `user <unit>`. A unit the repo ships lives in the package it belongs to (`hypr/.config/systemd/user/`). Enable only: `disable` and `reenable` delete a stowed unit's link. |
| Something to check or fix | One `item <label> <check> <fix>` line in the step it belongs to (pacman, packages, stow, aur, system, user, services) and two small functions. The fix runs its commands through `run`, which only prints them in check mode. Something to mention with no fix is a `warn`. A check that reads a command's output captures it first (`have=$(cmd) && [[ $have == *x* ]]`): the script sets `pipefail`, and `cmd \| grep -q x` exits 141 when grep stops reading before `cmd` has finished writing. A new item shows as missing on this machine until the owner runs its step. |
| A launcher entry, or hiding one | `desktop/.local/share/applications/<name>.desktop`. To hide a packaged entry, a three-line stub with `Hidden=true`, never a copy of the packaged file. |

## What stow does with a careless file

- **A package root holds its `$HOME` mirror and an optional `README.md`, nothing
  else.** Stow skips the README and links every other entry into `~`: a notes file, a
  nested `CLAUDE.md`, a stray `.claude/`. Keep the working directory at the repo root;
  a `cd` into a package can leave a lock directory there.
- **A missing target directory gets linked whole,** and whatever an app later writes
  into it lands in the repo. Directories that apps or `systemctl --user enable` write
  into are listed in `real_dirs` in `setup.sh` and created before stow runs:
  `~/.config/systemd/user`, `~/.config/Thunar`, `~/.config/Code - OSS/User`,
  `~/.local/bin`, `~/.local/share/applications`. Add to that list when a new package
  puts a file where an app writes.
- **Apps write into the linked directories.** An untracked file, or a diff nobody
  made, can be an app's doing. Check the file's mtime and what the app does before
  trimming it; add state files to `.gitignore`.
- **Where an app reads drop-ins (`*.conf.d/`), change single keys there.** A full copy
  of a packaged config stops following the package.
- **`~/.gitconfig` is a real file** that holds the identity. The tracked git config is
  `~/.config/git/config`.

## Checks

```bash
./setup.sh           # everything in place?
./setup.sh lint      # bash -n, shellcheck, shfmt, zsh -n, stylua, qs-fmt
shfmt -d -i 2 -ci setup.sh && shellcheck setup.sh
```

A shell script added to the repo joins the `sh` list in `lint()` in `setup.sh`.
