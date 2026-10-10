---
name: fuzzel-missing-include-fatal
description: When fuzzel include missing, fatal error, launcher fails.
category: app-config
---

Fuzzel treats a missing include as fatal: exits 1 ("failed to read from configuration"), no window opens.

This breaks the launcher, clipboard picker, and cheatsheet—any tool that spawns fuzzel. Design options: (A) use `include=` in fuzzel.ini and seed an empty file during setup to guarantee it always exists, or (B) leave the launcher static and don't use includes.

If using includes, test with `fuzzel --check-config --config=<path>` to verify the file exists.
