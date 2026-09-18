import QtQuick
import Quickshell
import Quickshell.Wayland

import "../core" as Core

/**
* PositionedPanelWindow - PanelWindow with built-in position handling
*
* Automatically sets anchors and margins based on a position string.
*
* Usage:
*   PositionedPanelWindow {
*     screen: myScreen
*     location: "top_right"   // or Config.Config.osdPosition
*     margin: 20
*     topExtra: Style.barHeight * 2
*
*     // Your content here
*   }
*/
PanelWindow {
  id: root

  property string namespace

  // === Position Configuration ===
  property string location: "top_right"
  property int margin: 0
  property int topExtra: 0
  property int bottomExtra: 0

  // === Parsed Position (readonly) ===
  readonly property bool isTop: location.startsWith("top")
  readonly property bool isBottom: location.startsWith("bottom")
  readonly property bool isLeft: location.endsWith("_left")
  readonly property bool isRight: location.endsWith("_right")

  // === Anchors (auto-configured) ===
  anchors.top: isTop
  anchors.bottom: isBottom
  anchors.left: isLeft
  anchors.right: isRight

  // === Margins (auto-configured) ===
  margins {
    top: isTop ? margin + topExtra : 0
    bottom: isBottom ? margin + bottomExtra : 0
    left: isLeft ? margin : 0
    right: isRight ? margin : 0
  }

  // Default transparent background
  color: Core.Theme.transparent

  // Wayland layer settings
  WlrLayershell.namespace: namespace + "-" + (screen?.name ?? "unknown")
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusionMode: ExclusionMode.Ignore
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
}
