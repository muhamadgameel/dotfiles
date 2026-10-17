import QtQuick

import "../../../components" as Components
import "../../../core" as Core
import "../../../services" as Services

/**
* IdleInhibitor - keep-awake toggle
*
* Deliberately loud when active: an inhibitor left on by accident drains the
* battery silently, so it gets an accent colour and a pulsing dot rather than a
* subtle state change.
*/
BarButton {
  id: root

  icon: Services.Idle.statusIcon
  iconColor: Core.Theme.warning

  tooltipText: "Keeping the screen awake\n\nClick to allow sleeping again"

  onClicked: Services.Idle.toggle()
}
