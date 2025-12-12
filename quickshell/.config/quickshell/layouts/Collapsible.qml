import QtQuick
import QtQuick.Layouts

import "../components" as Components
import "../config" as Config
import "../core" as Core

/*
* Collapsible - Expandable/collapsible section with title
*/
ColumnLayout {
  id: root

  property string title: "Section"
  property bool expanded: true

  default property alias content: contentColumn.data

  spacing: Core.Style.spaceS

  // Header
  Rectangle {
    Layout.fillWidth: true
    height: 36
    radius: Core.Style.radiusS
    color: headerMouse.containsMouse ? Config.Theme.surface : Config.Theme.transparent

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Core.Style.spaceS
      anchors.rightMargin: Core.Style.spaceS

      Components.Label {
        text: root.title
        font.weight: Core.Style.weightBold
        Layout.fillWidth: true
      }

      Components.Label {
        text: root.expanded ? "▼" : "▶"
        color: Config.Theme.textDim
        size: Core.Style.fontS
      }
    }

    MouseArea {
      id: headerMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.expanded = !root.expanded
    }
  }

  // Content
  ColumnLayout {
    id: contentColumn
    Layout.fillWidth: true
    Layout.leftMargin: Core.Style.spaceS
    spacing: Core.Style.spaceXS
    visible: root.expanded
  }
}
