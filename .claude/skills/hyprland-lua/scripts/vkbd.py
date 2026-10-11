#!/usr/bin/env python3
"""vkbd.py - press keys through a virtual keyboard (/dev/uinput), as real input.

    vkbd.py SUPER+F2          press SUPER then F2, hold 60 ms, release
    vkbd.py 240 400           hold key 240 for 400 ms

Keys are evdev codes (/usr/include/linux/input-event-codes.h) or a name from NAMES.
A key no bind takes goes to the focused window, so press only what is bound or types
nothing: 240 (KEY_UNKNOWN) is inert everywhere.

As a module: `from vkbd import Kbd`, then `k = Kbd("name")`, `k.key(code, 1)`,
`k.key(code, 0)`, `k.close()`. Wait about two seconds after creating one: Hyprland
needs that long to pick the device up.
"""
import fcntl
import os
import struct
import sys
import time

UI_SET_EVBIT, UI_SET_KEYBIT, UI_DEV_CREATE, UI_DEV_DESTROY = 0x40045564, 0x40045565, 0x5501, 0x5502
EV_SYN, EV_KEY = 0, 1
NAMES = {"SUPER": 125, "CTRL": 29, "SHIFT": 42, "ALT": 56, "PRINT": 99, "RETURN": 28, "ESCAPE": 1, "SPACE": 57}
NAMES.update({f"F{n}": 58 + n for n in range(1, 11)}, F11=87, F12=88)


class Kbd:
    def __init__(self, name="vkbd-test-keyboard"):
        self.fd = os.open("/dev/uinput", os.O_WRONLY | os.O_NONBLOCK)
        fcntl.ioctl(self.fd, UI_SET_EVBIT, EV_KEY)
        fcntl.ioctl(self.fd, UI_SET_EVBIT, EV_SYN)
        # Every ordinary key, so udev tags the device as a keyboard.
        for code in range(1, 249):
            fcntl.ioctl(self.fd, UI_SET_KEYBIT, code)
        os.write(self.fd, struct.pack("80sHHHHi" + "i" * 256, name.encode(), 3, 0x1234, 0x5678, 1, 0, *([0] * 256)))
        fcntl.ioctl(self.fd, UI_DEV_CREATE)

    def event(self, kind, code, value):
        os.write(self.fd, struct.pack("llHHi", 0, 0, kind, code, value))

    def sync(self):
        self.event(EV_SYN, 0, 0)

    def key(self, code, value):
        """value 1 presses, 0 releases; each call is its own report."""
        self.event(EV_KEY, code, value)
        self.sync()

    def close(self):
        fcntl.ioctl(self.fd, UI_DEV_DESTROY)
        os.close(self.fd)


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    codes = [NAMES[k.upper()] if k.upper() in NAMES else int(k) for k in sys.argv[1].split("+")]
    hold = int(sys.argv[2]) / 1000 if len(sys.argv) > 2 else 0.06
    kbd = Kbd()
    time.sleep(2)
    try:
        for code in codes:
            kbd.key(code, 1)
            time.sleep(0.03)
        time.sleep(hold)
        for code in reversed(codes):
            kbd.key(code, 0)
        time.sleep(0.2)
    finally:
        kbd.close()


if __name__ == "__main__":
    main()
