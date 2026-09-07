import QtQuick

import "../../components" as Components
import "../../config" as Config
import "../../services" as Services

/**
* OSDLayouts - the bodies the OSD can display
*
* Services.OSD carries a layout name and a payload; this maps the name to a
* Component and reads the payload's fields. Adding a kind of OSD means adding a
* Component here and naming it in the switch, with no change to the window,
* the timer, or the show/hide plumbing.
*
* Every field is read with a default, so a caller that omits one gets a sane
* value instead of a binding error.
*/
Item {
  id: root

  // === Public API ===

  function getComponent(type) {
    switch (type) {
    case "progressRow":
      return progressRowComponent;
    default:
      return null;
    }
  }

  // === Layout Components ===

  Component {
    id: progressRowComponent
    Components.ProgressRow {
      icon: Services.OSD.payload.icon ?? ""
      iconColor: Services.OSD.payload.iconColor ?? Config.Theme.text
      value: Services.OSD.payload.value ?? 0
      maxValue: Services.OSD.payload.maxValue ?? 1
      progressColor: Services.OSD.payload.progressColor ?? Config.Theme.accent
      valueText: Services.OSD.payload.valueText ?? ""
    }
  }
}
