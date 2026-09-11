pragma Singleton

import QtQuick
import Quickshell

import "../core" as Core

/**
* Panels - registry of which sliding panel is open, and where
*
* Exactly one panel is open at a time, on one screen. Centralising that here
* means:
*
* - Panels can be instantiated lazily. Previously every bar instantiated all of
*   them at startup, on every screen, and each created two PanelWindows whether
*   or not it was ever opened.
* - Opening one closes any other, without panels having to know about each other.
* - IPC and global shortcuts have a single entry point, instead of the bar's
*   per-panel `signal xClicked` plumbing.
*
* Panel ids are the plain names in modules/panels (see Panels.ids below).
*/
Singleton {
  id: root

  // Known panel ids. Kept here so IPC can validate a requested name and report
  // what is available rather than silently doing nothing.
  readonly property var ids: ["audio", "network", "bluetooth", "systemstats", "notifications", "media", "calendar", "power", "screenshot", "quicksettings"]

  // Currently open panel id, or "" when none is open.
  property string openPanel: ""

  // The screen the open panel belongs to.
  property var targetScreen: null

  // Panel id whose window should still exist. Lags openPanel until the panel
  // reports that its close animation has finished (release()), so it is not
  // torn down mid-slide.
  property string retainedPanel: ""

  readonly property bool anyOpen: openPanel !== ""

  // === Queries used by the bar and by SlidingPanel ===

  /**
  * Whether this panel should be *visible* on this screen.
  */
  function isOpen(id, screen) {
    return openPanel === id && (targetScreen === null || targetScreen === screen);
  }

  /**
  * Whether this panel should be *instantiated* on this screen. True while it is
  * open and for the duration of its close animation.
  */
  function isLoaded(id, screen) {
    if (targetScreen !== null && targetScreen !== screen)
      return false;
    return openPanel === id || retainedPanel === id;
  }

  // === Commands ===

  function open(id, screen) {
    if (!ids.includes(id)) {
      Core.Logger.w("Panels", `Unknown panel: ${id}`);
      return false;
    }

    if (screen !== undefined && screen !== null)
      targetScreen = screen;

    openPanel = id;
    return true;
  }

  function close() {
    openPanel = "";
  }

  /**
  * Called by a panel once its window has actually hidden, so it can be torn
  * down. Ignored if that panel has been reopened, or another one has taken over.
  */
  function release(id) {
    if (retainedPanel === id && openPanel !== id) {
      retainTimer.stop();
      retainedPanel = "";
    }
  }

  function toggle(id, screen) {
    // Re-triggering the open panel from the same screen closes it; from a
    // different screen it moves there instead.
    if (openPanel === id && (screen === undefined || screen === null || targetScreen === screen)) {
      close();
      return true;
    }
    return open(id, screen);
  }

  onOpenPanelChanged: {
    if (openPanel !== "") {
      retainTimer.stop();
      retainedPanel = openPanel;
    } else {
      retainTimer.restart();
    }
  }

  // Fallback only: normally the panel calls release() the moment its window
  // hides. This covers a panel that can never report back - its screen was
  // unplugged mid-close, say - so retainedPanel cannot stick, and Screenshot
  // (which waits on it) cannot hang. Generous, since it is never the fast path.
  Timer {
    id: retainTimer
    interval: Core.Style.animSlow * 4
    repeat: false
    onTriggered: root.retainedPanel = ""
  }
}
