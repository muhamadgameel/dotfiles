import QtQuick

import "../config" as Config
import "../core" as Core

/**
* Badge - A pill-shaped label for status or tags
*/
Rectangle {
  id: root

  property string text: ""
  property color textColor: Config.Theme.accent
  property color backgroundColor: Config.Theme.alpha(textColor, 0.2)
  property real fontSize: Core.Style.fontS

  implicitWidth: badgeText.width + Core.Style.spaceM
  implicitHeight: badgeText.height + Core.Style.spaceXS
  radius: implicitHeight / 2
  color: backgroundColor
  visible: text !== ""

  Label {
    id: badgeText
    anchors.centerIn: parent
    text: root.text
    size: root.fontSize
    color: root.textColor
  }
}
