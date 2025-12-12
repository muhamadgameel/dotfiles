import QtQuick
import Quickshell

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core

PopupWindow {
  id: root

  property string text: ""
  property string direction: "auto"
  property Item targetItem: null

  visible: false
  color: Config.Theme.transparent

  anchor.item: targetItem
  implicitWidth: content.width
  implicitHeight: content.height

  Timer {
    id: showTimer
    interval: Config.Config.tooltipDelay
    onTriggered: root.positionAndShow()
  }

  function show(target, tipText, tipDirection, delay) {
    targetItem = target;
    text = tipText;
    direction = tipDirection ?? "auto";
    showTimer.interval = delay ?? Config.Config.tooltipDelay;
    showTimer.start();
  }

  function hide() {
    showTimer.stop();
    if (visible)
      animator.hide();
    else
      root.destroy();
  }

  function positionAndShow() {
    var pos = Core.Screen.calculatePopupPosition(targetItem, implicitWidth, implicitHeight, direction, Core.Style.spaceS);
    if (pos) {
      anchor.rect.x = pos.x;
      anchor.rect.y = pos.y;
    }
    visible = true;
    animator.show();
  }

  // === Animation ===

  Core.PopAnimator {
    id: animator
    target: content
    showDuration: Core.Style.animFast
    hideDuration: Core.Style.animFaster
    onHideFinished: root.destroy()
  }

  // === Content ===

  Rectangle {
    id: content
    width: label.implicitWidth + Core.Style.spaceM * 2
    height: label.implicitHeight + Core.Style.spaceS * 2

    color: Config.Theme.surface
    border.color: Config.Theme.surfaceHover
    border.width: 1
    radius: Core.Style.radiusS

    transformOrigin: Item.Center

    Components.Label {
      id: label
      anchors.centerIn: parent
      text: root.text
      size: Core.Style.fontS
    }
  }
}
