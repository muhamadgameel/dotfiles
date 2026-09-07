pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../core" as Core

/**
* Idle - keep the session awake on demand
*
* hypridle runs as a systemd user service here (see hypr/settings/autostart.lua),
* which makes this straightforward: stop the unit to inhibit, start it to
* release. Its own state is the source of truth, so an inhibit survives a shell
* reload and cannot get stuck on invisibly.
*
* A systemd-inhibit lock is held alongside it for anything else that honours
* logind idle inhibitors, since hypridle does not itself take one.
*/
Singleton {
  id: root

  readonly property string unit: "hypridle.service"

  // Whether the screen is currently being kept awake.
  property bool inhibited: false

  // True while a start/stop is in flight, so the toggle cannot be double-fired.
  property bool busy: false

  readonly property string statusIcon: inhibited ? "eye" : "eye-off"
  readonly property string statusText: inhibited ? "Staying awake" : "Idle timeout active"

  // === Public API ===

  function setInhibited(enabled) {
    if (busy || enabled === inhibited)
      return;

    busy = true;

    // Stopping hypridle is what actually prevents the lock/blank.
    _unitProc.command = ["systemctl", "--user", enabled ? "stop" : "start", root.unit];
    _unitProc.running = true;

    if (enabled) {
      _lockProc.running = true;
    } else {
      // Killing the systemd-inhibit process releases its lock.
      _lockProc.signal(15);
      _lockProc.running = false;
    }
  }

  function toggle() {
    setInhibited(!inhibited);
  }

  function refresh() {
    _stateProc.running = true;
  }

  // === Processes ===

  Process {
    id: _unitProc
    running: false

    onExited: exitCode => {
      root.busy = false;
      if (exitCode !== 0)
        Core.Logger.w("Idle", `systemctl exited ${exitCode}`);
      root.refresh();
    }
  }

  // Held open for as long as the inhibit lasts; logind releases the lock when
  // the process goes away.
  Process {
    id: _lockProc
    running: false
    command: ["systemd-inhibit", "--what=idle:sleep", "--who=quickshell", "--why=Idle inhibitor enabled from the bar", "--mode=block", "sleep", "infinity"]
  }

  // hypridle's unit state is the truth; never assume our own flag is right.
  Process {
    id: _stateProc
    running: true
    command: ["systemctl", "--user", "is-active", root.unit]

    stdout: StdioCollector {
      onStreamFinished: {
        const state = text.trim();
        // "inactive" means we (or the user) stopped it, so idling is inhibited.
        root.inhibited = state !== "active";
      }
    }
  }

  // Catch changes made outside the shell (systemctl from a terminal).
  Timer {
    interval: 30000
    repeat: true
    running: true
    onTriggered: {
      if (!root.busy)
        root.refresh();
    }
  }

  Component.onCompleted: Core.Logger.d("Idle", "Service started")
}
