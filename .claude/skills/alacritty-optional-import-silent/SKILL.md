---
name: alacritty-optional-import-silent
description: When Alacritty import missing, silently skipped, INFO only.
category: app-config
---

Alacritty silently skips missing imports: logs one INFO line ("Config import not found"), no warning bar or error.

This makes Alacritty safe for relying on generated or optional config files that may not exist on fresh install. A running terminal recolours approximately 0.4 seconds after an imported file is swapped by rename.

Verify with `alacritty msg get-config` to dump resolved config and confirm missing imports are handled gracefully.
