import QtQuick
import QtQuick.Layouts

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core
import "widgets" as Widgets

Rectangle {
  id: root

  // Signals for external communication
  signal notificationClicked
  signal networkClicked
  signal systemStatsClicked
  signal testPanelClicked

  color: Config.Theme.alpha(Config.Theme.bg, 0.95)

  // === CENTER SECTION (absolutely centered) ===
  Widgets.Clock {
    anchors.centerIn: parent
    visible: Config.Config.barShowClock
  }

  // === LEFT & RIGHT SECTIONS ===
  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: Core.Style.spaceM
    anchors.rightMargin: Core.Style.spaceM
    spacing: Core.Style.spaceM

    // === LEFT SECTION ===
    RowLayout {
      spacing: Core.Style.spaceS

      Widgets.Launcher {
        visible: Config.Config.barShowLauncher
      }

      Widgets.Workspaces {}
    }

    // === SPACER ===
    Item {
      Layout.fillWidth: true
    }

    // === RIGHT SECTION ===
    RowLayout {
      spacing: Core.Style.spaceXS

      Widgets.Network {
        visible: Config.Config.barShowNetwork
        onPanelRequested: root.networkClicked()
      }

      Widgets.Volume {
        visible: Config.Config.barShowVolume
      }

      Widgets.Microphone {
        visible: Config.Config.barShowMicrophone
      }

      Widgets.Brightness {
        visible: Config.Config.barShowBrightness
      }

      Widgets.SystemStats {
        visible: Config.Config.barShowSystemStats
        onPanelRequested: root.systemStatsClicked()
      }

      Widgets.Battery {
        visible: Config.Config.barShowBattery
      }

      Widgets.Notification {
        visible: Config.Config.barShowNotification
        onPanelRequested: root.notificationClicked()
      }

      Components.Divider {
        vertical: true
      }

      Widgets.Test {
        onPanelRequested: root.testPanelClicked()
      }
    }
  }
}
