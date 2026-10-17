import QtQuick
import QtQuick.Layouts

import "../../core" as Core

/**
* BarGroup - related bar widgets on one shared background
*
* The group only draws the pill behind them; each widget keeps its own clicks,
* scroll and tooltip.
*
* It hides while none of its widgets is `wanted`; a widget that does not say
* counts as wanted. It cannot go by their `visible`: hiding the group hides the
* widgets too, so it could never tell when one came back.
*
* Usage:
*   BarGroup {
*     Widgets.Volume {}
*     Widgets.Microphone {}
*   }
*/
Rectangle {
  id: root

  default property alias content: row.data

  visible: row.children.some(widget => widget.wanted ?? true)
  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight
  radius: height / 2
  // Solid surface: cardBg's half alpha vanished against the translucent bar.
  // Hovering a widget still shows, as surfaceHover.
  color: Core.Theme.surface

  RowLayout {
    id: row

    anchors.fill: parent
    spacing: 0
  }
}
