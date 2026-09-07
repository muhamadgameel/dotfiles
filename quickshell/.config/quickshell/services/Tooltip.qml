pragma Singleton

import QtQuick
import Quickshell

import "../modules/popups" as Popups

/**
* Tooltip - shell-wide tooltip controller
*
* Owns one tooltip window for the whole shell, created on first use and reused
* afterwards. Previously a window was created per hover with createObject(null)
* - unparented, so nothing owned it - and hide() cleared the service's
* reference while the object was still animating itself towards self-destruct.
*/
Singleton {
  id: root

  // The item the tooltip is currently following, if any.
  readonly property Item currentTarget: _target

  property Item _target: null
  property var _window: null

  Component {
    id: tooltipComponent

    Popups.TooltipWindow {}
  }

  function _ensureWindow() {
    if (!_window)
      _window = tooltipComponent.createObject(root);
    return _window;
  }

  function show(target, text, direction, delay) {
    if (!target || !text)
      return;

    // Re-entering the same item (including while it is animating out) must not
    // restart the reveal.
    if (root._target === target)
      return;

    root._target = target;
    _ensureWindow().showFor(target, text, direction, delay);
  }

  function hide() {
    root._target = null;
    if (_window)
      _window.hide();
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
    if (_window)
      _window.release();
  }
}
