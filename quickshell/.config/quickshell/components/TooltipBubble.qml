import QtQuick
import "../core" as Core

import "." as Components

/**
* TooltipBubble - Tooltip content component
*
* The visual bubble only. For a positioned tooltip window, go through
* Services.Tooltip, which drives modules/popups/TooltipWindow.qml.
*
* Usage:
*   // As a standalone tooltip content
*   Tooltip {
*       text: "This is helpful information"
*       visible: parent.hovered
*   }
*
*   // With custom styling
*   Tooltip {
*       text: "Custom tooltip"
*       backgroundColor: Theme.accent
*       textColor: Theme.bg
*   }
*/
Rectangle {
  id: root

  // === Properties ===
  property string text: ""
  property color backgroundColor: Core.Theme.surface
  property color textColor: Core.Theme.text
  property color borderColor: Core.Theme.surfaceHover
  property int borderWidth: Core.Style.borderThin
  property real fontSize: Core.Style.fontS
  property real paddingH: Core.Style.spaceM
  property real paddingV: Core.Style.spaceS

  // === Dimensions ===
  implicitWidth: tooltipText.implicitWidth + paddingH * 2
  implicitHeight: tooltipText.implicitHeight + paddingV * 2

  // === Appearance ===
  radius: Core.Style.radiusS
  color: backgroundColor
  border.color: borderColor
  border.width: borderWidth

  visible: text !== ""

  // === Content ===
  Components.Text {
    id: tooltipText
    anchors.centerIn: parent
    text: root.text
    size: root.fontSize
    color: root.textColor
  }
}
