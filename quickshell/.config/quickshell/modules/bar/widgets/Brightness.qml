import QtQuick

import "../../../components" as Components
import "../../../config" as Config
import "../../../core" as Core
import "../../../services" as Services

/**
* Brightness - Bar widget for display backlight control
*
* Features:
* - Dynamic icon based on brightness level
* - Scroll to adjust brightness
* - Click to toggle between min/max
* - Middle-click to set to 50%
* - Tooltip showing percentage and device info
*/
Components.Button {
  id: root

  // Hide when no backlight device is available (desktops without backlight)
  visible: Services.Brightness.ready

  icon: Services.Brightness.getIcon()
  iconSize: Core.Style.fontL

  text: Services.Brightness.ready ? Math.round(Services.Brightness.brightness * 100) + "%" : "--"

  tooltipText: {
    if (!Services.Brightness.ready)
      return "Brightness control unavailable";

    let lines = [];
    lines.push("Brightness: " + Math.round(Services.Brightness.brightness * 100) + "%");

    if (Services.Brightness.device) {
      lines.push(Config.Icons.get("monitor") + "  " + Services.Brightness.device);
    }

    lines.push("");
    lines.push("Scroll: Adjust brightness");
    lines.push("Click: Toggle min/max");
    lines.push("Middle-click: Set to 50%");

    return lines.join("\n");
  }

  // Scroll to adjust brightness
  onWheel: function (wheel) {
    if (wheel.angleDelta.y > 0) {
      Services.Brightness.increase();
    } else {
      Services.Brightness.decrease();
    }
  }

  // Click handlers
  onClicked: function (button) {
    if (button === Qt.LeftButton) {
      // Toggle between low (10%) and high (100%)
      if (Services.Brightness.brightness > 0.5) {
        Services.Brightness.set(0.1);
      } else {
        Services.Brightness.set(1.0);
      }
    } else if (button === Qt.MiddleButton) {
      // Set to 50%
      Services.Brightness.set(0.5);
    }
  }
}
