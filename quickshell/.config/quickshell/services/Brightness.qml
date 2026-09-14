pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../core" as Core
import "../services" as Services

/**
* Brightness - Service for controlling display brightness
*
* brightnessctl writes the value; reads come straight from
* /sys/class/backlight/<device>/brightness via the FileView that is already
* watching it.
*
* Usage:
*   Services.Brightness.brightness    // Current value (0.0 - 1.0)
*   Services.Brightness.ready         // Whether brightness control is available
*   Services.Brightness.increase()    // Increase by step
*   Services.Brightness.decrease()    // Decrease by step
*   Services.Brightness.set(0.5)      // Set to 50%
*/
Singleton {
  id: root

  // === Public Properties ===
  property real brightness: 0.0       // Current brightness (0.0 - 1.0)
  property int maxBrightness: 0       // Maximum raw value
  property int currentBrightness: 0   // Current raw value
  property bool ready: false          // Whether brightness control is available
  property string device: ""          // Backlight device name

  // === Configuration ===
  readonly property real stepSize: 0.05       // Step for increase/decrease (5%)
  readonly property real minBrightness: 0.01  // Minimum (1%) to prevent black screen

  // How long after our own write to ignore inotify events, so the change we
  // just made does not come back as an "external change" and show a second OSD.
  readonly property int selfWriteGraceMs: 400

  // === Private Properties ===
  property real _queuedBrightness: NaN

  // The level the last request asked for, even while it is still queued.
  readonly property real requestedBrightness: isNaN(_queuedBrightness) ? brightness : _queuedBrightness
  property real _lastSelfWrite: 0

  // === Debounce Timer ===
  // Prevents command spam during rapid scroll/slider adjustments
  Timer {
    id: debounceTimer
    interval: 50
    repeat: false
    onTriggered: root._flushBrightness()
  }

  // === Public API ===

  /**
  * Get brightness icon based on level
  * @param value - Optional brightness value (uses current if not provided)
  * @returns Icon name string
  */
  function getIcon(value) {
    if (value === undefined)
      value = root.brightness;
    if (value < 0.33)
      return "brightness-low";
    if (value < 0.66)
      return "brightness-medium";
    return "brightness-high";
  }

  /**
  * Increase brightness by step
  */
  function increase() {
    if (!root.ready)
      return;
    set(root.requestedBrightness + root.stepSize);
  }

  /**
  * Decrease brightness by step
  */
  function decrease() {
    if (!root.ready)
      return;
    set(root.requestedBrightness - root.stepSize);
  }

  /**
  * Set brightness to specific value
  * @param value - Brightness value (0.0 - 1.0)
  */
  function set(value) {
    if (!root.ready || !isFinite(value))
      return;
    root._queuedBrightness = Core.Utils.clamp(value, root.minBrightness, 1.0);
    debounceTimer.restart();
  }

  /**
  * Set brightness to specific percentage
  * @param percent - Percentage (0 - 100)
  */
  function setPercent(percent) {
    set(percent / 100.0);
  }

  // === Private Functions ===

  function _flushBrightness() {
    // Process.running = true does not launch a second command while one is
    // active. Keep the latest target queued until that write finishes.
    if (_setProc.running || isNaN(root._queuedBrightness))
      return;
    const value = root._queuedBrightness;
    root._queuedBrightness = NaN;
    root._applyBrightness(value);
  }

  function _applyBrightness(value) {
    root._lastSelfWrite = Date.now();
    root.brightness = value;
    root.currentBrightness = Math.round(value * root.maxBrightness);
    root._showOSD();

    _setProc.command = ["brightnessctl", "-c", "backlight", "-d", root.device, "-q", "s", Math.round(value * 100) + "%"];
    _setProc.running = true;
  }

  function _showOSD() {
    // Quick settings already shows the level, and the OSD would cover it.
    if (Services.Panels.openPanel === "quicksettings")
      return;

    Services.OSD.show({
      icon: getIcon(brightness),
      value: brightness,
      maxValue: 1.0,
      iconColor: Core.Theme.text,
      progressColor: Core.Theme.accent
    });
  }

  // Read the value the watcher already holds - no process spawn.
  function _refreshFromWatcher() {
    if (!root.ready || root.maxBrightness <= 0 || _setProc.running || !isNaN(root._queuedBrightness))
      return;

    // Our own write, echoed back by inotify.
    if (Date.now() - root._lastSelfWrite < root.selfWriteGraceMs)
      return;

    const raw = parseInt(brightnessWatcher.text().trim(), 10);
    if (isNaN(raw))
      return;

    const value = raw / root.maxBrightness;
    const changed = Math.abs(value - root.brightness) >= 0.005;
    root.currentBrightness = raw;
    root.brightness = value;
    if (changed)
      root._showOSD();
  }

  // === Processes ===

  // Set brightness via brightnessctl. `command` is set by _applyBrightness().
  Process {
    id: _setProc
    running: false

    onRunningChanged: {
      if (running)
        return;
      if (!isNaN(root._queuedBrightness)) {
        if (!debounceTimer.running)
          debounceTimer.restart();
      } else {
        // Reconcile rounded values and failed writes with the actual device,
        // even when its inotify event arrived during our self-write grace.
        root._lastSelfWrite = 0;
        brightnessWatcher.reload();
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        const msg = text.trim();
        if (msg)
          Core.Logger.w("Brightness", msg);
      }
    }
  }

  // Initialize: resolve the device and its range.
  // -c backlight restricts the search to display backlights, so a keyboard LED
  // is never picked up as "the" brightness device.
  Process {
    id: _initProc
    running: true
    command: ["brightnessctl", "-c", "backlight", "-m"]

    stdout: StdioCollector {
      onStreamFinished: {
        // brightnessctl -m output: device,class,current,percentage,max
        // Example: intel_backlight,backlight,15000,100%,15000
        const line = text.trim().split("\n")[0] ?? "";
        if (line === "") {
          root.ready = false;
          Core.Logger.w("Brightness", "No backlight device found");
          return;
        }

        const parts = line.split(",");
        if (parts.length < 5) {
          Core.Logger.w("Brightness", `Unexpected brightnessctl output: ${line}`);
          return;
        }

        const current = parseInt(parts[2], 10);
        const max = parseInt(parts[4], 10);
        if (isNaN(current) || isNaN(max) || max <= 0) {
          Core.Logger.w("Brightness", `Unusable brightness range: ${line}`);
          return;
        }

        root.device = parts[0];
        root.currentBrightness = current;
        root.maxBrightness = max;
        root.brightness = current / max;
        root.ready = true;
        Core.Logger.i("Brightness", `Device '${root.device}' at ${Math.round(root.brightness * 100)}%`);
      }
    }
  }

  // === File Watcher ===
  // Picks up external changes (hardware keys, other apps). The FileView holds
  // the contents itself, so onLoaded reads them directly.
  FileView {
    id: brightnessWatcher
    path: root.device !== "" ? `/sys/class/backlight/${root.device}/brightness` : ""
    watchChanges: path !== ""
    printErrors: false

    onFileChanged: reload()

    onLoaded: Qt.callLater(root._refreshFromWatcher)
  }
}
