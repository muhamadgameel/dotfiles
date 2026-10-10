---
name: quickshell-uinput-probe-hover-gate
description: When injecting uinput pointer events: gate by HoverHandler.
category: quickshell-development
---

Virtual pointer events via uinput route to whichever window is under the cursor at injection time. If the probe block has no pointer focus, injected events go to the window beneath it (e.g., your editor). **Add a `HoverHandler` to the probe and check `hovered` before injecting.**

```qml
HoverHandler { }
// In the injection function:
if (!root.hovered) return;
// Then inject via uinput
```

Alternatively, warp the real cursor into the probe's bounds before injection and back after, but the hover gate is cleaner.