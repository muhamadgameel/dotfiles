import QtQuick

import "." as Core

/**
* ShowHideAnimator
*
* Animates an item in on show() and out on hide(): fade and scale, plus a slide
* from one edge for cards and notifications, or with `slideFrom: "none"`, a pop
* in place for tooltips and the OSD.
*
* Usage:
*   ShowHideAnimator {
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
  property real slideDistance: Core.Style.slideDistance

  // Which edge the item travels in from on show, and back out towards on hide:
  // "top" | "bottom" | "left" | "right", or "none" to pop in place. Hide is always
  // the reverse of show, so a card that enters from the right leaves to the right.
  property string slideFrom: "top"

  // Duration
  property int showDuration: Core.Style.duration(Core.Style.slideShowDuration)
  property int hideDuration: Core.Style.duration(Core.Style.slideHideDuration)

  // Scale
  property real hiddenScale: Core.Style.slideHiddenScale
  property real visibleScale: 1.0

  // Opacity
  property real hiddenOpacity: 0.0
  property real visibleOpacity: 1.0

  // Easing
  property int showEasing: Core.Style.easeEnter
  property int hideEasing: Core.Style.easeExit
  property real showOvershoot: Core.Style.enterOvershoot

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
  // Fresh callers need a hidden starting frame, but reversals must retain it.
  property bool _initialized: false
  readonly property bool _horizontal: root.slideFrom === "left" || root.slideFrom === "right"

  // Negative for the edges the item comes from above/before, positive otherwise.
  readonly property real _hiddenOffset: root.slideFrom === "none" ? 0 : (root.slideFrom === "top" || root.slideFrom === "left") ? -root.slideDistance : root.slideDistance

  // The unused axis keeps its binding at 0 forever; the active one has its
  // binding broken by the first _setOffset() write, which is what the animations
  // then drive.
  property Translate _slideTransform: Translate {
    x: root._horizontal ? root._hiddenOffset : 0
    y: root._horizontal ? 0 : root._hiddenOffset
  }

  function _setOffset(value) {
    if (root._horizontal)
      root._slideTransform.x = value;
    else
      root._slideTransform.y = value;
  }

  Component.onCompleted: {
    if (target && root.slideFrom !== "none") {
      target.transform = target.transform ? target.transform.concat([_slideTransform]) : [_slideTransform];
    }
  }

  // === Public Methods ===
  function show() {
    if (!target)
      return;
    if (!_initialized)
      setHidden();
    const reversing = hideAnim.running;
    hideAnim.stop();
    showStarted();

    // Stagger hidden entrances only; never pause an in-flight reversal.
    if (delayTimer.interval > 0 && !reversing && !showAnim.running && target.opacity === hiddenOpacity) {
      delayTimer.start();
    } else {
      delayTimer.stop();
      showAnim.start();
    }
  }

  function hide() {
    if (!target)
      return;
    _initialized = true;
    delayTimer.stop();
    showAnim.stop();
    hideStarted();
    hideAnim.start();
  }

  function setHidden() {
    if (!target)
      return;
    _initialized = true;
    delayTimer.stop();
    showAnim.stop();
    hideAnim.stop();
    target.opacity = hiddenOpacity;
    target.scale = hiddenScale;
    root._setOffset(root._hiddenOffset);
  }

  function setVisible() {
    if (!target)
      return;
    _initialized = true;
    delayTimer.stop();
    showAnim.stop();
    hideAnim.stop();
    target.opacity = visibleOpacity;
    target.scale = visibleScale;
    root._setOffset(0);
  }

  Timer {
    id: delayTimer
    interval: Core.Style.duration(root.entryDelay)
    repeat: false
    onTriggered: showAnim.start()
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

    PropertyAnimation {
      target: root._slideTransform
      property: root._horizontal ? "x" : "y"
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
      property: root._horizontal ? "x" : "y"
      to: root._hiddenOffset
      duration: root.hideDuration
      easing.type: root.hideEasing
    }
  }
}
