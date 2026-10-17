import QtQuick

import "../../../components" as Components
import "../../../core" as Core

/**
* BarButton - a button at the bar's height, round like the pills it sits in
*
* `dot` shows a small pulsing dot under the icon in that colour; transparent
* shows none. `dotLoops` is how many times it pulses when it appears.
*/
Components.Button {
  id: root

  property color dot: Core.Theme.transparent
  property alias dotLoops: statusDot.pulseLoops

  implicitHeight: Core.Style.widgetSize
  radius: height / 2

  Components.StatusDot {
    id: statusDot
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottomMargin: Core.Style.spaceXXS
    visible: root.dot.a > 0
    pulse: true
    color: root.dot
  }
}
