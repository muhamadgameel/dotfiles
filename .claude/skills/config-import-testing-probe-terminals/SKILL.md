---
name: config-import-testing-probe-terminals
description: When testing config imports safely use probe terminals.
category: testing
---

To test config file imports without affecting the live system: create a temporary Hyprland rule, spawn a test window into a hidden workspace, and dump its resolved config using the app's introspection command.

Example: Add temporary rule `{ match = { class = "qsprobe" }, workspace = "special:qsprobe silent" }`, spawn Alacritty with `--class qsprobe`, and run `alacritty msg get-config` to dump resolved config. Compare before/after dumps to verify that imports work, missing files are handled gracefully, and theme switches propagate.

Test window stays off-screen and out of the way.
