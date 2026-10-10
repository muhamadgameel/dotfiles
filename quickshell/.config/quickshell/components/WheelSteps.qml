import QtQuick

/**
* WheelSteps - whole steps from a mouse wheel or a two-finger swipe
*
* A wheel notch is one step. A swipe arrives as dozens of small events, so its
* travel is added up and counts one step per swipePerStep.
*
* Usage:
*   Button {
*       WheelSteps {
*           onScrolled: steps => volume += steps * 0.05
*       }
*   }
*/
WheelHandler {
  id: root

  // angleDelta a swipe covers per step: about half a centimetre of finger travel.
  property real swipePerStep: 450

  // Up is positive.
  signal scrolled(int steps)

  property real _travel: 0

  // Qt's Wayland platform reports every wheel event as a touchpad's.
  acceptedDevices: PointerDevice.AllDevices

  onWheel: event => {
    let steps = Math.sign(event.angleDelta.y);

    // Only a swipe has a scroll phase, and it ends on an event of its own.
    if (event.phase !== Qt.NoScrollPhase) {
      root._travel += event.angleDelta.y;
      steps = Math.trunc(root._travel / root.swipePerStep);
      root._travel = event.phase === Qt.ScrollEnd ? 0 : root._travel - steps * root.swipePerStep;
    }

    if (steps !== 0)
      root.scrolled(steps);
  }
}
