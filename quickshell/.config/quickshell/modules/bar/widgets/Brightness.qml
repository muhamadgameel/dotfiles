import QtQuick

import "../../../components" as Components
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

  icon: Services.Brightness.getIcon()

  text: Services.Brightness.ready ? Math.round(Services.Brightness.brightness * 100) + "%" : "--"

  tooltipText: {
    if (!Services.Brightness.ready)
      return "Brightness control unavailable";

    let lines = [];
    lines.push("Brightness: " + Math.round(Services.Brightness.brightness * 100) + "%");

    if (Services.Brightness.device) {
      lines.push(Core.Icons.get("monitor") + "  " + Services.Brightness.device);
    }

    lines.push("");
    lines.push("Scroll: Adjust brightness");
    lines.push("Left click: Set to 50%");
    lines.push("Right click: Toggle min/max");

    return lines.join("\n");
  }

  // Scroll to adjust brightness
  onWheel: function (wheel) {
    // A sideways touchpad swipe has no vertical delta; it used to count as down.
    if (wheel.angleDelta.y === 0)
      return;
    if (wheel.angleDelta.y > 0) {
      Services.Brightness.increase();
    } else {
      Services.Brightness.decrease();
    }
  }

  // Click handlers
  onClicked: function (button) {
    if (button === Qt.RightButton) {
      // Toggle between low (10%) and high (100%)
      if (Services.Brightness.brightness > 0.5) {
        Services.Brightness.set(0.1);
      } else {
        Services.Brightness.set(1.0);
      }
    } else if (button === Qt.LeftButton) {
      // Set to 50%
      Services.Brightness.set(0.5);
    }
  }
}
