pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../config" as Config
import "../core" as Core
import "../services" as Services

/**
* NightLight - warms the screen after dark
*
* hyprsunset owns the colour transform; this owns when it applies. It runs from
* the unit in the hypr package, which starts it with --identity, so a session
* without the shell is never left tinted.
*
* Whether the filter is on is kept here rather than read back: hyprsunset keeps
* its last temperature across `identity`, so asking it cannot tell "off" from
* "on, at that temperature".
*
* The schedule writes the same setting the toggle does, so turning it off in
* the evening holds until the next boundary instead of being undone a minute
* later.
*
* This is a transform over the whole output - it stacks with brightness rather
* than replacing it, and game mode takes it off.
*/
Singleton {
  id: root

  // === State ===
  readonly property bool enabled: Config.Config.nightLight
  readonly property int temperature: Config.Config.nightLightTemperature

  // 6500K is daylight, where the transform is nearly identity; below 2500 the
  // screen is too orange to read on.
  readonly property int temperatureMin: 2500
  readonly property int temperatureMax: 6500

  readonly property bool suspended: Services.GameMode.active

  // Cleared when hyprctl cannot reach the daemon, which is how the control
  // knows to stay hidden on a session where the unit was never enabled.
  property bool available: true

  readonly property bool active: root.enabled && root.available && !root.suspended

  readonly property string statusText: {
    if (!root.available)
      return "hyprsunset is not running";
    const window = root.scheduled ? `, scheduled ${Config.Config.nightLightStart}-${Config.Config.nightLightEnd}` : "";
    if (root.enabled && root.suspended)
      return `held off by game mode${window}`;
    return (root.enabled ? `on at ${root.temperature}K` : "off") + window;
  }

  // === Public API ===

  function toggle() {
    Config.Config.setNightLight(!root.enabled);
    return root.enabled;
  }

  function setEnabled(on) {
    Config.Config.setNightLight(on);
  }

  function setTemperature(kelvin) {
    Config.Config.setNightLightTemperature(Math.round(Core.Utils.clamp(kelvin, root.temperatureMin, root.temperatureMax)));
  }

  function setSchedule(on) {
    Config.Config.setNightLightAuto(on);
  }

  // Put the daemon into the state this service says it should be in.
  function apply() {
    root._follow();
    commit.restart();
  }

  // === Schedule ===
  readonly property bool scheduled: Config.Config.nightLightAuto

  readonly property int _from: root._minuteOf(Config.Config.nightLightStart)
  readonly property int _to: root._minuteOf(Config.Config.nightLightEnd)

  function _minuteOf(hhmm) {
    const parts = String(hhmm).split(":");
    return Core.Utils.clamp(parseInt(parts[0]) || 0, 0, 23) * 60 + Core.Utils.clamp(parseInt(parts[1]) || 0, 0, 59);
  }

  // The window runs over midnight whenever it starts after it ends.
  readonly property bool _inWindow: {
    const now = Services.Time.minuteOfDay;
    return root._from <= root._to ? now >= root._from && now < root._to : now >= root._from || now < root._to;
  }

  function _follow() {
    if (root.scheduled && root.enabled !== root._inWindow)
      root.setEnabled(root._inWindow);
  }

  on_InWindowChanged: root._follow()
  onScheduledChanged: root._follow()

  // === Applying ===
  readonly property var _request: root.active ? ["temperature", String(root.temperature)] : ["identity"]

  // Coalesces a slider drag into one call every few frames rather than one per
  // pixel of travel.
  Timer {
    id: commit

    interval: Core.Style.animFaster
    onTriggered: {
      if (hyprctl.running) {
        commit.restart();
        return;
      }
      hyprctl.command = ["hyprctl", "hyprsunset"].concat(root._request);
      hyprctl.running = true;
    }
  }

  on_RequestChanged: commit.restart()

  // The daemon and the shell are started by the same target with nothing
  // ordering them, so the first call can arrive before hyprsunset is listening.
  // Give it a few seconds before believing it is absent.
  property int _retries: 0

  Timer {
    id: retry

    interval: 2000
    repeat: true
    running: !root.available && root._retries < 5
    onTriggered: {
      root._retries++;
      commit.restart();
    }
  }

  Component.onCompleted: root.apply()

  // Re-checked when the panel holding the control opens, so enabling the unit
  // is noticed without restarting the shell.
  Connections {
    target: Services.Panels

    function onOpenPanelChanged() {
      if (!root.available && Services.Panels.openPanel === "quicksettings")
        commit.restart();
    }
  }

  Process {
    id: hyprctl

    // 3 is hyprctl failing to reach the daemon's socket.
    onExited: code => {
      const reachable = code !== 3;
      if (reachable !== root.available) {
        root.available = reachable;
        Core.Logger.i("NightLight", reachable ? "hyprsunset reachable" : "hyprsunset is not running");
      }
      if (reachable)
        root._retries = 0;
      if (code !== 0 && reachable)
        Core.Logger.w("NightLight", `hyprctl hyprsunset exited ${code}`);
    }
  }
}
