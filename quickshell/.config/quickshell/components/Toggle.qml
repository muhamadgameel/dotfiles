import QtQuick

import "../config" as Config
import "../core" as Core

Rectangle {
  id: root

  property bool checked: false
  property bool enabled: true

  signal toggled(bool checked)

  implicitWidth: 44
  implicitHeight: 24
  radius: height / 2

  color: checked ? Config.Theme.accent : Config.Theme.surfaceHover
  opacity: enabled ? 1.0 : 0.5

  Behavior on color {
    ColorAnimation {
      duration: Core.Style.animFast
    }
  }

  // Knob
  Rectangle {
    id: knob
    width: 18
    height: 18
    radius: 9
    x: root.checked ? parent.width - width - 3 : 3
    anchors.verticalCenter: parent.verticalCenter

    color: Config.Theme.text

    Behavior on x {
      NumberAnimation {
        duration: Core.Style.animFast
        easing.type: Easing.OutQuad
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.enabled
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

    onClicked: {
      root.checked = !root.checked;
      root.toggled(root.checked);
    }
  }
}
