---
name: quickshell-wayland-wheel-device-binding
description: When testing Quickshell wheel handlers: use AllDevices.
category: quickshell-development
---

On Wayland, Qt reports every wheel event—from a physical mouse or touchpad—as coming from a touchpad. A `WheelHandler` with default `acceptedDevices` (Mouse and Tablet) never fires. **Set `acceptedDevices: PointerDevice.AllDevices`**.

Offscreen testing (`QT_QPA_PLATFORM=offscreen`) cannot reveal this: synthetic events come from a Mouse device, so the default binding works in test. Always test wheel handlers against real input on the real platform, or accept all devices from the start.