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

  // Which edge the item travels in from on show, and back out towards on hide:
  // "top" | "bottom" | "left" | "right", or "none" to pop in place. Hide is always
  // the reverse of show, so a card that enters from the right leaves to the right.
  property string slideFrom: "top"

  // Duration
  property int showDuration: Core.Style.duration(Core.Style.slideShowDuration)
  property int hideDuration: Core.Style.duration(Core.Style.slideHideDuration)

  // Scale
  property real hiddenScale: Core.Style.slideHiddenScale

  // Easing
  property int showEasing: Core.Style.easeEnter
  property int hideEasing: Core.Style.easeExit

  // === Signals ===
  signal hideFinished

  // === Internal ===
  // Fresh callers need a hidden starting frame, but reversals must retain it.
  property bool _initialized: false
  readonly property bool _horizontal: root.slideFrom === "left" || root.slideFrom === "right"

  // Negative for the edges the item comes from above/before, positive otherwise.
  readonly property real _hiddenOffset: root.slideFrom === "none" ? 0 : (root.slideFrom === "top" || root.slideFrom === "left") ? -Core.Style.slideDistance : Core.Style.slideDistance

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
    hideAnim.stop();
    showAnim.start();
  }

  function hide() {
    if (!target)
      return;
    _initialized = true;
    showAnim.stop();
    hideAnim.start();
  }

  function setHidden() {
    if (!target)
      return;
    _initialized = true;
    showAnim.stop();
    hideAnim.stop();
    target.opacity = 0;
    target.scale = hiddenScale;
    root._setOffset(root._hiddenOffset);
  }

  function setVisible() {
    if (!target)
      return;
    _initialized = true;
    showAnim.stop();
    hideAnim.stop();
    target.opacity = 1;
    target.scale = 1;
    root._setOffset(0);
  }

  // === Animations ===
  ParallelAnimation {
    id: showAnim

    PropertyAnimation {
      target: root.target
      property: "opacity"
      to: 1
      duration: root.showDuration
      easing.type: Core.Style.easeStandard
    }

    PropertyAnimation {
      target: root.target
      property: "scale"
      to: 1
      duration: root.showDuration
      easing.type: root.showEasing
      easing.overshoot: Core.Style.enterOvershoot
    }

    PropertyAnimation {
      target: root._slideTransform
      property: root._horizontal ? "x" : "y"
      to: 0
      duration: root.showDuration
      easing.type: root.showEasing
      easing.overshoot: Core.Style.enterOvershoot
    }
  }

  ParallelAnimation {
    id: hideAnim
    onFinished: root.hideFinished()

    PropertyAnimation {
      target: root.target
      property: "opacity"
      to: 0
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
