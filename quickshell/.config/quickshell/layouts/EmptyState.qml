import QtQuick
import QtQuick.Layouts

import "../components" as Components
import "../config" as Config
import "../core" as Core

/**
* EmptyState - Displays a centered icon with message and optional hint
*
* Used for showing empty states in lists or disabled features
*
* Usage:
*   EmptyState {
*       icon: "inbox"
*       message: "No messages"
*       hint: "New messages will appear here"
*   }
*/
Item {
  id: root

  property string icon: "info"
  property int iconSize: Core.Style.fontXXXL
  property string message: ""
  property string hint: ""

  implicitHeight: content.implicitHeight + Core.Style.spaceXL

  ColumnLayout {
    id: content
    anchors.centerIn: parent
    width: parent.width - Core.Style.spaceXL * 2
    spacing: Core.Style.spaceS

    Components.Icon {
      Layout.alignment: Qt.AlignHCenter
      icon: root.icon
      size: root.iconSize
      color: Config.Theme.textMuted
    }

    Components.Text {
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignHCenter
      text: root.message
      size: root.hint ? Core.Style.fontXL : Core.Style.fontL
      color: Config.Theme.textMuted
      wrapMode: Text.WordWrap
    }

    Components.Text {
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignHCenter
      visible: root.hint !== ""
      text: root.hint
      size: Core.Style.fontM
      color: Config.Theme.textDim
      wrapMode: Text.WordWrap
    }
  }
}
