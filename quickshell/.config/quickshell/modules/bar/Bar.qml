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

  // A widget asked for its panel. The id is one of Services.Panels.ids; the bar
  // only names it, and BarWindow does the routing.
  signal panelRequested(string panelId)

  color: Core.Theme.barBg

  // ===================================================================
  // CENTRE - absolutely centred, never overlapped
  // ===================================================================
  Widgets.Clock {
    id: clock

    anchors.centerIn: parent
    visible: Config.Config.barShowClock

    onCalendarRequested: root.panelRequested("calendar")
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

    Widgets.Tray {
      id: tray

      visible: Config.Config.barShowTray && tray.shownItems.length > 0
    }

    Components.Divider {
      Layout.fillHeight: false
      Layout.preferredHeight: Core.Style.iconSize
      vertical: true
    }

    // Only while it is on: left on by accident, it keeps the machine awake and
    // drains the battery. Quick Settings has the switch.
    Widgets.IdleInhibitor {
      visible: Config.Config.barShowIdleInhibitor && Services.Idle.inhibited
    }

    BarGroup {
      Widgets.Volume {
        visible: Config.Config.barShowVolume
        onPanelRequested: root.panelRequested("audio")
      }

      Widgets.Microphone {
        visible: Config.Config.barShowMicrophone
        onPanelRequested: root.panelRequested("audio")
      }

      Widgets.Media {
        visible: Config.Config.barShowMedia && Services.Media.hasPlayer
        onPanelRequested: root.panelRequested("media")
      }
    }

    BarGroup {
      Widgets.Network {
        visible: Config.Config.barShowNetwork
        onPanelRequested: root.panelRequested("network")
      }

      Widgets.Bluetooth {
        visible: Config.Config.barShowBluetooth
        onPanelRequested: root.panelRequested("bluetooth")
      }
    }

    BarGroup {
      Widgets.SystemStats {
        visible: Config.Config.barShowSystemStats
        onPanelRequested: root.panelRequested("systemstats")
      }

      Widgets.Battery {
        id: battery

        visible: Config.Config.barShowBattery && battery.hasBattery
      }
    }

    // Off by default; Quick Settings has the slider.
    Widgets.Brightness {
      visible: Config.Config.barShowBrightness && Services.Brightness.ready
    }

    Widgets.NotificationBell {
      visible: Config.Config.barShowNotification
      onPanelRequested: root.panelRequested("notifications")
    }

    Components.Divider {
      Layout.fillHeight: false
      Layout.preferredHeight: Core.Style.iconSize
      vertical: true
    }

    Widgets.QuickActions {
      onQuickSettingsRequested: root.panelRequested("quicksettings")
      onWallpaperRequested: root.panelRequested("wallpaper")
      onScreenshotRequested: root.panelRequested("screenshot")
      onPowerRequested: root.panelRequested("power")
    }
  }
}
