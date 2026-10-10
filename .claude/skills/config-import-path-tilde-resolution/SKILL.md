---
name: config-import-path-tilde-resolution
description: When ~ used in config, resolved via /etc/passwd, not $HOME.
category: app-config
---

In config `import` or `include` statements, `~` is expanded via the user's /etc/passwd home directory, not the $HOME environment variable.

This means a fake HOME environment does not redirect tilde paths. For portable testing with alternate HOME values, use absolute paths instead of tilde in config imports.
