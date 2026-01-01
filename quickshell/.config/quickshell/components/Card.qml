import QtQuick

import "../config" as Config
import "../core" as Core

/**
* Card - Base container component with consistent styling
*
* Provides a reusable container with:
* - Border, radius, and background color
* - Hover state with color transition
* - Click handling with mouse button support
* - Optional padding and content slot
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
  property color backgroundColor: Config.Theme.transparent
  property color hoverColor: Config.Theme.surface
  property color activeColor: Config.Theme.surfaceActive
  property color borderColor: Config.Theme.transparent
  property int borderWidth: 0
  property int padding: 0

  // === Behavior Properties ===
  property bool interactive: false
  property bool hoverEnabled: true

  // === State (readonly) ===
  readonly property bool hovered: mouseArea.containsMouse
  readonly property bool pressed: mouseArea.pressed

  // === Signals ===
  signal clicked(var button)
  signal doubleClicked(var button)
  signal entered
  signal exited

  // === Appearance ===
  radius: Core.Style.radiusS

  // Use hoverColor's RGB with 0 alpha when transparent to prevent black flash during animation
  // (ColorAnimation interpolates RGB through black when going from transparent to opaque)
  readonly property color _effectiveBackground: backgroundColor == Config.Theme.transparent ? Qt.rgba(hoverColor.r, hoverColor.g, hoverColor.b, 0) : backgroundColor

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
      duration: Core.Style.animFast
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
    onDoubleClicked: mouse => root.doubleClicked(mouse.button)
    onEntered: root.entered()
    onExited: root.exited()
  }

  // === Content Container ===
  Item {
    id: contentItem
    anchors.fill: parent
    anchors.margins: root.padding
  }
}
