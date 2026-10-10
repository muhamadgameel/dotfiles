---
name: quickshell-jsonadapter-write
category: quickshell-development
description: When using JsonAdapter: debounce and guard its echo.
---

`FileView { JsonAdapter {} }` wired the documented way (`onAdapterUpdated: writeAdapter()`, `watchChanges: true`, `onFileChanged: reload()`) does not replace a debounce timer or a self-write guard. Measured on Quickshell 0.3.1 under `QT_QPA_PLATFORM=offscreen`:

- Every write serialises all adapter properties, untouched defaults included. A default changed later in the QML no longer reaches a machine whose file already exists.
- `adapterUpdated` fires once per property change and each one writes the file: 150 changes gave 150 writes and 150 reloads. There is no coalescing.
- It reloads its own write. One isolated change settles (one write, one reload, no loop). In a burst (two properties, three changes per millisecond) a reload of an older write lands after newer in-memory changes and sets them back: 600 changes sent, `n` ended at 598 in 3 of 3 runs, and the file kept the mixed state.

So keep a debounce and an echo guard around it, as `config/Settings.qml` does with `saveTimer` and `_lastSelfWrite`, or do not adopt it for values a slider can drive.
