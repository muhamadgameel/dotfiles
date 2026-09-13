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
*
* The lock follows hypridle's state rather than the toggle. It lives in a child
* process, so a shell reload used to kill it while the state - read back from
* hypridle - still said "inhibited": staying awake as far as the bar showed, with
* no logind lock held.
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

    // Stopping hypridle is what actually prevents the lock/blank. The logind
    // lock is brought in line once the new state is read back (_syncLock).
    _unitProc.command = ["systemctl", "--user", enabled ? "stop" : "start", root.unit];
    _unitProc.running = true;
  }

  function toggle() {
    setInhibited(!inhibited);
  }

  function refresh() {
    _stateProc.running = true;
  }

  // Hold the logind lock exactly while inhibited. Stopping the process is what
  // releases it.
  function _syncLock() {
    if (root.inhibited && !_lockProc.running)
      _lockProc.running = true;
    else if (!root.inhibited && _lockProc.running)
      _lockProc.running = false;
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
  //
  // It waits on the shell's own pid (`tail --pid`), not `sleep infinity`, so the
  // lock dies with the shell however the shell dies. Quickshell does not kill
  // its children when it is terminated: with `sleep infinity`, every `pkill qs`
  // left a lock behind that blocked system sleep with nothing to release it.
  // One such orphan was found holding sleep off for over a day. `exec` makes
  // systemd-inhibit replace the shell, so $PPID is still the quickshell pid.
  Process {
    id: _lockProc
    running: false
    command: ["sh", "-c", "exec systemd-inhibit --what=idle:sleep --who=quickshell --why='Idle inhibitor enabled from the bar' --mode=block tail --pid=\"$PPID\" -f /dev/null"]
  }

  // hypridle's unit state is the truth; never assume our own flag is right.
  Process {
    id: _stateProc
    running: true
    command: ["systemctl", "--user", "is-active", root.unit]

    stdout: StdioCollector {
      onStreamFinished: {
        const state = text.trim();

        // Only a cleanly stopped unit means someone chose to stay awake. This
        // was `state !== "active"`, which also read a crashed ("failed") or
        // missing unit as "Staying awake" - a choice nobody made.
        root.inhibited = state === "inactive";

        if (state !== "active" && state !== "inactive")
          Core.Logger.w("Idle", `${root.unit} is ${state || "not found"}: screen dim and lock are not running`);

        root._syncLock();
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
