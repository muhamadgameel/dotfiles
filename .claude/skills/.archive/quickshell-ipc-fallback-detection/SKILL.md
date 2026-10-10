---
name: quickshell-ipc-fallback-detection
category: quickshell-development
description: When qs ipc needs fallback: exit 255 shell down, 0 up.
---

`qs ipc call` returns distinct exit codes you can detect:

- Exit **255** if quickshell is not running → trigger fallback with `|| fallback_command`
- Exit **0** if quickshell IS running, even if the function name is invalid → fallback won't spuriously double-execute
- Keep output/file naming identical across primary and fallback paths (e.g., YYYY-MM-DD_HH-MM-SS for screenshots in both shell service and grim)

Pattern tested with uinput keyboard injection, shell running and stopped.