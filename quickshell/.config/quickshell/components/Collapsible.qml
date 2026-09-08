import QtQuick
import QtQuick.Layouts

import "." as Components
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
        icon: "chevron-right"
        size: Core.Style.fontS
        color: Config.Theme.textDim
        rotation: root.expanded ? 90 : 0

        Behavior on rotation {
          NumberAnimation {
            duration: Core.Style.duration(Core.Style.animFast)
            easing.type: Core.Style.easeStandard
          }
        }
      }
    }
  }

  // Content
  Item {
    Layout.fillWidth: true
    Layout.leftMargin: Core.Style.spaceS
    Layout.preferredHeight: root.expanded ? contentColumn.implicitHeight : 0

    clip: true
    // Skipped entirely when collapsed, so it costs nothing and takes no input.
    visible: Layout.preferredHeight > 0

    Behavior on Layout.preferredHeight {
      NumberAnimation {
        duration: Core.Style.duration(Core.Style.animNormal)
        easing.type: Core.Style.easeStandard
      }
    }

    ColumnLayout {
      id: contentColumn

      width: parent.width
      spacing: Core.Style.spaceXS
    }
  }
}
