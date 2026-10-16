import QtQuick

import "../core" as Core

/**
* FocusRing - the keyboard focus outline of a control
*
* Declared inside the control. Drawn outside it, so it never eats into the
* content box.
*/
Rectangle {
  readonly property Rectangle control: parent as Rectangle

  anchors.fill: parent
  anchors.margins: -Core.Style.focusRingOffset
  z: -1

  visible: control.activeFocus
  color: Core.Theme.transparent
  radius: control.radius + Core.Style.focusRingOffset
  border.color: Core.Theme.focusRing
  border.width: Core.Style.focusRingWidth
}
