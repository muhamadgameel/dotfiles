import QtQuick

import "../core" as Core

/**
* StatusDot - Generic status indicator dot
*
* A small dot for showing status, with an optional pulse to draw the eye.
*
* The pulse is FINITE by default: it runs `pulseLoops` times when the dot
* appears, then holds at full opacity. That is deliberate. Any running
* animation keeps the whole window rendering at the display's refresh rate, so
* a pulse on a state that can last for hours - the idle inhibitor being on,
* the battery charging - was a permanent 240 Hz render loop. Measured, it was
* nearly all of the shell's idle CPU (~8% with it, ~0.3% without).
*
* Use Animation.Infinite only for a state that ends on its own, such as a scan.
*
* Usage:
*   // Static status dot
*   StatusDot {
*       color: Theme.success
*   }
*
*   // Draw attention when something starts, then settle
*   StatusDot {
*       visible: isCharging
*       pulse: true
*   }
*
*   // Transient activity that stops by itself
*   StatusDot {
*       visible: scanning
*       pulse: true
*       pulseLoops: Animation.Infinite
*   }
*/
Rectangle {
  id: root

  // === Properties ===
  property bool pulse: false
  property int pulseLoops: 3
  property int pulseDuration: Core.Style.animSlow
  property real minOpacity: 0.3
  property real size: Core.Style.px(4)

  // Whether the pulse should be running. `visible` is the effective value, so
  // this is also false while any ancestor is hidden.
  readonly property bool shouldPulse: root.pulse && root.visible && Core.Style.motionEnabled

  // === Dimensions ===
  width: size
  height: size
  radius: Core.Style.radiusFull

  // === Appearance ===
  color: Core.Theme.accent

  // === Pulse Animation ===
  // Started and stopped explicitly rather than through a `running:` binding. A
  // finite animation stops itself when its loops run out, and a binding that
  // still evaluates true would not start it again on the next appearance.
  SequentialAnimation {
    id: pulseAnim

    loops: root.pulseLoops

    NumberAnimation {
      target: root
      property: "opacity"
      to: root.minOpacity
      duration: root.pulseDuration
      easing.type: Core.Style.easePulse
    }

    // Ends at full opacity, so a finished pulse leaves a solid dot.
    NumberAnimation {
      target: root
      property: "opacity"
      to: 1.0
      duration: root.pulseDuration
      easing.type: Core.Style.easePulse
    }
  }

  onShouldPulseChanged: {
    if (shouldPulse) {
      pulseAnim.restart();
    } else {
      pulseAnim.stop();
      opacity = 1.0;
    }
  }

  Component.onCompleted: {
    if (shouldPulse)
      pulseAnim.start();
  }
}
