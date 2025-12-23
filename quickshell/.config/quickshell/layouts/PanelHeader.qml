import QtQuick
import QtQuick.Layouts

import "../components" as Components
import "../config" as Config
import "../core" as Core

/**
* PanelHeader - Reusable header component for panels
*
* Displays an icon, title, subtitle, and close button
*/
RowLayout {
  id: root

  property string icon: ""
  property color iconColor: Config.Theme.text
  property string title: ""
  property string subtitle: ""

  signal closeClicked

  spacing: Core.Style.spaceM

  Components.Icon {
    name: root.icon
    size: Core.Style.fontXXL
    color: root.iconColor
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Components.Label {
      text: root.title
      size: Core.Style.fontXL
      font.weight: Core.Style.weightBold
    }

    Components.Label {
      text: root.subtitle
      size: Core.Style.fontS
      color: Config.Theme.textDim
      visible: root.subtitle !== ""
    }
  }

  Item {
    Layout.fillWidth: true
  }

  Components.Button {
    icon: "close"
    tooltipText: "Close"
    tooltipDirection: "left"
    onClicked: root.closeClicked()
  }
}
