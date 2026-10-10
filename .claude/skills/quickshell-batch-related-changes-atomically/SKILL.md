---
name: quickshell-batch-related-changes-atomically
description: Use when Quickshell refactors span related files.
category: quickshell-development
---

When refactoring spans a new component and services that consume it, or multiple services with related changes, write all files together in one atomic batch rather than piecemeal. This ensures the reload sees the complete logical unit and avoids transient states where files mismatch.

Use `qslive_many.py` (or equivalent) to write all files within milliseconds, nudge the watcher, and verify one clean reload. A single "Configuration Loaded" that straddles all writes proves the coherence. Test rigs can then run both the old and new versions as complete wholes, not partial or intermediate states.

Benefit: clearer validation, fewer edge cases from asymmetric states, and confidence that the logical group behaves as a unit.