import QtQuick

import "../config" as Config
import "../core" as Core

/**
* ProgressBar - Horizontal progress indicator
*
* A simple progress bar that fills from left to right (or right to left when reversed).
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
*
*   // Reversed (fills from right, useful for countdowns)
*   ProgressBar { value: 0.3; reversed: true }
*/
Rectangle {
  id: root

  property real value: 0.0
  property real maxValue: 1.0
  property color progressColor: Config.Theme.accent
  property color trackColor: Config.Theme.surface
  property bool reversed: false

  implicitWidth: 200
  implicitHeight: 6
  radius: height / 2
  color: trackColor

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
