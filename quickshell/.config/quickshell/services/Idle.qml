pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../core" as Core

/**
* Idle - keep the session awake on demand
*
* Holds a logind idle inhibitor while enabled. hypridle keeps running and honours
* it (ignore_systemd_inhibit = false), so dimming, locking and screen-off pause
* while locking before suspend still works.
*
* The lock waits on the shell's own pid (`tail --pid`), not `sleep infinity`, so it
* dies with the shell however the shell dies: Quickshell does not kill its children
* when it is terminated. `exec` makes systemd-inhibit replace the shell, so $PPID
* is still the quickshell pid.
*/
Singleton {
  id: root

  readonly property bool inhibited: _state.inhibited
  readonly property bool busy: false
  readonly property string statusIcon: inhibited ? "eye" : "eye-off"

  // === Public API ===

  function setInhibited(enabled) {
    _state.inhibited = enabled;
  }

  function toggle() {
    setInhibited(!inhibited);
  }

  // Survives hot reloads. A restart starts released: the lock died with the old
  // process.
  PersistentProperties {
    id: _state
    reloadableId: "idle"

    property bool inhibited: false
  }

  Process {
    running: root.inhibited
    command: ["sh", "-c", "exec systemd-inhibit --what=idle --who=quickshell --why='Stay Awake is on' --mode=block tail --pid=\"$PPID\" -f /dev/null"]

    stderr: StdioCollector {
      onStreamFinished: {
        const msg = text.trim();
        if (msg)
          Core.Logger.w("Idle", `systemd-inhibit: ${msg}`);
      }
    }
  }

  Component.onCompleted: Core.Logger.d("Idle", "Service started")
}
