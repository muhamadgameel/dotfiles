import QtQuick

import "../config" as Config
import "../core" as Core

/**
* WarningOverlay - pulse that flags a widget entering a warning/critical state
*
* A translucent tint that pulses `pulseLoops` times when `active` turns on,
* then fades out and stays out. The widget's own icon and text colour carry the
* state from there; this only draws the eye to the moment it changed.
*
* It used to pulse forever. The states it marks are steady - a laptop CPU that
* idles above the temperature threshold is "warning" all day - and any running
* animation keeps the window rendering at the display refresh rate. That made
* it a permanent 240 Hz render loop, and most of the shell's idle CPU.
*
* Usage:
*   Item {
*       // Your content...
*
*       WarningOverlay {
*           active: isWarning
*           severity: "warning"   // or "critical"
*       }
*   }
*/
Rectangle {
  id: root

  // === Properties ===
  property bool active: false
  property string severity: "warning"  // "warning" or "critical"
  property real maxOpacity: 0.2
  property int duration: Core.Style.animSlow * 2
  property int pulseLoops: 3

  readonly property bool shouldPulse: root.active && root.visible && Core.Style.motionEnabled

  // === Appearance ===
  anchors.fill: parent
  radius: (parent as Rectangle)?.radius ?? 0

  color: {
    if (severity === "critical")
      return Config.Theme.error;
    return Config.Theme.warning;
  }

  visible: active
  opacity: 0

  // === Pulse Animation ===
  // Started explicitly rather than through `running:`, which would not restart
  // a finite animation that has already run out its loops. See StatusDot.qml.
  SequentialAnimation {
    id: pulseAnim

    loops: root.pulseLoops

    NumberAnimation {
      target: root
      property: "opacity"
      to: root.maxOpacity
      duration: root.duration
      easing.type: Easing.InOutQuad
    }

    // Ends at 0, so a finished pulse leaves nothing drawn.
    NumberAnimation {
      target: root
      property: "opacity"
      to: 0
      duration: root.duration
      easing.type: Easing.InOutQuad
    }
  }

  onShouldPulseChanged: {
    if (shouldPulse) {
      pulseAnim.restart();
    } else {
      pulseAnim.stop();
      opacity = 0;
    }
  }

  Component.onCompleted: {
    if (shouldPulse)
      pulseAnim.start();
  }
}
