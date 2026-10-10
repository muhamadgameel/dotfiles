---
name: dangerous-keybind-three-modifiers
category: keybind-safety
description: When implementing logout keybind: use three modifiers.
---

Keybinds that trigger destructive or unexpected actions (logout, restart, shutdown) should require three modifier keys to prevent accidental activation when fingers slip on the keyboard.

Example: use `SUPER+CTRL+SHIFT+Escape` for logout, not `SUPER+SHIFT+Escape` alone. Three modifiers provide a harder-to-hit target and catch mis-presses that could end a session unintentionally.

Applied in this setup after moving logout from SUPER+SHIFT+Escape (easy to hit by accident near lock key) to SUPER+CTRL+SHIFT+Escape.