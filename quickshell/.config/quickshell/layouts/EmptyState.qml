import QtQuick
import QtQuick.Layouts

import "../components" as Components
import "../config" as Config
import "../core" as Core

/**
* EmptyState - Displays a centered icon with message and optional hint
*
* Used for showing empty states in lists or disabled features
*/
Item {
  id: root

  property string icon: "info"
  property int iconSize: Core.Style.fontXXL
  property string message: ""
  property string hint: ""

  implicitHeight: content.implicitHeight + Core.Style.spaceXL

  ColumnLayout {
    id: content
    anchors.centerIn: parent
    spacing: Core.Style.spaceS

    Components.Icon {
      Layout.alignment: Qt.AlignHCenter
      name: root.icon
      size: root.iconSize
      color: Config.Theme.textMuted
    }

    Components.Label {
      Layout.alignment: Qt.AlignHCenter
      text: root.message
      size: root.hint ? Core.Style.fontL : Core.Style.fontM
      color: Config.Theme.textMuted
    }

    Components.Label {
      Layout.alignment: Qt.AlignHCenter
      visible: root.hint !== ""
      text: root.hint
      size: Core.Style.fontS
      color: Config.Theme.textDim
    }
  }
}
