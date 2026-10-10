---
name: quickshell-testing-stub-services
description: When testing QML components: use stub services, no IPC.
category: testing
---

A stub service is a minimal Singleton replacement that has the same public properties and methods as the real service but makes no external calls. Stubs keep probe shells isolated from the live shell.

Patterns:

**Notification stub:** `services/Notification.qml` with empty `ListModel activeList`, no-op methods (`pauseTimeout`, `resumeTimeout`, `dismiss`, `removeFromHistory`, `invokeAction`), and no claim on `org.freedesktop.Notifications` D-Bus name. The live shell retains the real service.

**Wallpaper stub:** `services/Wallpaper.qml` returns a fixed list of real files, implements `url()` and `name()` to work with real thumbnails, makes no hyprpaper IPC calls. The live shell's hourly rotation continues uninterrupted.

**Generic pattern:** Expose exactly the properties and methods the component under test reads. Implement only enough to prevent crashes (return fixed constants, empty lists, no-ops). Never touch D-Bus, IPC, filesystem writes, or external state.

Place stubs at the same path as the real service in the probe config (e.g., `services/ServiceName.qml`); they override the system services for that instance only.