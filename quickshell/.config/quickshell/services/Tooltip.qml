pragma Singleton

import QtQuick
import Quickshell

/**
* Tooltip - shell-wide tooltip controller
*
* Drives the one tooltip window the whole shell shares. The window is built in
* shell.qml and handed over through `window`, the same way shell.qml pushes
* Logger its level. Building it here meant this service importing modules/popups
* - a service reaching up into the view layer - so it is built where the OSD and
* notification popups already are.
*/
Singleton {
  id: root

  // The shared TooltipWindow, set by shell.qml. Until then show() does nothing.
  property var window: null

  // The item the tooltip is currently following, if any.
  readonly property Item currentTarget: _target

  property Item _target: null

  function show(target, text, direction, delay) {
    if (!target || !text || !root.window)
      return;

    // Re-entering the same item (including while it is animating out) must not
    // restart the reveal.
    if (root._target === target)
      return;

    root._target = target;
    root.window.showFor(target, text, direction, delay);
  }

  function hide() {
    root._target = null;
    if (root.window)
      root.window.hide();
  }

  /**
  * Forget a target that is going away.
  *
  * Repeater and Variants delegates are destroyed while still hovered. Without
  * this the service keeps comparing against a dead item, and a recycled
  * delegate that lands on the same address is mistaken for "already showing".
  */
  function forget(target) {
    if (root._target !== target)
      return;

    root._target = null;
    if (root.window)
      root.window.release();
  }
}
