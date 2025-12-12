import QtQuick

import "../../../components" as Components
import "../../../config" as Config
import "../../../services" as Services

Components.Button {
  id: root

  // TODO: Connect to actual brightness service
  property real brightness: 0.8

  icon: _getBrightnessIcon(brightness)

  tooltipText: Math.round(brightness * 100) + "%"

  function _getBrightnessIcon(value) {
    if (value < 0.33)
      return "brightness-low";
    if (value <= 0.66)
      return "brightness-medium";
    return "brightness-high";
  }

  onClicked: {
    // Demo: cycle through brightness levels
    brightness = (brightness + 0.1) % 1.1;
    if (brightness > 1.0)
      brightness = 0.1;

    Services.OSD.show("progressRow", {
      icon: _getBrightnessIcon(brightness),
      value: brightness,
      maxValue: 1.0,
      iconColor: Config.Theme.text,
      progressColor: Config.Theme.accent
    });
  }
}
