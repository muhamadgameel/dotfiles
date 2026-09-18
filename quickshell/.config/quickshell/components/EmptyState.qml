import QtQuick
import QtQuick.Layouts
import "../core" as Core

import "." as Components

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

  // Every call site toggles this against the list it stands in for, and all of
  // them used to hard-swap. Fading and settling from slightly small reads as the
  // state changing rather than the panel redrawing. Covers eight sites at once.
  opacity: visible ? 1 : 0
  scale: visible ? 1 : 0.96

  Behavior on opacity {
    NumberAnimation {
      duration: Core.Style.duration(Core.Style.animNormal)
      easing.type: Core.Style.easeStandard
    }
  }

  Behavior on scale {
    NumberAnimation {
      duration: Core.Style.duration(Core.Style.animNormal)
      easing.type: Core.Style.easeStandard
    }
  }

  property string icon: "info"
  property int iconSize: Core.Style.emptyIconSize
  property string message: ""
  property string hint: ""

  width: parent.width
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
      color: Core.Theme.textMuted
    }

    Components.Text {
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignHCenter
      text: root.message
      size: root.hint ? Core.Style.fontXL : Core.Style.fontL
      color: Core.Theme.textMuted
      wrapMode: Text.WordWrap
    }

    Components.Text {
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignHCenter
      visible: root.hint !== ""
      text: root.hint
      size: Core.Style.fontM
      color: Core.Theme.textDim
      wrapMode: Text.WordWrap
    }
  }
}
