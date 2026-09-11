import QtQuick
import QtQuick.Layouts

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core
import "../../services" as Services
import "widgets" as Widgets

/**
* Bar - the bar contents
*
* The clock is positioned absolutely at the centre of the bar, and the two side
* sections are anchored *to it* rather than sharing a row with it.
*
* A three-cell RowLayout cannot actually centre the middle cell: the side
* sections are sized by their content's minimums, so the centre lands wherever
* those happen to leave it.
*
* Anchoring the sections to the clock's edges gives both properties at once:
* the clock is always exactly centred, and neither section can reach it.
*/
Rectangle {
  id: root

  // The screen this bar is on, so per-monitor widgets can filter.
  property var screen: null

  // Signals for external communication
  signal audioClicked
  signal notificationClicked
  signal networkClicked
  signal bluetoothClicked
  signal systemStatsClicked
  signal mediaClicked
  signal calendarClicked
  signal powerClicked
  signal screenshotClicked

  color: Config.Theme.barBg

  // ===================================================================
  // CENTRE - absolutely centred, never overlapped
  // ===================================================================
  Widgets.Clock {
    id: clock

    anchors.centerIn: parent
    visible: Config.Config.barShowClock

    onCalendarRequested: root.calendarClicked()
  }

  // ===================================================================
  // LEFT
  // ===================================================================
  RowLayout {
    anchors.left: parent.left
    anchors.leftMargin: Core.Style.spaceM
    // Bounded by the clock, so the window title elides instead of running underneath it.
    anchors.right: clock.visible ? clock.left : parent.horizontalCenter
    anchors.rightMargin: Core.Style.spaceM
    anchors.verticalCenter: parent.verticalCenter

    spacing: Core.Style.spaceS

    Widgets.Launcher {
      visible: Config.Config.barShowLauncher
    }

    Widgets.Workspaces {
      screen: root.screen
    }

    Widgets.WindowTitle {
      Layout.fillWidth: true
      Layout.maximumWidth: Core.Style.windowTitleMaxWidth
      visible: Config.Config.barShowWindowTitle
    }

    // Takes up whatever the title does not, keeping the widgets left-packed.
    Components.Spacer {}
  }

  // ===================================================================
  // RIGHT
  // ===================================================================
  RowLayout {
    anchors.left: clock.visible ? clock.right : parent.horizontalCenter
    anchors.leftMargin: Core.Style.spaceM
    anchors.right: parent.right
    anchors.rightMargin: Core.Style.spaceM
    anchors.verticalCenter: parent.verticalCenter

    spacing: Core.Style.spaceXS

    // Pushes everything to the right edge.
    Components.Spacer {}

    Widgets.Media {
      visible: Config.Config.barShowMedia && Services.Media.hasPlayer
      onPanelRequested: root.mediaClicked()
    }

    Widgets.Tray {
      id: tray

      visible: Config.Config.barShowTray && tray.shownItems.length > 0
    }

    Components.Divider {
      Layout.fillHeight: false
      Layout.preferredHeight: Core.Style.iconSize
      vertical: true
    }

    Widgets.IdleInhibitor {
      visible: Config.Config.barShowIdleInhibitor
    }

    Widgets.Network {
      visible: Config.Config.barShowNetwork
      onPanelRequested: root.networkClicked()
    }

    Widgets.Bluetooth {
      visible: Config.Config.barShowBluetooth
      onPanelRequested: root.bluetoothClicked()
    }

    Widgets.Volume {
      visible: Config.Config.barShowVolume
      onPanelRequested: root.audioClicked()
    }

    Widgets.Microphone {
      visible: Config.Config.barShowMicrophone
      onPanelRequested: root.audioClicked()
    }

    Widgets.Brightness {
      visible: Config.Config.barShowBrightness && Services.Brightness.ready
    }

    Widgets.SystemStats {
      visible: Config.Config.barShowSystemStats
      onPanelRequested: root.systemStatsClicked()
    }

    Widgets.Battery {
      id: battery

      visible: Config.Config.barShowBattery && battery.hasBattery
    }

    Widgets.NotificationBell {
      visible: Config.Config.barShowNotification
      onPanelRequested: root.notificationClicked()
    }

    Components.Divider {
      Layout.fillHeight: false
      Layout.preferredHeight: Core.Style.iconSize
      vertical: true
    }

    Widgets.QuickActions {
      onScreenshotRequested: root.screenshotClicked()
      onPowerRequested: root.powerClicked()
    }
  }
}
