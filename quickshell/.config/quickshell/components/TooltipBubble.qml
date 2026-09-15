import QtQuick
import "../core" as Core

import "." as Components

/**
* TooltipBubble - Tooltip content component
*
* The visual bubble only. For a positioned tooltip window, go through
* Services.Tooltip, which drives modules/popups/TooltipWindow.qml.
*/
Rectangle {
  id: root

  // === Properties ===
  property string text: ""

  // === Dimensions ===
  implicitWidth: tooltipText.implicitWidth + Core.Style.spaceM * 2
  implicitHeight: tooltipText.implicitHeight + Core.Style.spaceS * 2

  // === Appearance ===
  radius: Core.Style.radiusS
  color: Core.Theme.surface
  border.color: Core.Theme.surfaceHover
  border.width: Core.Style.borderThin

  visible: text !== ""

  // === Content ===
  Components.Text {
    id: tooltipText
    anchors.centerIn: parent
    text: root.text
    size: Core.Style.fontS
  }
}
