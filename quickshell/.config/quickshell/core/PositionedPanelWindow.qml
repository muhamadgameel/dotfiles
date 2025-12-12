import QtQuick
import Quickshell
import Quickshell.Wayland

import "../config" as Config

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

  // The screen this panel is associated with.
  property ShellScreen screen
  property string namespace

  // === Position Configuration ===
  property string location: "top_right"
  property int margin: 0
  property int topExtra: 0
  property int bottomExtra: 0
  property int leftExtra: 0
  property int rightExtra: 0

  // === Parsed Position (readonly) ===
  readonly property bool isTop: location.startsWith("top")
  readonly property bool isBottom: location.startsWith("bottom")
  readonly property bool isLeft: location.endsWith("_left")
  readonly property bool isRight: location.endsWith("_right")
  readonly property bool isCenter: location.endsWith("_center") || (!isLeft && !isRight)

  // === Anchors (auto-configured) ===
  anchors.top: isTop
  anchors.bottom: isBottom
  anchors.left: isLeft
  anchors.right: isRight

  // === Margins (auto-configured) ===
  margins {
    top: isTop ? margin + topExtra : 0
    bottom: isBottom ? margin + bottomExtra : 0
    left: isLeft ? margin + leftExtra : 0
    right: isRight ? margin + rightExtra : 0
  }

  // Default transparent background
  color: Config.Theme.transparent

  // Wayland layer settings
  WlrLayershell.namespace: namespace + (screen?.name || "unknown")
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusionMode: ExclusionMode.Ignore
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
}
