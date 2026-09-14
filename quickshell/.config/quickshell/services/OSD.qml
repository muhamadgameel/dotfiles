pragma Singleton

import QtQuick
import Quickshell

import "../config" as Config

/**
* OSD - on-screen display controller
*
* Services push a payload here; the OSD windows (one per screen) render it.
*/
Singleton {
  id: root

  // === Current OSD State ===
  // Named `payload`, not `data`: `data` is the default-property name on every
  // QML Item, so `OSD.data` reads as a child list rather than OSD content.
  property var payload: ({})

  // === Signals ===
  signal showRequested

  // === Startup Suppression ===
  //
  // Services report their current values while they populate - PipeWire the
  // sink volume, the backlight watcher its first read. Those are not user
  // actions and must not flash an OSD at login, so nothing shows until the
  // shell has been up for settleMs.
  readonly property int settleMs: 2000
  property bool _settled: false

  Timer {
    interval: root.settleMs
    running: true
    onTriggered: root._settled = true
  }

  // === Public API ===

  /**
  * Show an OSD.
  *
  * @param osdPayload - { icon, iconColor, value, maxValue, progressColor,
  *   valueText }, as read in modules/popups/OSD.qml
  */
  function show(osdPayload) {
    if (!Config.Config.osdEnabled || !root._settled)
      return;

    payload = osdPayload ?? ({});
    showRequested();
  }
}
