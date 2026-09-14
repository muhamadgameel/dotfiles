import QtQuick
import QtQuick.Layouts
import "../core" as Core

import "." as Components

/**
* StatusBanner - an error message in a red banner
*
* Usage:
*   StatusBanner {
*       visible: hasError
*       message: errorMessage
*   }
*/
Rectangle {
  id: root

  property string message: ""

  implicitHeight: visible ? content.height + Core.Style.spaceS * 2 : 0
  radius: Core.Style.radiusS
  color: Core.Theme.alpha(Core.Theme.error, Core.Style.opacityTintStrong)

  RowLayout {
    id: content
    anchors {
      left: parent.left
      right: parent.right
      verticalCenter: parent.verticalCenter
      margins: Core.Style.spaceM
    }
    spacing: Core.Style.spaceS

    Components.Icon {
      icon: "error"
      size: Core.Style.fontL
      color: Core.Theme.error
      Layout.alignment: Qt.AlignCenter
    }

    Components.Text {
      Layout.fillWidth: true
      text: root.message
      color: Core.Theme.error
      size: Core.Style.fontM
      wrapMode: Text.Wrap
    }
  }
}
