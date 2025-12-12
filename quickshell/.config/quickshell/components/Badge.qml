import QtQuick

import "../config" as Config
import "../core" as Core

/*
* Badge - A small indicator for counts or status
*/
Rectangle {
  id: root

  property int count: 0
  property color badgeColor: Config.Theme.error
  property color textColor: Config.Theme.bg
  property color borderColor: Config.Theme.bg

  width: count > 0 ? Math.max(14, badgeText.implicitWidth + 6) : 8
  height: count > 0 ? 14 : 8
  radius: height / 2
  color: badgeColor
  visible: count > 0
  border.color: borderColor
  border.width: Core.Style.borderThin

  Text {
    id: badgeText
    anchors.centerIn: parent
    text: root.count > 99 ? "99+" : root.count.toString()
    font.pixelSize: Core.Style.fontS
    font.weight: Font.Bold
    color: root.textColor
    visible: root.count > 0
  }

  Behavior on width {
    NumberAnimation {
      duration: Core.Style.animFast
    }
  }
}
