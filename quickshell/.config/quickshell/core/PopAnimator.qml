import QtQuick

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

  // Duration (ms)
  property int showDuration: 150
  property int hideDuration: 75

  // Scale
  property real hiddenScale: 0.85
  property real visibleScale: 1.0

  // Opacity
  property real hiddenOpacity: 0.0
  property real visibleOpacity: 1.0

  // Easing
  property int showEasing: Easing.OutBack
  property int hideEasing: Easing.InCubic
  property real showOvershoot: 1.2

  // === Signals ===
  signal showStarted
  signal showFinished
  signal hideStarted
  signal hideFinished

  // === State ===
  readonly property bool isAnimating: showAnim.running || hideAnim.running
  readonly property bool isVisible: target ? target.opacity > 0 : false

  // === Public Methods ===
  function show() {
    if (!target)
      return;
    hideAnim.stop();
    showStarted();
    showAnim.start();
  }

  function hide() {
    if (!target)
      return;
    showAnim.stop();
    hideStarted();
    hideAnim.start();
  }

  function setHidden() {
    if (!target)
      return;
    showAnim.stop();
    hideAnim.stop();
    target.opacity = hiddenOpacity;
    target.scale = hiddenScale;
  }

  function setVisible() {
    if (!target)
      return;
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
      from: root.hiddenOpacity
      to: root.visibleOpacity
      duration: root.showDuration
      easing.type: root.showEasing
    }

    PropertyAnimation {
      target: root.target
      property: "scale"
      from: root.hiddenScale
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
