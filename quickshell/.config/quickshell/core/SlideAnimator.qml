import QtQuick

/**
* SlideAnimator
*
* Animates an item with coordinated slide, opacity, and scale transitions.
* Creates a sliding entrance effect for cards, notifications, and panels.
*
* Usage:
*   SlideAnimator {
*     id: animator
*     target: card
*     slideDistance: 300
*     onHideFinished: card.destroy()
*   }
*
*   animator.show()
*   animator.hide()
*/
Item {
  id: root

  // === Configuration ===
  required property Item target

  // Slide
  property real slideDistance: 200
  property bool slideFromTop: true  // false = slide from bottom

  // Duration (ms)
  property int showDuration: 350
  property int hideDuration: 250

  // Scale
  property real hiddenScale: 0.8
  property real visibleScale: 1.0

  // Opacity
  property real hiddenOpacity: 0.0
  property real visibleOpacity: 1.0

  // Easing
  property int showEasing: Easing.OutBack
  property int hideEasing: Easing.InCubic
  property real showOvershoot: 1.2

  // Entry delay for staggered animations
  property int entryDelay: 0

  // === Signals ===
  signal showStarted
  signal showFinished
  signal hideStarted
  signal hideFinished

  // === State ===
  readonly property bool isAnimating: showAnim.running || hideAnim.running || delayTimer.running
  readonly property bool isVisible: target ? target.opacity > 0 : false

  // === Internal ===
  property real _hiddenOffset: slideFromTop ? -slideDistance : slideDistance

  property Translate _slideTransform: Translate {
    y: root._hiddenOffset
  }

  Component.onCompleted: {
    if (target) {
      target.transform = target.transform ? target.transform.concat([_slideTransform]) : [_slideTransform];
    }
  }

  // === Public Methods ===
  function show() {
    if (!target)
      return;
    hideAnim.stop();
    showStarted();

    if (entryDelay > 0) {
      delayTimer.start();
    } else {
      _startShowAnim();
    }
  }

  function hide() {
    if (!target)
      return;
    delayTimer.stop();
    showAnim.stop();
    hideStarted();
    hideAnim.start();
  }

  function setHidden() {
    if (!target)
      return;
    delayTimer.stop();
    showAnim.stop();
    hideAnim.stop();
    target.opacity = hiddenOpacity;
    target.scale = hiddenScale;
    _slideTransform.y = _hiddenOffset;
  }

  function setVisible() {
    if (!target)
      return;
    delayTimer.stop();
    showAnim.stop();
    hideAnim.stop();
    target.opacity = visibleOpacity;
    target.scale = visibleScale;
    _slideTransform.y = 0;
  }

  // === Internal ===
  function _startShowAnim() {
    // Reset to hidden state before animating
    target.opacity = hiddenOpacity;
    target.scale = hiddenScale;
    _slideTransform.y = _hiddenOffset;
    showAnim.start();
  }

  Timer {
    id: delayTimer
    interval: root.entryDelay
    repeat: false
    onTriggered: root._startShowAnim()
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

    PropertyAnimation {
      target: root._slideTransform
      property: "y"
      from: root._hiddenOffset
      to: 0
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

    PropertyAnimation {
      target: root._slideTransform
      property: "y"
      to: root._hiddenOffset
      duration: root.hideDuration
      easing.type: root.hideEasing
    }
  }
}
