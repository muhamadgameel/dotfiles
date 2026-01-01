import QtQuick
import Quickshell.Hyprland

import "../../../components" as Components
import "../../../config" as Config
import "../../../core" as Core

/**
* Workspaces - Bar widget showing Hyprland workspaces
*/
Row {
  id: root
  spacing: Core.Style.spaceS

  Repeater {
    model: Hyprland.workspaces

    Components.Card {
      id: wsButton

      required property var modelData

      readonly property var workspace: modelData
      readonly property bool isFocused: Hyprland.focusedWorkspace?.id === workspace.id
      readonly property bool isUrgent: workspace.urgent

      // Hide special workspaces (negative IDs)
      visible: workspace.id > 0

      width: Core.Style.widgetSize
      height: Core.Style.widgetSize

      interactive: true
      backgroundColor: isFocused ? Config.Theme.accent : isUrgent ? Config.Theme.error : Config.Theme.surface
      hoverColor: isFocused ? Config.Theme.accent : isUrgent ? Config.Theme.error : Config.Theme.surfaceHover

      onClicked: workspace.activate()

      Components.Text {
        anchors.centerIn: parent
        text: wsButton.workspace.id
        color: wsButton.isFocused ? Config.Theme.bg : Config.Theme.text
        weight: wsButton.isFocused ? Core.Style.weightBold : Core.Style.weightMedium
      }
    }
  }
}
