---
name: gtk-settings-testing-keyfile-isolation
category: testing
description: When testing GTK settings: use keyfile backend isolation.
---

Use `GSETTINGS_BACKEND=keyfile` environment variable with separate `XDG_CONFIG_HOME` and `XDG_STATE_HOME` directories (in a scratchpad) to test GTK settings changes without touching the session's real dconf database.

The keyed settings write to `${XDG_CONFIG_HOME}/glib-2.0/settings/keyfile` instead of the system dconf database, so the real session is never modified. This is especially useful for testing Quickshell's `ThemeSync` service, which writes GTK settings (color-scheme, gtk-theme, icon-theme) when the desktop theme changes.

A test can verify that:
- A fresh GTK 3 process picks up the theme colors immediately
- A GTK 3 process left running follows theme switches live
- Rapid theme switches in sequence resolve to the final state (no lost updates)

Launch a throwaway Quickshell instance under this backend: `GSETTINGS_BACKEND=keyfile XDG_CONFIG_HOME=<scratch>/xdg XDG_STATE_HOME=<scratch>/state qs -p <config-dir>`. Probe the GTK state with a PyGObject script under the same environment variables.
