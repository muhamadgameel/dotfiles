---
name: dotfiles-explicit-vs-dependency-packages
description: Use when deciding manifest entries: list only directly-used.
category: setup
---

A package belongs in `setup/packages/*.txt` if you use it directly, even if currently installed only as a dependency of something else.

To decide: `pacman -Qi PACKAGE | grep "Required By"` shows what depends on it. If you actively use it, add it with a comment explaining the dependency (e.g., "yt-dlp merges video and audio with it"). `./setup.sh check` reports missing packages; `./setup.sh install packages` installs them and auto-marks as explicit.

Keep macOS equivalents in `setup/macos/Brewfile` in sync. Record the decision in the overhaul plan with the phase and reasoning.