pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core
import "../../services" as Services
import "../panels" as Panels

/**
* BarWindow - the bar window for each screen, plus that screen's panels
*
* One PanelWindow per output, reserving its own height as an exclusive zone so
* tiled windows do not sit underneath it.
*
* Panels are built on demand. Instantiating all of them up front created a
* panel window per panel per monitor before anything had been opened; each
* LazyLoader below is active only while its panel is open on this screen, plus
* the length of the close animation (see services/Panels.qml).
*
* The bar itself only reports what was clicked - the routing to a panel happens
* here, so the bar contents do not need to know that panels exist.
*/
Variants {
  id: root

  model: Quickshell.screens

  PanelWindow {
    id: barWindow

    required property var modelData

    screen: modelData

    anchors {
      top: Config.Config.barPosition === "top"
      bottom: Config.Config.barPosition === "bottom"
      left: true
      right: true
    }

    readonly property bool atTop: Config.Config.barPosition === "top"

    implicitHeight: Core.Style.barHeight
    color: Config.Theme.transparent

    WlrLayershell.namespace: "quickshell-bar"
    WlrLayershell.layer: WlrLayer.Top
    exclusiveZone: Core.Style.barHeight

    // Bar Component
    Bar {
      id: bar

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: barWindow.atTop ? parent.top : undefined
      anchors.bottom: barWindow.atTop ? undefined : parent.bottom
      height: Core.Style.barHeight

      screen: barWindow.modelData

      onPanelRequested: panelId => Services.Panels.toggle(panelId, barWindow.modelData)
    }

    // === Panels (built on first open, torn down after the close animation) ===

    LazyLoader {
      active: Services.Panels.isLoaded("audio", barWindow.modelData)

      component: Panels.AudioPanel {
        parentWindow: barWindow
      }
    }

    LazyLoader {
      active: Services.Panels.isLoaded("network", barWindow.modelData)

      component: Panels.NetworkPanel {
        parentWindow: barWindow
      }
    }

    LazyLoader {
      active: Services.Panels.isLoaded("bluetooth", barWindow.modelData)

      component: Panels.BluetoothPanel {
        parentWindow: barWindow
      }
    }

    LazyLoader {
      active: Services.Panels.isLoaded("systemstats", barWindow.modelData)

      component: Panels.SystemStatsPanel {
        parentWindow: barWindow
      }
    }

    LazyLoader {
      active: Services.Panels.isLoaded("notifications", barWindow.modelData)

      component: Panels.NotificationCenter {
        parentWindow: barWindow
      }
    }

    LazyLoader {
      active: Services.Panels.isLoaded("media", barWindow.modelData)

      component: Panels.MediaPanel {
        parentWindow: barWindow
      }
    }

    LazyLoader {
      active: Services.Panels.isLoaded("calendar", barWindow.modelData)

      component: Panels.CalendarPanel {
        parentWindow: barWindow
      }
    }

    LazyLoader {
      active: Services.Panels.isLoaded("power", barWindow.modelData)

      component: Panels.PowerPanel {
        parentWindow: barWindow
      }
    }

    LazyLoader {
      active: Services.Panels.isLoaded("screenshot", barWindow.modelData)

      component: Panels.ScreenshotPanel {
        parentWindow: barWindow
      }
    }

    LazyLoader {
      active: Services.Panels.isLoaded("quicksettings", barWindow.modelData)

      component: Panels.QuickSettingsPanel {
        parentWindow: barWindow
      }
    }
  }
}
