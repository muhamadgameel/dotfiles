import QtQuick

import "../core" as Core

/**
* Text - a label in the shell's font, sizes and colours
*
* Usage:
*   Text { text: "Hello" }
*
*   Text { text: "CPU"; size: Style.fontXL; weight: Font.Bold }
*
*   // Multi-line with wrap (give it a width via Layout.fillWidth)
*   Text { Layout.fillWidth: true; text: "Long..."; wrapMode: Text.Wrap }
*/
Text {
  id: root

  property real size: Core.Style.fontM
  property int weight: Core.Style.weightMedium

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
