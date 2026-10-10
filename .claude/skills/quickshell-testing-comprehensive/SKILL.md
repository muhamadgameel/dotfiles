---
name: quickshell-testing-comprehensive
description: When testing Quickshell: use stubs, before/after compare.
category: testing
---

Test QML widget changes by running the same test against both today's code and the candidate, using offscreen rendering and real mouse events.

Stub all affected services (Audio, Network, Brightness, Media, Bluetooth, Notification, GameMode, and modules/ipc/Targets.qml) to record calls only; mark each `isStub: true`. Start offscreen shell (`QT_QPA_PLATFORM=offscreen`). Refuse to click unless all stubs report themselves. Click each control left/right/middle via `qs ipc call probe click`, record what was called. Compare: every used button must give the same call both times; unused buttons now ignored are intended changes. Before and after, read real state (volume, brightness, Wi-Fi, workspace, do-not-disturb): must be identical.

See p718 scratchpad (2026-10-08) for build.py and drive.py templates.