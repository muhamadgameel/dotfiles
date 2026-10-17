import QtQuick

import "../../../core" as Core
import "../../../services" as Services

/**
* IdleInhibitor - keep-awake toggle
*
* Deliberately loud when active: an inhibitor left on by accident drains the
* battery silently, so it gets an accent colour rather than a subtle state change.
*
* - Click: allow sleeping again
*/
BarButton {
  id: root

  icon: Services.Idle.statusIcon
  iconColor: Core.Theme.warning

  tooltipText: "Keeping the screen awake"

  onClicked: Services.Idle.toggle()
}
