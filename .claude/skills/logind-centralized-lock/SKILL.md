---
name: logind-centralized-lock
category: system-integration
description: When locking via logind: keybind and UI call loginctl.
---

Instead of multiple places starting hyprlock independently (Hyprland keybind with pidof guard, shell button, systemd idle timer), route all lock requests through the same point:

- Keybind: `SUPER+Escape` → `loginctl lock-session`
- Shell UI: power button or lock button → `loginctl lock-session`
- Idle timer: systemd idle timeout → hypridle's `lock_cmd = loginctl lock-session`

Let hypridle's `lock_cmd` handle hyprlock startup. One place controls lock behavior; hyprlock never starts twice; consistent behavior regardless of trigger source.

Validated: journal shows hypridle running this path 41 times in 14 days with "Got Lock from dbus" → hyprlock startup.