import QtQuick
import QtQuick.Layouts

import "../../core" as Core

/**
* BarGroup - related bar widgets on one shared background
*
* The group only draws the pill behind them; each widget keeps its own clicks,
* scroll and tooltip.
*
* It does not hide itself when every widget inside is hidden: hiding it hides
* the widgets too, so it could never tell when one came back. It shrinks to
* nothing instead.
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

  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight

  // A little more room between groups than between the widgets inside one.
  Layout.leftMargin: Core.Style.spaceXXS
  Layout.rightMargin: Core.Style.spaceXXS
  radius: Core.Style.radiusS
  // Solid surface: cardBg's half alpha vanished against the translucent bar.
  // Hovering a widget still shows, as surfaceHover.
  color: Core.Theme.surface

  RowLayout {
    id: row

    anchors.fill: parent
    spacing: 0
  }
}
