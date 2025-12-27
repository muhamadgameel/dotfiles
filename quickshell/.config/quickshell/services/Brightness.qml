pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../config" as Config
import "../services" as Services

/**
* Brightness - Service for controlling display brightness
*
* Uses brightnessctl to manage backlight brightness.
* Monitors /sys/class/backlight for external changes (hardware keys, etc).
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
  property int maxBrightness: 100     // Maximum raw value
  property int currentBrightness: 0   // Current raw value
  property bool ready: false          // Whether brightness control is available
  property string device: ""          // Backlight device name

  // === Configuration ===
  readonly property real stepSize: 0.05       // Step for increase/decrease (5%)
  readonly property real minBrightness: 0.01  // Minimum (1%) to prevent black screen

  // === Private Properties ===
  property real _queuedBrightness: NaN
  property bool _settingBrightness: false

  // === Debounce Timer ===
  // Prevents command spam during rapid scroll/slider adjustments
  Timer {
    id: debounceTimer
    interval: 50
    repeat: false
    onTriggered: {
      if (!isNaN(root._queuedBrightness)) {
        root._applyBrightness(root._queuedBrightness);
        root._queuedBrightness = NaN;
      }
    }
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
    if (!ready)
      return;
    set(brightness + stepSize);
  }

  /**
  * Decrease brightness by step
  */
  function decrease() {
    if (!ready)
      return;
    set(brightness - stepSize);
  }

  /**
  * Set brightness to specific value
  * @param value - Brightness value (0.0 - 1.0)
  */
  function set(value) {
    if (!ready)
      return;
    value = Math.max(minBrightness, Math.min(1.0, value));
    _setBrightnessDebounced(value);
  }

  /**
  * Set brightness to specific percentage
  * @param percent - Percentage (0 - 100)
  */
  function setPercent(percent) {
    set(percent / 100.0);
  }

  // === Private Functions ===

  function _setBrightnessDebounced(value) {
    root._queuedBrightness = value;
    debounceTimer.restart();
  }

  function _applyBrightness(value) {
    var percentage = Math.round(value * 100);
    root._settingBrightness = true;
    root.brightness = value;
    root._showOSD();
    _setProc.command = ["brightnessctl", "s", percentage + "%"];
    _setProc.running = true;
  }

  function _showOSD() {
    Services.OSD.show("progressRow", {
      iconName: getIcon(brightness),
      value: brightness,
      maxValue: 1.0,
      iconColor: Config.Theme.text,
      progressColor: Config.Theme.accent
    });
  }

  function _refreshFromSystem() {
    if (!ready || _settingBrightness)
      return;
    _refreshProc.running = true;
  }

  // === Processes ===

  // Set brightness via brightnessctl
  Process {
    id: _setProc
    running: false
    onExited: {
      root._settingBrightness = false;
    }
  }

  // Initialize: get device info and current brightness
  Process {
    id: _initProc
    running: true
    command: ["sh", "-c", "brightnessctl -m | head -n1"]
    stdout: StdioCollector {
      onStreamFinished: {
        // brightnessctl -m output: device,class,current,percentage,max
        // Example: intel_backlight,backlight,15000,100%,15000
        var output = text.trim();
        if (output === "") {
          root.ready = false;
          console.log("Brightness: No backlight device found");
          return;
        }

        var parts = output.split(",");
        if (parts.length >= 5) {
          root.device = parts[0];
          root.currentBrightness = parseInt(parts[2]);
          root.maxBrightness = parseInt(parts[4]);
          if (root.maxBrightness > 0) {
            root.brightness = root.currentBrightness / root.maxBrightness;
            root.ready = true;
            console.log("Brightness: Initialized device '" + root.device + "' at " + Math.round(root.brightness * 100) + "%");
          }
        }
      }
    }
  }

  // Refresh brightness from system (for external changes)
  Process {
    id: _refreshProc
    running: false
    command: ["sh", "-c", "brightnessctl -m | head -n1"]
    stdout: StdioCollector {
      onStreamFinished: {
        var output = text.trim();
        if (output === "")
          return;

        var parts = output.split(",");
        if (parts.length >= 5) {
          var current = parseInt(parts[2]);
          var max = parseInt(parts[4]);
          if (max > 0) {
            var newBrightness = current / max;
            // Only update if significantly different (avoids feedback loops)
            if (Math.abs(newBrightness - root.brightness) > 0.01) {
              root.currentBrightness = current;
              root.brightness = newBrightness;
              root._showOSD();
            }
          }
        }
      }
    }
  }

  // === File Watcher ===
  // Watch for external brightness changes (hardware keys, other apps)
  FileView {
    id: brightnessWatcher
    path: root.device !== "" ? "/sys/class/backlight/" + root.device + "/brightness" : ""
    watchChanges: path !== ""

    onFileChanged: {
      // Use Qt.callLater to avoid reading stale values
      Qt.callLater(root._refreshFromSystem);
    }
  }
}
