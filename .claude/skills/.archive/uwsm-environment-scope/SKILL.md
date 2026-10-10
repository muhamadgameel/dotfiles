---
name: uwsm-environment-scope
category: config
description: "When configuring session env: use uwsm/env, not hl.env()."
---

Variables have different scopes in a Wayland session with uwsm and Hyprland:

- `hl.env()` in `settings/env.lua` reaches only processes Hyprland starts directly (child processes), not D-Bus/systemd apps.
- `uwsm/env` is sourced by uwsm before the compositor starts, so it reaches the activation environment that systemd and D-Bus inherit.

For system-wide variables (PATH, EDITOR, VISUAL, TERMINAL, PAGER, toolkit backends), use `uwsm/env`. Don't duplicate them in Hyprland config.

**Gotcha:** `$UWSM_FINALIZE_VARNAMES` lists variables for re-export, but they won't appear in the activation environment unless set upstream (in `uwsm/env` or elsewhere).

Remove duplicate variables from hyprland.lua to avoid confusion.