---
name: hypridle-condition-gated-listeners
category: system-integration
description: When hypridle listener needs a gate: use condition_cmd.
---

When a listener should only fire in a specific state (e.g., only while locked), use `condition_cmd` with `condition_retry` instead of embedding shell logic like `pidof process && command` in the on-timeout.

**Structure:**
- `condition_cmd`: shell command returning 0 (exit) if the gate is open, non-zero otherwise.
- `condition_retry`: seconds between rechecks if the condition failed; hypridle will pause the listener and retry.
- `ignore_inhibit`: set to `true` to fire even when other inhibitors (audio via pipewire-idle-inhibit, Stay Awake toggle) are active.

When the condition blocks on-timeout, hypridle rechecks in `condition_retry` seconds and skips the on-resume call on the next timeout. This keeps gate logic separate from action logic and is cleaner than shell operators.

Example: turn the display off 60 seconds into idle, but only while locked:

```
listener {
    timeout = 60
    condition_cmd = pidof hyprlock
    condition_retry = 60
    on-timeout = hyprctl dispatch 'hl.dsp.dpms({action = "off"})'
    on-resume = hyprctl dispatch 'hl.dsp.dpms({action = "on"})'
    ignore_inhibit = true
}
```

The `ignore_inhibit` ensures a locked screen stays dark even during audio playback.