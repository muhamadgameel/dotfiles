import QtQuick
import QtQuick.Layouts

import "../../../components" as Components
import "../../../config" as Config
import "../../../core" as Core

/**
* QuickActions - bar entry points for the panels that have no status to show
*
* Clipboard, screenshot and power have no ambient state worth a permanent
* readout, but they still need to be discoverable - reachable only by keybind
* or `qs ipc call` means nobody finds them.
*/
RowLayout {
  id: root

  signal quickSettingsRequested
  signal settingsRequested
  signal wallpaperRequested
  signal screenshotRequested
  signal powerRequested

  spacing: Core.Style.spaceXS

  Components.Button {
    icon: "dashboard"
    tooltipText: "Quick settings"
    onClicked: root.quickSettingsRequested()
  }

  Components.Button {
    icon: "settings"
    tooltipText: "Settings"
    onClicked: root.settingsRequested()
  }

  Components.Button {
    icon: "image"
    visible: Config.Config.barShowWallpaper
    tooltipText: "Change the wallpaper"
    onClicked: root.wallpaperRequested()
  }

  Components.Button {
    icon: "camera"
    visible: Config.Config.barShowScreenshot
    tooltipText: "Take a screenshot"
    onClicked: root.screenshotRequested()
  }

  Components.Button {
    icon: "power"
    iconColor: Core.Theme.error
    visible: Config.Config.barShowPower
    tooltipText: "Power menu"
    onClicked: root.powerRequested()
  }
}
