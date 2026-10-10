---
name: quickshell-wheel-notch-vs-swipe-detection
description: When testing Quickshell wheel input: check event.phase.
category: quickshell-development
---

Wheel notches and touchpad swipes both arrive in the wheel event stream on Wayland. A single notch has `event.phase === Qt.NoScrollPhase` (value 0); a two-finger swipe arrives as ~25 events with `event.phase` cycling through 1 (began), 2 (ongoing), 3 (ended). **Filter notches only:**

```qml
if (event.phase !== Qt.NoScrollPhase) return;
```

Also filter horizontal-only events: `if (event.angleDelta.y === 0) return;`