import QtQuick
import Quickshell

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core

/**
* Tooltip - the single tooltip surface for the shell
*
* Created once, in shell.qml, and driven by Services.Tooltip: re-anchored per
* target rather than constructed and destroyed on every hover.
*
* Placement is delegated to PopupAnchor's edges/gravity/adjustment, which flips
* and slides the popup to keep it on screen. The hand-rolled geometry helper
* this replaces could not see the compositor's constraints and only clamped
* horizontally, in one branch.
*/
PopupWindow {
  id: root

  property string text: ""
  property string direction: "auto"

  visible: false
  color: Core.Theme.transparent

  readonly property int shadowRoom: Core.Style.elevationRoom(1)

  implicitWidth: content.implicitWidth + shadowRoom * 2
  implicitHeight: content.implicitHeight + shadowRoom * 2

  anchor {
    edges: root._edgeFor(root.direction)
    gravity: root._edgeFor(root.direction)
    adjustment: PopupAdjustment.All

    margins {
      left: Core.Style.spaceS - root.shadowRoom
      right: Core.Style.spaceS - root.shadowRoom
      top: Core.Style.spaceS - root.shadowRoom
      bottom: Core.Style.spaceS - root.shadowRoom
    }
  }

  // "auto" resolves to Bottom and lets PopupAdjustment flip it if there is no
  // room, which is what auto placement needs to mean here.
  function _edgeFor(dir) {
    switch (dir) {
    case "top":
      return Edges.Top;
    case "left":
      return Edges.Left;
    case "right":
      return Edges.Right;
    default:
      return Edges.Bottom;
    }
  }

  // === Public API (driven by Services.Tooltip) ===

  // Another item's tooltip, waiting for this one to finish hiding.
  property var _next: null

  function showFor(target, tipText, tipDirection) {
    if (!target || !tipText)
      return;

    // A popup moved while it shows can leave pieces of its old frame on screen,
    // so the tooltip only moves once it has hidden.
    if (root.visible && root.anchor.item !== target) {
      root._next = {
        target: target,
        text: tipText,
        direction: tipDirection
      };
      animator.hide();
      return;
    }

    root._next = null;
    root._place(target, tipText, tipDirection);

    if (root.visible) {
      // Back on the item it was hiding from.
      animator.show();
      return;
    }

    showTimer.restart();
  }

  function refresh(target, tipText) {
    if (root._next?.target === target)
      root._next.text = tipText;
    else if (root.anchor.item === target)
      root.text = tipText;
  }

  function hide() {
    root._next = null;
    showTimer.stop();
    if (root.visible)
      animator.hide();
  }

  // Drop the anchor immediately, without animating, so a target that is being
  // destroyed is not held alive by it.
  function release() {
    root._next = null;
    showTimer.stop();
    animator.setHidden();
    root.visible = false;
    root.anchor.item = null;
    root.text = "";
  }

  Timer {
    id: showTimer
    interval: Config.Config.tooltipDelay
    repeat: false
    onTriggered: {
      if (root.anchor.item)
        root._reveal();
    }
  }

  function _place(target, tipText, tipDirection) {
    root.text = tipText;
    root.direction = tipDirection ?? "auto";
    root.anchor.item = target;
  }

  function _reveal() {
    root.visible = true;
    // Let the content lay out first, otherwise the opening frame is placed
    // against a zero-size popup. This is why the old version mispositioned
    // whenever it was shown with no delay.
    Qt.callLater(animator.show);
  }

  Core.ShowHideAnimator {
    id: animator
    target: bubble
    slideFrom: "none"
    showDuration: Core.Style.duration(Core.Style.popShowDuration)
    hideDuration: Core.Style.duration(Core.Style.popHideDuration)
    hiddenScale: Core.Style.popHiddenScale
    onHideFinished: {
      root.visible = false;
      root.anchor.item = null;

      // Straight in, without the hover delay: the pointer went from one
      // tooltip to the next.
      const next = root._next;
      root._next = null;
      if (next) {
        root._place(next.target, next.text, next.direction);
        root._reveal();
      }
    }
  }

  // The shadow fades and scales with the bubble, so neither is left on
  // screen without the other.
  Item {
    id: bubble

    anchors.centerIn: parent
    width: content.implicitWidth
    height: content.implicitHeight
    visible: root.text !== ""
    transformOrigin: Item.Center
    opacity: 0

    Components.Elevation {
      surface: content
      level: 1
      radius: content.radius
    }

    Rectangle {
      id: content

      anchors.fill: parent
      implicitWidth: tooltipText.implicitWidth + Core.Style.spaceM * 2
      implicitHeight: tooltipText.implicitHeight + Core.Style.spaceS * 2
      radius: Core.Style.radiusS
      color: Core.Theme.surface
      border.color: Core.Theme.surfaceHover
      border.width: Core.Style.borderThin

      Components.Text {
        id: tooltipText

        anchors.centerIn: parent
        text: root.text
        size: Core.Style.fontM
      }
    }
  }
}
