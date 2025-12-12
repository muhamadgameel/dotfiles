pragma Singleton

import QtQuick
import Quickshell

import "../config" as Config

Singleton {
  id: root

  // === Current OSD State ===
  property string currentType: ""
  property var data: ({})
  property bool ready: false

  // === Signals ===
  signal showRequested

  // === Startup Guard ===
  Timer {
    id: startupTimer
    interval: 2000
    running: true
    onTriggered: root.ready = true
  }

  // === Public API ===

  // Show OSD with type and arbitrary data
  function show(type, osdData) {
    if (!Config.Config.osdEnabled || !ready)
      return;

    currentType = type;
    data = osdData ?? {};
    showRequested();
  }
}
