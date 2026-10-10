---
name: hyprland-uinput-keybind-testing
category: testing
description: When testing Hyprland binds with fallback: use /dev/uinput.
---

Test Hyprland keybinds without real keypresses using `/dev/uinput` to create a virtual keyboard:

- Open `/dev/uinput` with `os.O_WRONLY | os.O_NONBLOCK`
- Populate `UI_SET_EVBIT` and `UI_SET_KEYBIT` for event type and key codes
- Write struct defining device name, type, vendor, product
- Call `UI_DEV_CREATE` ioctl to register the device
- Emit key press/release events as struct writes
- Tear down with `UI_DEV_DESTROY` ioctl

Advantage: test fallback behavior (e.g., shell-down path) by stopping the shell mid-test, then re-trigger the keybind. Real input is unaffected; test can inject multiple keys without manual intervention.

Example: test screenshot keybind with shell running and stopped to verify grim fallback works.