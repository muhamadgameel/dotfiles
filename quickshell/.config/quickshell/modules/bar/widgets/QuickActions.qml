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

  signal screenshotRequested
  signal powerRequested

  spacing: Core.Style.spaceXS

  Components.Button {
    icon: "camera"
    iconSize: Core.Style.fontL
    visible: Config.Config.barShowScreenshot
    tooltipText: "Take a screenshot"
    onClicked: root.screenshotRequested()
  }

  Components.Button {
    icon: "power"
    iconSize: Core.Style.fontL
    iconColor: Config.Theme.error
    visible: Config.Config.barShowPower
    tooltipText: "Power menu"
    onClicked: root.powerRequested()
  }
}
