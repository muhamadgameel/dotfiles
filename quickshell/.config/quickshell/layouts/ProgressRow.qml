import QtQuick
import QtQuick.Layouts

import "../components" as Components
import "../config" as Config
import "../core" as Core

/*
* ProgressRow - Icon + Progress Bar + Percentage label
*/
RowLayout {
  id: root

  property string icon: ""
  property color iconColor: Config.Theme.text
  property int iconSize: Core.Style.fontXL
  property real value: 0
  property real maxValue: 1
  property color progressColor: Config.Theme.accent
  property bool showPercentage: true

  spacing: Core.Style.spaceM

  Components.Icon {
    icon: root.icon
    size: root.iconSize
    color: root.iconColor

    Behavior on color {
      ColorAnimation {
        duration: Core.Style.animNormal
      }
    }
  }

  Components.ProgressBar {
    Layout.fillWidth: true
    value: root.value
    maxValue: root.maxValue
    progressColor: root.progressColor
  }

  Components.Label {
    visible: root.showPercentage
    text: Math.round(root.value * 100) + "%"
    size: Core.Style.fontM
  }
}
