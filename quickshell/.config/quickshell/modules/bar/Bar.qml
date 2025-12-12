import QtQuick
import QtQuick.Layouts

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core
import "widgets" as Widgets

Rectangle {
  id: root

  // Signals for external communication
  signal settingsClicked
  signal notificationClicked

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

      Widgets.Volume {
        visible: Config.Config.barShowVolume
      }

      Widgets.Microphone {
        visible: Config.Config.barShowMicrophone
      }

      Widgets.Notification {
        visible: Config.Config.barShowNotification
        onClickedMainEvent: root.notificationClicked()
      }

      Widgets.Brightness {
        visible: Config.Config.barShowBrightness
      }

      Components.Divider {
        vertical: true
        Layout.preferredHeight: 16
      }

      Widgets.Settings {
        onClicked: root.settingsClicked()
      }
    }
  }
}
