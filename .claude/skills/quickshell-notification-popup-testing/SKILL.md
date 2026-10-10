---
name: quickshell-notification-popup-testing
description: When testing popups: lift delegate and use a stub service.
category: testing
---

Popups cannot render offscreen: they are panel-resident components embedded in the shell, and the real notification service would claim the session's dbus notification server. Extract the popup delegate into a standalone QML file that provides mock `notifWindow` and `notificationStack` objects, a test `ListModel` with sample notifications, and a stub notification service that records calls. This isolates the component for testing before deploying to the live shell.

See `references/notification-popup-testing.md` for the step-by-step technique.