import QtQuick
import QtQuick.Layouts

import "../core" as Core

/**
* Text - Text display component with optional icon
*
* A styled text component that follows the design system.
* Supports an optional icon before or after the label.
*
* Usage:
*   // Simple text
*   Text { text: "Hello" }
*
*   // With icon (section header style)
*   Text { icon: "cpu"; text: "CPU"; size: Style.fontXL; weight: Font.Bold }
*
*   // Icon on right
*   Text { text: "Settings"; icon: "chevron-right"; iconPosition: "right" }
*
*   // Multi-line with wrap (give it a width via Layout.fillWidth)
*   Text { Layout.fillWidth: true; text: "Long..."; wrapMode: Text.Wrap }
*/
Item {
  id: root

  // === Text Properties ===
  property alias text: label.text
  property real size: Core.Style.fontM
  property int weight: Core.Style.weightMedium
  property alias color: label.color
  property alias elide: label.elide
  property alias horizontalAlignment: label.horizontalAlignment
  property alias verticalAlignment: label.verticalAlignment
  property alias font: label.font
  property alias wrapMode: label.wrapMode
  property alias maximumLineCount: label.maximumLineCount
  property alias lineHeight: label.lineHeight
  property alias lineHeightMode: label.lineHeightMode
  property alias truncated: label.truncated

  // === Icon Properties ===
  property string icon: ""
  property color iconColor: label.color
  property real iconSize: size
  property string iconPosition: "left"  // "left" or "right"

  // === Layout ===
  property real spacing: Core.Style.spaceS

  // === Internal ===
  readonly property bool hasIcon: icon !== ""

  // Sized from content. Callers that wrap must supply a width themselves
  // (Layout.fillWidth or an anchor)
  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight

  RowLayout {
    id: row

    anchors.fill: parent
    spacing: root.hasIcon ? root.spacing : 0
    layoutDirection: root.iconPosition === "right" ? Qt.RightToLeft : Qt.LeftToRight

    Icon {
      visible: root.hasIcon
      icon: root.icon
      size: root.iconSize
      color: root.iconColor
    }

    Text {
      id: label

      Layout.fillWidth: true
      font.family: Core.Style.fontFamily
      font.pixelSize: root.size
      font.weight: root.weight
      color: Core.Theme.text
      elide: Text.ElideRight
      verticalAlignment: Text.AlignVCenter

      Behavior on color {
        ColorAnimation {
          duration: Core.Style.duration(Core.Style.animFast)
          easing.type: Core.Style.easeStandard
        }
      }
    }
  }
}
