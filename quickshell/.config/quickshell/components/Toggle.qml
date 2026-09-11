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

  activeFocusOnTab: root.enabled

  property bool checked: false

  signal toggled(bool checked)

  implicitWidth: 44
  implicitHeight: 24
  radius: Core.Style.radiusFull

  // Was inert on hover - it read only `checked`, despite being the control you
  // reach for most in a FormRow.
  color: {
    const base = checked ? Config.Theme.accent : Config.Theme.surfaceHover;
    if (mouse.pressed)
      return Config.Theme.stateLayer(base, Core.Style.opacityPressed);
    if (mouse.containsMouse)
      return Config.Theme.stateLayer(base, Core.Style.opacityHover);
    return base;
  }

  opacity: enabled ? 1.0 : Core.Style.opacityDisabled

  Behavior on opacity {
    NumberAnimation {
      duration: Core.Style.duration(Core.Style.animFast)
    }
  }

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

  // Keyboard focus was invisible everywhere except TextField, which made the
  // shell effectively unusable without a pointer. Drawn outside the control so
  // it never eats into the content box.
  Rectangle {
    anchors.fill: parent
    anchors.margins: -Core.Style.focusRingOffset
    z: -1

    visible: root.activeFocus
    color: Config.Theme.transparent
    radius: parent.radius + Core.Style.focusRingOffset
    border.color: Config.Theme.focusRing
    border.width: Core.Style.focusRingWidth
  }

  MouseArea {
    id: mouse

    anchors.fill: parent
    hoverEnabled: root.enabled
    enabled: root.enabled
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

    onClicked: {
      root.checked = !root.checked;
      root.toggled(root.checked);
    }
  }
}
