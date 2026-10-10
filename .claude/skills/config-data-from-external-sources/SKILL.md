---
name: config-data-from-external-sources
category: setup
description: Use when syncing from external sources: apply atomically.
---

Extract data from authoritative sources via script, validate it equals both upstream and user's current version, then apply via atomic file swap: write to a tempfile in the same directory, then `os.replace()` to swap atomically. This ensures processes watching inotify never see partial state.

See `references/extraction-pattern.md` for a worked example extracting colour schemes from TOML files.