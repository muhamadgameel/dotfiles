import QtQuick

import "../../config" as Config
import "../../layouts" as Layouts
import "../../services" as Services

Item {
  id: root

  // === Public API ===

  function getComponent(type) {
    switch (type) {
    case "progressRow":
      return progressRowComponent;
    case "iconLabel":
      return iconLabelComponent;
    default:
      return null;
    }
  }

  // === Layout Components ===

  Component {
    id: progressRowComponent
    Layouts.ProgressRow {
      icon: Services.OSD.data.icon ?? ""
      iconColor: Services.OSD.data.iconColor ?? Config.Theme.text
      value: Services.OSD.data.value ?? 0
      maxValue: Services.OSD.data.maxValue ?? 1
      progressColor: Services.OSD.data.progressColor ?? Config.Theme.accent
    }
  }

  Component {
    id: iconLabelComponent
    Layouts.IconLabel {
      icon: Services.OSD.data.icon ?? ""
      iconColor: Services.OSD.data.iconColor ?? Config.Theme.text
      label: Services.OSD.data.label ?? ""
    }
  }
}
