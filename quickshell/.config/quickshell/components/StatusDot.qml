import QtQuick

import "../config" as Config
import "../core" as Core

/**
* StatusDot - Generic status indicator dot
*
* A small dot for showing status with optional pulse animation.
* Replaces and extends PulsingDot functionality.
*
* Usage:
*   // Static status dot
*   StatusDot {
*       color: Theme.success
*   }
*
*   // Pulsing dot (activity indicator)
*   StatusDot {
*       color: Theme.accent
*       pulse: true
*   }
*
*   // Conditional pulse
*   StatusDot {
*       color: isCharging ? Theme.success : Theme.text
*       pulse: isCharging
*   }
*
*   // Custom size
*   StatusDot {
*       size: 8
*       color: Theme.error
*   }
*/
Rectangle {
  id: root

  // === Properties ===
  property bool pulse: false
  property int pulseDuration: Core.Style.animSlow
  property real minOpacity: 0.3
  property real size: 4

  // === Dimensions ===
  width: size
  height: size
  radius: size / 2

  // === Appearance ===
  color: Config.Theme.accent

  // === Pulse Animation ===
  SequentialAnimation on opacity {
    running: root.pulse && root.visible
    loops: Animation.Infinite

    NumberAnimation {
      to: root.minOpacity
      duration: root.pulseDuration
      easing.type: Easing.InOutQuad
    }

    NumberAnimation {
      to: 1.0
      duration: root.pulseDuration
      easing.type: Easing.InOutQuad
    }
  }

  // Reset opacity when pulse stops
  onPulseChanged: {
    if (!pulse) {
      opacity = 1.0;
    }
  }
}
