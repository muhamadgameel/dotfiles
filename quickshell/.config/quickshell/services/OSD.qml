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
  property string currentType: ""

  // Named `payload`, not `data`: `data` is the default-property name on every
  // QML Item, so `OSD.data` reads as a child list rather than OSD content.
  property var payload: ({})

  // === Signals ===
  signal showRequested

  // === Startup Suppression ===
  //
  // Services emit change signals while populating their initial state
  // (PipeWire reporting the current sink volume, brightnessctl reporting the
  // current backlight level). Those are not user actions and must not flash an
  // OSD at login.
  property var _armed: ({})

  /**
  * Mark a source as having produced a value. The first call returns false -
  * that event is initial state - and every later call returns true.
  *
  * @param source - Stable id for the calling service, e.g. "volume"
  * @returns whether the source may show an OSD
  */
  function arm(source) {
    if (_armed[source])
      return true;
    _armed[source] = true;
    return false;
  }

  // === Public API ===

  /**
  * Show an OSD.
  *
  * @param type - Layout id, resolved by OSDLayouts.getComponent()
  * @param osdPayload - Layout-specific values
  * @param source - Optional source id for startup suppression (see arm())
  */
  function show(type, osdPayload, source) {
    if (!Config.Config.osdEnabled)
      return;

    // First value from this source is initial state, not a user action.
    if (source !== undefined && !arm(source))
      return;

    currentType = type;
    payload = osdPayload ?? ({});
    showRequested();
  }
}
