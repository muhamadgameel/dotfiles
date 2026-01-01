import QtQuick

import "../config" as Config
import "../core" as Core

/**
* WarningOverlay - Animated warning/critical pulse overlay
*
* A translucent pulsing overlay for indicating warning or critical states.
* Extracted from Battery.qml and SystemStats.qml for reuse.
*
* Usage:
*   // Warning state
*   Item {
*       // Your content...
*
*       WarningOverlay {
*           active: isWarning
*           severity: "warning"
*       }
*   }
*
*   // Critical state with custom color
*   WarningOverlay {
*       active: isCritical
*       severity: "critical"
*       color: Theme.error
*   }
*
*   // Custom animation
*   WarningOverlay {
*       active: showWarning
*       maxOpacity: 0.3
*       duration: 600
*   }
*/
Rectangle {
  id: root

  // === Properties ===
  property bool active: false
  property string severity: "warning"  // "warning" or "critical"
  property real maxOpacity: 0.2
  property int duration: Core.Style.animSlow * 2

  // === Appearance ===
  anchors.fill: parent
  radius: parent.radius ?? 0

  color: {
    if (severity === "critical")
      return Config.Theme.error;
    return Config.Theme.warning;
  }

  visible: active
  opacity: 0

  // === Pulse Animation ===
  SequentialAnimation on opacity {
    running: root.active && root.visible
    loops: Animation.Infinite

    NumberAnimation {
      to: root.maxOpacity
      duration: root.duration
      easing.type: Easing.InOutQuad
    }

    NumberAnimation {
      to: 0
      duration: root.duration
      easing.type: Easing.InOutQuad
    }
  }

  // Reset opacity when deactivated
  onActiveChanged: {
    if (!active) {
      opacity = 0;
    }
  }
}
