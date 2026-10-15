import QtQuick

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

  implicitWidth: Core.Style.px(44)
  implicitHeight: Core.Style.px(24)
  radius: Core.Style.radiusFull

  // Was inert on hover - it read only `checked`, despite being the control you
  // reach for most in a FormRow.
  color: {
    const base = checked ? Core.Theme.accent : Core.Theme.surfaceHover;
    if (mouse.pressed)
      return Core.Theme.stateLayer(base, Core.Style.opacityPressed);
    if (mouse.containsMouse)
      return Core.Theme.stateLayer(base, Core.Style.opacityHover);
    return base;
  }

  opacity: enabled ? 1.0 : Core.Style.opacityDisabled

  Behavior on opacity {
    AnimFast {}
  }

  Behavior on color {
    AnimFast {}
  }

  // Knob
  Rectangle {
    id: knob
    width: Core.Style.px(18)
    height: width
    radius: width / 2
    x: root.checked ? parent.width - width - Core.Style.px(3) : Core.Style.px(3)
    anchors.verticalCenter: parent.verticalCenter

    color: Core.Theme.text

    Behavior on x {
      AnimFast {}
    }
  }

  FocusRing {}

  // Space and Enter on the focused toggle: flip it, once per press.
  Keys.onPressed: event => {
    if (event.key !== Qt.Key_Space && event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter)
      return;
    event.accepted = true;
    if (!event.isAutoRepeat)
      root.toggled(!root.checked);
  }

  MouseArea {
    id: mouse

    anchors.fill: parent
    hoverEnabled: root.enabled
    enabled: root.enabled
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

    onClicked: root.toggled(!root.checked)
  }
}
