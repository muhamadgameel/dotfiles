import QtQuick

import "../config" as Config
import "../core" as Core

/**
* ScrollArea - Styled Flickable wrapper with consistent scrollbar
*
* Provides a scrollable area with optional styled scrollbar.
* Wraps Flickable with common settings and visual consistency.
*
* Usage:
*   // Basic scrollable content
*   ScrollArea {
*       contentHeight: column.height
*
*       Column {
*           id: column
*           width: parent.width
*           // content...
*       }
*   }
*
*   // Horizontal scroll
*   ScrollArea {
*       orientation: Qt.Horizontal
*       contentWidth: row.width
*
*       Row {
*           id: row
*           // content...
*       }
*   }
*/
Flickable {
  id: root

  // === Scrollbar Properties ===
  property bool showScrollbar: true
  property int scrollbarWidth: 2
  property color scrollbarColor: Config.Theme.alpha(Config.Theme.accent, 0.8)

  // === Behavior Properties ===
  property int orientation: Qt.Vertical

  // === State (readonly) ===
  readonly property bool scrolling: moving
  readonly property bool atStart: orientation === Qt.Vertical ? atYBeginning : atXBeginning
  readonly property bool atEnd: orientation === Qt.Vertical ? atYEnd : atXEnd

  // === Flickable Setup ===
  clip: true
  boundsBehavior: Flickable.StopAtBounds
  flickableDirection: orientation === Qt.Vertical ? Flickable.VerticalFlick : Flickable.HorizontalFlick

  rightMargin: orientation === Qt.Vertical ? Core.Style.panelPadding : 0
  leftMargin: orientation === Qt.Vertical ? Core.Style.panelPadding : 0
  bottomMargin: orientation === Qt.Horizontal ? Core.Style.panelPadding : 0
  topMargin: orientation === Qt.Horizontal ? Core.Style.panelPadding : 0

  // === Vertical Scrollbar ===
  Rectangle {
    id: verticalScrollbar
    visible: root.showScrollbar && root.orientation === Qt.Vertical && root.contentHeight > root.height
    parent: root
    z: 100

    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.margins: Core.Style.spaceXXS

    width: root.scrollbarWidth
    radius: width / 2
    color: Config.Theme.transparent

    anchors.rightMargin: root.scrollbarWidth + Core.Style.spaceXXS

    Rectangle {
      id: verticalHandle
      width: parent.width
      radius: width / 2
      color: root.scrollbarColor

      // Calculate handle position and size
      readonly property real viewRatio: root.height / root.contentHeight
      readonly property real handleHeight: Math.max(20, parent.height * viewRatio)

      height: handleHeight
      y: root.contentHeight > root.height ? (parent.height - handleHeight) * (root.contentY / (root.contentHeight - root.height)) : 0

      Behavior on color {
        ColorAnimation {
          duration: Core.Style.animFast
        }
      }
    }
  }

  // === Horizontal Scrollbar ===
  Rectangle {
    id: horizontalScrollbar
    visible: root.showScrollbar && root.orientation === Qt.Horizontal && root.contentWidth > root.width
    parent: root
    z: 100

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: Core.Style.spaceXXS

    height: root.scrollbarWidth
    radius: height / 2
    color: Config.Theme.transparent

    anchors.bottomMargin: root.scrollbarWidth + Core.Style.spaceXXS

    Rectangle {
      id: horizontalHandle
      height: parent.height
      radius: height / 2
      color: root.scrollbarColor

      // Calculate handle position and size
      readonly property real viewRatio: root.width / root.contentWidth
      readonly property real handleWidth: Math.max(20, parent.width * viewRatio)

      width: handleWidth
      x: root.contentWidth > root.width ? (parent.width - handleWidth) * (root.contentX / (root.contentWidth - root.width)) : 0

      Behavior on color {
        ColorAnimation {
          duration: Core.Style.animFast
        }
      }
    }
  }

  // === Public API ===
  function scrollToTop() {
    contentY = 0;
  }

  function scrollToBottom() {
    contentY = contentHeight - height;
  }

  function scrollToLeft() {
    contentX = 0;
  }

  function scrollToRight() {
    contentX = contentWidth - width;
  }
}
