import QtQuick
import QtQuick.Layouts

import "../components" as Components
import "../config" as Config
import "../core" as Core

/**
* Collapsible - Expandable/collapsible section with title
*
* Usage:
*   Collapsible {
*       title: "Advanced Settings"
*       expanded: false
*
*       FormRow { label: "Option 1" }
*       FormRow { label: "Option 2" }
*   }
*/
ColumnLayout {
  id: root

  property string title: "Section"
  property bool expanded: true
  property string icon: ""

  default property alias content: contentColumn.data

  spacing: Core.Style.spaceS

  // Header
  Components.Card {
    Layout.fillWidth: true
    implicitHeight: 36
    interactive: true

    onClicked: root.expanded = !root.expanded

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Core.Style.spaceS
      anchors.rightMargin: Core.Style.spaceS

      spacing: Core.Style.spaceS

      Components.Icon {
        visible: root.icon !== ""
        icon: root.icon
        size: Core.Style.fontL
        color: Config.Theme.text
      }

      Components.Text {
        text: root.title
        weight: Core.Style.weightBold
        Layout.fillWidth: true
      }

      Components.Icon {
        icon: root.expanded ? "chevron-down" : "chevron-right"
        size: Core.Style.fontS
        color: Config.Theme.textDim
      }
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
