pragma Singleton

import QtQuick
import Quickshell

import "../core" as Core

/**
* ChargeLimit - UPower's battery charge limit
*
* Lenovo's conservation mode on this laptop. Through busctl, as in setup.sh:
* Quickshell's UPower module does not expose it.
*/
Singleton {
  id: root

  property bool supported: false
  property bool active: false
  readonly property bool busy: _write.running

  readonly property var _bus: ["org.freedesktop.UPower", "/org/freedesktop/UPower/devices/battery_BAT0", "org.freedesktop.UPower.Device"]

  function refresh() {
    _read.running = true;
  }

  function toggle() {
    _write.command = ["busctl", "call"].concat(root._bus, ["EnableChargeThreshold", "b", String(!root.active)]);
    _write.running = true;
  }

  Core.Command {
    id: _read

    command: ["busctl", "get-property"].concat(root._bus, ["ChargeThresholdSupported", "ChargeThresholdEnabled"])

    onDone: (code, out) => {
      const values = out.trim().split("\n");
      root.supported = values[0] === "b true";
      root.active = values[1] === "b true";
    }
  }

  Core.Command {
    id: _write

    tag: "ChargeLimit"
    label: "charge limit"

    onDone: _read.running = true
  }
}
