import QtQuick

/**
* WheelSteps - whole steps from a mouse wheel or a two-finger swipe
*
* A wheel notch is one step. A swipe arrives as dozens of small events, so its
* travel is added up and counts one step per swipePerStep. Both count along
* `orientation`; with `swipes: false` only notches do. A swipe steps the way the
* fingers move.
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

  property bool swipes: true

  // Up or left is positive.
  signal scrolled(int steps)

  property real _travel: 0

  // Qt's Wayland platform reports every wheel event as a touchpad's.
  acceptedDevices: PointerDevice.AllDevices

  onWheel: event => {
    const delta = root.orientation === Qt.Horizontal ? event.angleDelta.x : event.angleDelta.y;
    let steps = Math.sign(delta);

    // Only a swipe has a scroll phase, and it ends on an event of its own.
    if (event.phase !== Qt.NoScrollPhase) {
      if (!root.swipes)
        return;
      // Natural scrolling (hypr settings/input.lua) runs angleDelta against the
      // fingers, and Qt does not flag it: event.inverted stays false.
      root._travel -= delta;
      steps = Math.trunc(root._travel / root.swipePerStep);
      root._travel = event.phase === Qt.ScrollEnd ? 0 : root._travel - steps * root.swipePerStep;
    }

    if (steps !== 0)
      root.scrolled(steps);
  }
}
