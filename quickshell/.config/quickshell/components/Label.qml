import QtQuick

import "../config" as Config
import "../core" as Core

Text {
  id: root

  property real size: Core.Style.fontM
  property string weight: Core.Style.weightMedium

  font.pixelSize: size
  font.weight: weight
  color: Config.Theme.text
  elide: Text.ElideRight
  verticalAlignment: Text.AlignVCenter
}
