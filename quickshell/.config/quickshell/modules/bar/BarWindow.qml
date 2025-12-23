import QtQuick
import Quickshell
import Quickshell.Wayland

import "../../config" as Config
import "../../core" as Core
import "../../modules/panels" as Panels

/*
* BarWindow - Encapsulates bar PanelWindow setup for each screen
*/
Variants {
  id: root

  model: Quickshell.screens

  PanelWindow {
    id: barWindow

    required property var modelData
    property var screen: modelData

    anchors {
      top: Config.Config.barPosition === "top"
      bottom: Config.Config.barPosition === "bottom"
      left: true
      right: true
    }

    implicitHeight: Core.Style.barHeight
    color: Config.Theme.transparent

    WlrLayershell.namespace: "quickshell-bar"
    WlrLayershell.layer: WlrLayer.Top
    exclusiveZone: Core.Style.barHeight

    // Bar Component
    Bar {
      anchors.fill: parent
      onNotificationClicked: notificationCenter.toggle()
      onNetworkClicked: networkPanel.toggle()
      onSettingsClicked: settingsPanel.toggle()
    }

    // Notification Center
    Panels.NotificationCenter {
      id: notificationCenter
      screen: barWindow.modelData
    }

    // Settings Panel
    Panels.SettingsPanel {
      id: settingsPanel
      parentWindow: barWindow
    }

    // Network Panel
    Panels.NetworkPanel {
      id: networkPanel
      parentWindow: barWindow
    }
  }
}
