---
name: quickshell-binding-restoremode-singleton
description: When Bindings share state: use restoreMode: RestoreNone.
category: quickshell-development
---

When multiple QML components write to the same singleton via `Binding { when: gate }`, the default restore behavior causes race conditions: on close, a Binding restores the value it found when it activated. Panel A opens (width 360), panel B opens (width 420), panel A closes (restores 360) — the shell cannot control the order.

Add `restoreMode: Binding.RestoreNone` to all Bindings writing to the shared property. On close, they leave the value alone; the next opener overwrites it.

Use case: each panel's `Binding { target: Services.Panels; property: "openPanelWidth"; value: root.panelWidth; when: root.isOpen; restoreMode: Binding.RestoreNone }` writes when it opens. Without `RestoreNone`, a closed panel would restore its old width even if another panel is already showing.