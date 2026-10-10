---
name: quickshell-multi-file-live-writes
description: When writing Quickshell files: atomic swaps, verify reload.
category: testing
---

Update multiple Quickshell config files at once by writing them atomically, nudging the watcher to trigger a reload, and verifying that reload completed.

Write all files within milliseconds (temp file in the same directory, then atomic rename). After all writes, nudge the watcher by touching and removing a probe file in one of the directories. Poll the journal for a reload that started after the last write completed. Check inotify watches to confirm each new file inode is being watched. Each intermediate combination of old and new files must be loadable.

See qslive_many.py from the 2026-10-08 scratchpad: polls `hyprctl cursorpos` to avoid writing while a failed-reload popup might stick, records reload timestamps from journalctl, validates that "Reloading configuration" + "Configuration Loaded" pair straddles the write time.