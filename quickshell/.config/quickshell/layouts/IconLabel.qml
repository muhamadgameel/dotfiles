import QtQuick
import QtQuick.Layouts

import "../components" as Components
import "../config" as Config
import "../core" as Core

// TODO: is this component needed?!!
RowLayout {
  id: root

  property string icon: ""
  property string label: ""
  property color iconColor: Config.Theme.text
  property int iconSize: Core.Style.fontXXL
  property int labelSize: Core.Style.fontL

  spacing: Core.Style.spaceM

  Item {
    Layout.fillWidth: true
  }

  Components.Icon {
    icon: root.icon
    size: root.iconSize
    color: root.iconColor
  }

  Components.Label {
    visible: root.label !== ""
    text: root.label
    size: root.labelSize
  }

  Item {
    Layout.fillWidth: true
  }
}
