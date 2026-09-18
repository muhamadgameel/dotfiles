pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower

import "../config" as Config
import "../core" as Core
import "../services" as Services

/**
* Display - the laptop panel's refresh rate follows the power source
*
* 240 Hz costs about 1.9 W more than 60 Hz with the screen idle - 7.3 W against
* 5.4 W, measured at the GPU, which drives eDP-1 directly on this machine - so
* the panel drops to 60 Hz on battery and goes back on mains. Game mode keeps
* the full rate: a game on battery wants frames more than minutes.
*
* Only the internal panel is touched. Hyprland's Lua config takes a whole
* monitor line, so the current position and scale are restated with the mode
* or it resets them, and nothing is sent unless the rate actually differs -
* applying a mode blinks the screen.
*/
Singleton {
  id: root

  readonly property bool onBattery: UPower.onBattery
  readonly property bool enabled: Config.Config.lowRefreshOnBattery

  // The panel, as Hyprland describes it.
  property string output: ""
  property int fullRate: 0
  property int currentRate: 0
  property string _geometry: ""

  readonly property int targetRate: {
    if (root.fullRate <= 0)
      return 0;
    if (!root.enabled || Services.GameMode.active)
      return root.fullRate;
    return root.onBattery ? Config.Config.batteryRefreshRate : root.fullRate;
  }

  onTargetRateChanged: root.apply()

  // Re-read when an output appears or goes away: the panel's geometry, and
  // which modes it has, are only true for the setup they were read from.
  readonly property int _screenCount: Quickshell.screens.length
  on_ScreenCountChanged: _monitors.running = true

  Component.onCompleted: _monitors.running = true

  // A config reload restates the mode from monitors.lua, which pins the full
  // rate, so the panel would quietly go back to 240 Hz on battery.
  Connections {
    target: Hyprland

    function onRawEvent(event) {
      if (event.name === "configreloaded" || event.name === "monitoradded" || event.name === "monitorremoved")
        _monitors.running = true;
    }
  }

  function apply() {
    if (root.output === "" || root.targetRate <= 0 || root.targetRate === root.currentRate)
      return;

    Core.Logger.i("Display", `${root.output} to ${root.targetRate} Hz (${root.onBattery ? "battery" : "mains"})`);
    root.currentRate = root.targetRate;
    _setMode.command = ["hyprctl", "eval", `hl.monitor({ output = "${root.output}", mode = "${root._geometry}@${root.targetRate}", position = "${root._position}", scale = ${root._scale} })`];
    _setMode.running = true;
  }

  property string _position: "0x0"
  property string _scale: "1.0"

  // Hyprland is the source for the panel's modes, not the config file: the
  // config asks for a mode, the compositor reports what it got.
  Process {
    id: _monitors
    command: ["hyprctl", "-j", "monitors"]

    stdout: StdioCollector {
      onStreamFinished: {
        const monitors = JSON.parse(text);
        // The internal panel, or the only screen on a desktop.
        const panel = monitors.find(m => m.name.startsWith("eDP")) ?? monitors[0];
        if (!panel)
          return;

        root.output = panel.name;
        root._geometry = `${panel.width}x${panel.height}`;
        root._position = `${panel.x}x${panel.y}`;
        root._scale = panel.scale.toFixed(6);
        root.currentRate = Math.round(panel.refreshRate);

        // Only rates this panel offers at the size it is running.
        const rates = (panel.availableModes ?? []).filter(mode => mode.startsWith(root._geometry + "@")).map(mode => Math.round(parseFloat(mode.split("@")[1])));
        root.fullRate = rates.length > 0 ? Math.max(...rates) : root.currentRate;

        root.apply();
      }
    }
  }

  Process {
    id: _setMode

    stderr: StdioCollector {
      onStreamFinished: {
        const msg = text.trim();
        if (msg)
          Core.Logger.w("Display", `hyprctl: ${msg}`);
      }
    }
  }
}
