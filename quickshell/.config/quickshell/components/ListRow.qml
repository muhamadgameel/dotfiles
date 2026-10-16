import QtQuick
import QtQuick.Layouts
import "../core" as Core

import "." as Components

/**
* ListRow - a card row: an icon, a title over a small grey line, an icon at the end
*
* Items in `trailing` go at the end of the row: buttons, a spinner. The row keeps
* its height at the top of the card, so a row that sets a larger implicitHeight
* has room under it for content of its own.
*
* Usage:
*   ListRow {
*       icon: "lock"
*       title: "Lock"
*       subtitle: "Lock the screen"
*       interactive: true
*       onClicked: lock()
*   }
*/
Components.Card {
  id: root

  // The shorter row used inside collapsible lists.
  property bool dense: false

  property string icon: ""
  property real iconSize: root.dense ? Core.Style.fontL : Core.Style.fontXL
  property color iconColor: Core.Theme.text

  property string title: ""
  property color titleColor: Core.Theme.text
  property int titleWeight: root.dense ? Core.Style.weightMedium : Core.Style.weightBold
  property string subtitle: ""

  property alias trailing: trailingRow.data

  // Shown at the end of the row while set.
  property string trailingIcon: ""
  property real trailingSize: Core.Style.fontM
  property color trailingColor: Core.Theme.accent

  readonly property int rowHeight: root.dense ? Core.Style.controlHeightM : Core.Style.controlHeightL

  Layout.fillWidth: true
  implicitHeight: root.rowHeight

  RowLayout {
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: root.dense ? Core.Style.spaceM : Core.Style.spaceL
    anchors.rightMargin: root.dense ? Core.Style.spaceM : Core.Style.spaceL
    height: root.rowHeight
    spacing: root.dense ? Core.Style.spaceS : Core.Style.spaceM

    Components.Icon {
      icon: root.icon
      size: root.iconSize
      color: root.iconColor
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 0

      Components.Text {
        Layout.fillWidth: true
        text: root.title
        weight: root.titleWeight
        color: root.titleColor
      }

      Components.Text {
        Layout.fillWidth: true
        visible: root.subtitle !== ""
        text: root.subtitle
        size: Core.Style.fontXS
        color: Core.Theme.textMuted
      }
    }

    RowLayout {
      id: trailingRow

      visible: children.length > 0
      spacing: Core.Style.spaceXS
    }

    Components.Icon {
      visible: root.trailingIcon !== ""
      icon: root.trailingIcon
      size: root.trailingSize
      color: root.trailingColor
    }
  }
}
