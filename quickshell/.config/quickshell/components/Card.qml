import QtQuick

import "../core" as Core

/**
* Card - Base container component with consistent styling
*
* Provides a reusable container with:
* - Border, radius, and background color
* - Hover state with color transition
* - Click handling with mouse button support
* - A content slot
*
* Usage:
*   // Basic card
*   Card {
*       Text { text: "Content" }
*   }
*
*   // Interactive card
*   Card {
*       interactive: true
*       onClicked: doSomething()
*   }
*
*   // Custom styling
*   Card {
*       backgroundColor: Theme.surface
*       hoverColor: Theme.surfaceActive
*       borderColor: Theme.accent
*   }
*/
Rectangle {
  id: root

  // === Content ===
  default property alias content: contentItem.data

  // === Styling Properties ===
  // Filled by default: a transparent card was invisible until hovered, so list
  // rows read as loose text and a Collapsible header as a plain heading.
  property color backgroundColor: Core.Theme.cardBg
  property color hoverColor: Core.Theme.surface
  property color activeColor: Core.Theme.surfaceActive
  property color borderColor: Core.Theme.transparent
  property int borderWidth: 0

  // === Behavior Properties ===
  property bool interactive: false
  property bool hoverEnabled: true

  // === State (readonly) ===
  // From a HoverHandler rather than the MouseArea, which stops containing the
  // mouse as soon as the pointer moves onto a button inside the card. A row
  // that shows its buttons on hover then hid them again, in a loop.
  readonly property bool hovered: hoverHandler.hovered
  readonly property bool pressed: mouseArea.pressed

  // === Signals ===
  signal clicked(var button)

  // === Appearance ===
  radius: Core.Style.radiusS

  readonly property color _effectiveBackground: Qt.colorEqual(backgroundColor, Core.Theme.transparent) ? Core.Theme.transparentOf(hoverColor) : backgroundColor

  color: {
    if (!hoverEnabled)
      return backgroundColor;
    if (pressed && interactive)
      return activeColor;
    if (hovered)
      return hoverColor;
    return _effectiveBackground;
  }

  border.color: borderColor
  border.width: borderWidth

  Behavior on color {
    ColorAnimation {
      duration: Core.Style.duration(Core.Style.animFast)
    }
  }

  // === Mouse Handling ===
  // Declared before contentItem so it's behind the content in z-order,
  // allowing child MouseAreas (e.g., buttons) to receive click events
  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: root.hoverEnabled
    cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    acceptedButtons: root.interactive ? (Qt.LeftButton | Qt.RightButton | Qt.MiddleButton) : Qt.NoButton

    onClicked: mouse => root.clicked(mouse.button)
    // Must stay: with a doubleClicked handler, MouseArea does not emit clicked
    // for the second click, which otherwise armed and confirmed a Power action.
    onDoubleClicked: mouse => mouse.accepted = true
  }

  HoverHandler {
    id: hoverHandler
    enabled: root.hoverEnabled
  }

  // === Content Container ===
  Item {
    id: contentItem
    anchors.fill: parent
  }
}
