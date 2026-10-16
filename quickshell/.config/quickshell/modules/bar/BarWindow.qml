pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import "../../config" as Config
import "../../core" as Core
import "../../services" as Services

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
    color: Core.Theme.transparent

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

      // A click on the bar is the bar's own: a widget toggling its panel must
      // not also be read as clicking away from it. See Panels.dismiss().
      HoverHandler {
        onHoveredChanged: Services.Panels.pointerOverBar = hovered
      }
    }

    // === Panels (built on first open, torn down after the close animation) ===

    readonly property var panelFiles: ({
        audio: "AudioPanel",
        network: "NetworkPanel",
        bluetooth: "BluetoothPanel",
        systemstats: "SystemStatsPanel",
        notifications: "NotificationCenter",
        media: "MediaPanel",
        calendar: "CalendarPanel",
        power: "PowerPanel",
        screenshot: "ScreenshotPanel",
        quicksettings: "QuickSettingsPanel",
        wallpaper: "WallpaperPanel",
        settings: "SettingsPanel"
      })

    Variants {
      model: Services.Panels.ids

      LazyLoader {
        required property string modelData

        active: Services.Panels.isLoaded(modelData, barWindow.modelData)
        source: Qt.resolvedUrl(`../panels/${barWindow.panelFiles[modelData]}.qml`)
      }
    }
  }
}
