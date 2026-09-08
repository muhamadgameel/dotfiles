import QtQuick

import "../config" as Config
import "../core" as Core

/**
* Toggle - on/off switch
*
* Reports the change rather than applying it: `checked` is not flipped here, so
* a caller can bind it to the setting it represents and let the round trip
* through Settings decide the visual state. Assigning it locally would make the
* switch show a state the system has not actually reached.
*
* Uses the inherited `enabled`, so a disabled parent disables it.
*
* Usage:
*   Toggle {
*     checked: Config.Config.doNotDisturb
*     onToggled: on => Config.Config.setDoNotDisturb(on)
*   }
*/
Rectangle {
  id: root

  property bool checked: false

  signal toggled(bool checked)

  implicitWidth: 44
  implicitHeight: 24
  radius: height / 2

  color: checked ? Config.Theme.accent : Config.Theme.surfaceHover
  opacity: enabled ? 1.0 : 0.5

  Behavior on color {
    ColorAnimation {
      duration: Core.Style.duration(Core.Style.animFast)
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
        duration: Core.Style.duration(Core.Style.animFast)
        easing.type: Core.Style.easeStandard
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
