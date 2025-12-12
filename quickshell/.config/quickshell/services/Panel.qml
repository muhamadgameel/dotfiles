pragma Singleton

import QtQuick
import Quickshell

/*
* Panel - Manages panel states (open/close)
*/
Singleton {
  id: root

  // Currently open panel reference
  property var openedPanel: null

  // Signals
  signal panelOpening(var panel)
  signal panelClosed(var panel)

  // Register that a panel is opening (closes any other open panel)
  function willOpen(panel) {
    if (openedPanel && openedPanel !== panel) {
      openedPanel.close();
    }
    openedPanel = panel;
    panelOpening(panel);
  }

  // Register that a panel has closed
  function didClose(panel) {
    if (openedPanel === panel) {
      openedPanel = null;
    }
    panelClosed(panel);
  }

  // Check if any panel is open
  function isAnyPanelOpen() {
    return openedPanel !== null;
  }

  // Close all panels
  function closeAll() {
    if (openedPanel) {
      openedPanel.close();
    }
  }
}
