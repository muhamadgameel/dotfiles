import QtQuick
import Quickshell

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core

/**
* Tooltip - the single tooltip surface for the shell
*
* Created once by Services.Tooltip and re-anchored per target, rather than
* constructed and destroyed on every hover.
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
  color: Config.Theme.transparent

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

  function showFor(target, tipText, tipDirection, delay) {
    if (!target || !tipText)
      return;

    root.text = tipText;
    root.direction = tipDirection ?? "auto";
    root.anchor.item = target;

    if (root.visible) {
      // Already up for a different target - move without re-waiting.
      animator.show();
      return;
    }

    showTimer.interval = delay ?? Config.Config.tooltipDelay;
    showTimer.restart();
  }

  function hide() {
    showTimer.stop();
    if (root.visible)
      animator.hide();
  }

  // Drop the anchor immediately, without animating, so a target that is being
  // destroyed is not held alive by it.
  function release() {
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
      if (!root.anchor.item)
        return;

      root.visible = true;
      // Let the content lay out first, otherwise the opening frame is placed
      // against a zero-size popup. This is why the old version mispositioned
      // whenever it was shown with no delay.
      Qt.callLater(animator.show);
    }
  }

  Core.PopAnimator {
    id: animator
    target: content
    onHideFinished: {
      root.visible = false;
      root.anchor.item = null;
    }
  }

  Components.Elevation {
    surface: content
    level: 1
    radius: content.radius
  }

  Components.TooltipBubble {
    id: content

    anchors.centerIn: parent
    text: root.text
    transformOrigin: Item.Center
    opacity: 0
  }
}
