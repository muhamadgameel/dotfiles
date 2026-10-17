import QtQuick

import "../../../services" as Services

/**
* KeyboardLayout - the active layout as two letters; a click moves to the next
*/
BarButton {
  text: Services.KeyboardLayout.label
  tooltipText: `${Services.KeyboardLayout.name}\n\nClick: Next layout`
  onClicked: Services.KeyboardLayout.next()
}
