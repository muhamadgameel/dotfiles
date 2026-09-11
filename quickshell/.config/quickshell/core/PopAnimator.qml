import QtQuick

import "." as Core

/**
* PopAnimator
*
* Animates an item with coordinated opacity and scale transitions.
* Creates a "pop" effect commonly used for tooltips, menus, and overlays.
*
* Usage:
*   PopAnimator {
*     id: animator
*     target: myContent
*     onHideFinished: popup.destroy()
*   }
*
*   animator.show()
*   animator.hide()
*/
Item {
  id: root

  // === Configuration ===
  required property Item target

  // Duration
  property int showDuration: Core.Style.duration(Core.Style.popShowDuration)
  property int hideDuration: Core.Style.duration(Core.Style.popHideDuration)

  // Scale
  property real hiddenScale: Core.Style.popHiddenScale
  property real visibleScale: 1.0

  // Opacity
  property real hiddenOpacity: 0.0
  property real visibleOpacity: 1.0

  // Easing
  property int showEasing: Core.Style.easeEnter
  property int hideEasing: Core.Style.easeExit
  property real showOvershoot: Core.Style.enterOvershoot

  // === Signals ===
  signal showStarted
  signal showFinished
  signal hideStarted
  signal hideFinished

  // === State ===
  readonly property bool isAnimating: showAnim.running || hideAnim.running
  readonly property bool isVisible: target ? target.opacity > 0 : false

  // Some callers rely on show() to prepare the first entrance. Only do that
  // once: later shows may be reversing a hide and must keep the current frame.
  property bool _initialized: false

  // === Public Methods ===
  function show() {
    if (!target)
      return;
    if (!_initialized)
      setHidden();
    hideAnim.stop();
    showStarted();
    showAnim.start();
  }

  function hide() {
    if (!target)
      return;
    _initialized = true;
    showAnim.stop();
    hideStarted();
    hideAnim.start();
  }

  function setHidden() {
    if (!target)
      return;
    _initialized = true;
    showAnim.stop();
    hideAnim.stop();
    target.opacity = hiddenOpacity;
    target.scale = hiddenScale;
  }

  function setVisible() {
    if (!target)
      return;
    _initialized = true;
    showAnim.stop();
    hideAnim.stop();
    target.opacity = visibleOpacity;
    target.scale = visibleScale;
  }

  // === Animations ===
  ParallelAnimation {
    id: showAnim
    onFinished: root.showFinished()

    PropertyAnimation {
      target: root.target
      property: "opacity"
      to: root.visibleOpacity
      duration: root.showDuration
      easing.type: Core.Style.easeStandard
    }

    PropertyAnimation {
      target: root.target
      property: "scale"
      to: root.visibleScale
      duration: root.showDuration
      easing.type: root.showEasing
      easing.overshoot: root.showOvershoot
    }
  }

  ParallelAnimation {
    id: hideAnim
    onFinished: root.hideFinished()

    PropertyAnimation {
      target: root.target
      property: "opacity"
      to: root.hiddenOpacity
      duration: root.hideDuration
      easing.type: root.hideEasing
    }

    PropertyAnimation {
      target: root.target
      property: "scale"
      to: root.hiddenScale
      duration: root.hideDuration
      easing.type: root.hideEasing
    }
  }
}
