import QtQuick

import "../config" as Config
import "../core" as Core

Rectangle {
  id: root

  property real value: 0.0
  property real maxValue: 1.0
  property color progressColor: Config.Theme.accent
  property color backgroundColor: Config.Theme.surface
  property bool reversed: false

  implicitWidth: 200
  implicitHeight: 6
  radius: height / 2
  color: backgroundColor

  Rectangle {
    id: fill
    anchors.left: root.reversed ? undefined : parent.left
    anchors.right: root.reversed ? parent.right : undefined
    anchors.top: parent.top
    anchors.bottom: parent.bottom

    width: parent.width * Math.min(1.0, root.value / root.maxValue)
    radius: parent.radius
    color: root.progressColor

    Behavior on width {
      NumberAnimation {
        duration: Core.Style.animFast
        easing.type: Easing.OutQuad
      }
    }
  }
}
