import QtQuick

import "../config" as Config
import "../core" as Core

/**
* PulsingDot - Animated status indicator dot
*
* A small pulsing dot for showing activity states (charging, connecting, etc.)
*
* Usage:
*   PulsingDot {
*       active: isCharging
*       color: Config.Theme.success
*   }
*/
Rectangle {
  id: root

  property bool active: false
  property int duration: Core.Style.animSlow

  width: 4
  height: 4
  radius: 2
  color: Config.Theme.accent
  visible: active
  opacity: 1

  SequentialAnimation on opacity {
    running: root.active
    loops: Animation.Infinite

    NumberAnimation {
      to: 0.3
      duration: root.duration
      easing.type: Easing.InOutQuad
    }

    NumberAnimation {
      to: 1.0
      duration: root.duration
      easing.type: Easing.InOutQuad
    }
  }
}
