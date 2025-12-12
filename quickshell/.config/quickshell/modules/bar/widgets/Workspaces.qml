import QtQuick
import Quickshell.Hyprland

import "../../../components" as Components
import "../../../config" as Config
import "../../../core" as Core

Row {
  id: root
  spacing: Core.Style.spaceS

  Repeater {
    model: Hyprland.workspaces

    Rectangle {
      id: wsButton

      required property var modelData

      readonly property var workspace: modelData
      readonly property bool isFocused: Hyprland.focusedWorkspace?.id === workspace.id
      readonly property bool isUrgent: workspace.urgent
      readonly property bool isHovered: mouseArea.containsMouse

      // Hide special workspaces (negative IDs)
      visible: workspace.id > 0

      width: Core.Style.widgetSize
      height: Core.Style.widgetSize
      radius: Core.Style.radiusS

      color: isFocused ? Config.Theme.accent : isUrgent ? Config.Theme.error : isHovered ? Config.Theme.surfaceHover : Config.Theme.surface

      Behavior on color {
        ColorAnimation {
          duration: Core.Style.animFast
        }
      }

      Components.Label {
        anchors.centerIn: parent
        text: wsButton.workspace.id
        color: wsButton.isFocused ? Config.Theme.bg : Config.Theme.text
        weight: wsButton.isFocused ? Core.Style.weightBold : Core.Style.weightMedium
      }

      MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: wsButton.workspace.activate()
      }
    }
  }
}
