import QtQuick

import "../components" as Components
import "../config" as Config
import "../core" as Core

/**
* Tooltip - Tooltip content component
*
* A simple tooltip content component for displaying help text.
* This is the visual component - for window-based tooltips,
* use the Tooltip module via Services.Tooltip.
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
  property color backgroundColor: Config.Theme.surface
  property color textColor: Config.Theme.text
  property color borderColor: Config.Theme.surfaceHover
  property int borderWidth: 1
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
