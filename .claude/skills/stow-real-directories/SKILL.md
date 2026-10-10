---
name: stow-real-directories
category: setup
description: When stowing: prevent stow from folding parent directories.
---

Pre-create empty real system directories in setup.sh before running stow, or stow will link parent directories (like `~/.local`) into the repo.

On a fresh install, when a directory doesn't exist at the target, stow links the entire parent into the repo instead of individual files. Create a list in setup.sh (`real_dirs=( "$HOME/.config/systemd/user" "$HOME/.local/share/applications" )`), create them before stow runs, and verify in checks that they exist but are not symlinks.

Affects any dotfiles package containing subdirectories under standard user locations like `~/.local`, `~/.config` where apps will write entries (launchers, cache) that must never be committed.