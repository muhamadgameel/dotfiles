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
      onAudioClicked: audioPanel.toggle()
      onNotificationClicked: notificationCenter.toggle()
      onNetworkClicked: networkPanel.toggle()
      onSystemStatsClicked: systemStatsPanel.toggle()
      onTestPanelClicked: testPanel.toggle()
    }

    // Audio Panel
    Panels.AudioPanel {
      id: audioPanel
      parentWindow: barWindow
    }

    // Notification Center
    Panels.NotificationCenter {
      id: notificationCenter
      screen: barWindow.modelData
    }

    // Network Panel
    Panels.NetworkPanel {
      id: networkPanel
      parentWindow: barWindow
    }

    // System Stats Panel
    Panels.SystemStatsPanel {
      id: systemStatsPanel
      parentWindow: barWindow
    }

    // Test Panel
    Panels.TestPanel {
      id: testPanel
      parentWindow: barWindow
    }
  }
}
