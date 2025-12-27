import QtQuick
import QtQuick.Layouts

import "../config" as Config
import "../core" as Core

/**
* Label - Text component with optional icon
*
* Usage:
*   // Simple text
*   Label { text: "Hello" }
*
*   // With icon (section header style)
*   Label { icon: "cpu"; text: "CPU"; size: Style.fontXL; weight: Font.Bold }
*
*   // Icon on right
*   Label { text: "Settings"; icon: "chevron-right"; iconPosition: "right" }
*
*   // Multi-line with wrap
*   Label { text: "Long text..."; wrapMode: Text.Wrap; maximumLineCount: 2 }
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
  property alias contentWidth: label.contentWidth
  property alias contentHeight: label.contentHeight

  // === Icon Properties ===
  property string icon: ""
  property string iconName: ""
  property color iconColor: label.color
  property real iconSize: size
  property string iconPosition: "left"  // "left" or "right"

  // === Layout ===
  property real spacing: Core.Style.spaceS

  // === Internal ===
  readonly property bool hasIcon: icon !== "" || iconName !== ""

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
      name: root.iconName
      size: root.iconSize
      color: root.iconColor
    }

    Text {
      id: label
      Layout.fillWidth: true
      font.pixelSize: root.size
      font.weight: root.weight
      color: Config.Theme.text
      elide: Text.ElideRight
      verticalAlignment: Text.AlignVCenter
    }
  }
}
