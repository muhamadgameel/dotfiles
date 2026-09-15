import QtQuick

import "../core" as Core

/**
* ScrollArea - vertical Flickable with the shell's thin scrollbar
*
* Usage:
*   ScrollArea {
*       contentHeight: column.height
*
*       Column {
*           id: column
*           width: parent.width
*           // content...
*       }
*   }
*/
Flickable {
  id: root

  // === Scrollbar Properties ===
  property bool showScrollbar: true
  property int scrollbarWidth: Core.Style.px(2)
  property color scrollbarColor: Core.Theme.alpha(Core.Theme.accent, 0.8)

  // === Flickable Setup ===
  clip: true
  boundsBehavior: Flickable.StopAtBounds
  flickableDirection: Flickable.VerticalFlick

  // === Scrollbar ===
  Rectangle {
    id: scrollbar
    visible: root.showScrollbar && root.contentHeight > root.height
    parent: root
    z: Core.Style.zOverlay

    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.margins: Core.Style.spaceXXS

    width: root.scrollbarWidth
    radius: Core.Style.radiusFull
    color: Core.Theme.transparent

    anchors.rightMargin: root.scrollbarWidth + Core.Style.spaceXXS

    Rectangle {
      id: handle
      width: parent.width
      radius: Core.Style.radiusFull
      color: root.scrollbarColor

      // Calculate handle position and size
      readonly property real viewRatio: root.height / root.contentHeight
      readonly property real handleHeight: Math.max(Core.Style.px(20), parent.height * viewRatio)

      height: handleHeight
      y: root.contentHeight > root.height ? (parent.height - handleHeight) * (root.contentY / (root.contentHeight - root.height)) : 0

      Behavior on color {
        ColorAnimation {
          duration: Core.Style.duration(Core.Style.animFast)
          easing.type: Core.Style.easeStandard
        }
      }
    }
  }
}
