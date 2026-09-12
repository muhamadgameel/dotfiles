import QtQuick

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

  // === Variant ===
  //
  // Most Cards defaulted to a transparent background, which meant a Card was
  // invisible until hovered - list rows read as loose text on a flat plane, and
  // a Collapsible header looked identical to a plain heading. `filled` gives a
  // container you can actually see; the other two are opt-in for the cases that
  // genuinely want no surface of their own.
  //
  //   filled    a visible surface, the default
  //   outlined  hairline border, transparent fill
  //   ghost     invisible until hovered (the old behaviour)
  property string variant: "filled"

  readonly property bool _filled: variant === "filled"
  readonly property bool _outlined: variant === "outlined"

  // === Styling Properties ===
  // Each defaults from the variant but stays overridable per instance.
  property color backgroundColor: root._filled ? Core.Theme.cardBg : Core.Theme.transparent
  property color hoverColor: root._filled ? Core.Theme.surface : Core.Theme.stateLayer(Core.Theme.surface, Core.Style.opacityHover)
  property color activeColor: Core.Theme.surfaceActive
  property color borderColor: root._outlined ? Core.Theme.surfaceHover : Core.Theme.transparent
  property int borderWidth: root._outlined ? Core.Style.borderThin : 0
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
