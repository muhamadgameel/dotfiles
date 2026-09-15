import QtQuick

import "../core" as Core

/**
* ProgressBar - Horizontal progress indicator
*
* A simple progress bar that fills from left to right.
* Automatically animates value changes with a smooth easing transition.
*
* Usage:
*   // Basic usage (0-1 range)
*   ProgressBar { value: 0.75 }
*
*   // Custom range (e.g., 0-100)
*   ProgressBar { value: 75; maxValue: 100 }
*
*   // Custom colors
*   ProgressBar { value: 0.5; progressColor: Theme.success }
*/
Rectangle {
  id: root

  property real value: 0.0
  property real maxValue: 1.0
  property color progressColor: Core.Theme.accent

  implicitWidth: Core.Style.px(200)
  implicitHeight: Core.Style.progressHeightM
  radius: Core.Style.radiusFull
  color: Core.Theme.surface

  Rectangle {
    id: fill
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom

    width: parent.width * Math.min(1.0, root.value / root.maxValue)
    radius: parent.radius
    color: root.progressColor

    Behavior on color {
      ColorAnimation {
        duration: Core.Style.duration(Core.Style.animNormal)
        easing.type: Core.Style.easeStandard
      }
    }

    Behavior on width {
      NumberAnimation {
        duration: Core.Style.duration(Core.Style.animFast)
        easing.type: Core.Style.easeStandard
      }
    }
  }
}
