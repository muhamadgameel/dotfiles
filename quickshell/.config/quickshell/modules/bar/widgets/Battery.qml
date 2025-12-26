import QtQuick
import Quickshell.Services.UPower

import "../../../components" as Components
import "../../../config" as Config
import "../../../core" as Core

/**
* Battery - Bar widget showing battery status
*
* Features:
* - Battery percentage display with dynamic icon
* - Charging animation with pulsing indicator
* - Low/critical battery warning with color indication
* - Tooltip with detailed info (time remaining, health, power rate)
*/
Components.Button {
  id: root

  // === Configuration ===
  readonly property real lowThreshold: 20
  readonly property real criticalThreshold: 10

  // === UPower State ===
  readonly property var battery: UPower.displayDevice
  readonly property bool hasBattery: battery?.type === UPowerDeviceType.Battery && (battery.isPresent ?? battery.ready)
  readonly property bool isReady: hasBattery && battery.ready && battery.percentage !== undefined
  readonly property real percent: isReady ? battery.percentage * 100 : 0

  // Battery states
  readonly property bool isCharging: isReady && battery.state === UPowerDeviceState.Charging
  readonly property bool isFullyCharged: isReady && battery.state === UPowerDeviceState.FullyCharged
  readonly property bool isDischarging: isReady && battery.state === UPowerDeviceState.Discharging
  readonly property bool isLow: isReady && !isCharging && percent <= lowThreshold
  readonly property bool isCritical: isReady && !isCharging && percent <= criticalThreshold

  // Hide when no battery present (desktop/AC only)
  visible: hasBattery

  // === Display ===
  icon: {
    if (!isReady)
      return "battery-unknown";
    if (isCharging)
      return "battery-charging";
    if (percent >= 90)
      return "battery-full";
    if (percent >= 60)
      return "battery-high";
    if (percent >= 30)
      return "battery-medium";
    if (percent >= 10)
      return "battery-low";
    return "battery-critical";
  }

  iconColor: {
    if (!isReady)
      return Config.Theme.textMuted;
    if (isFullyCharged)
      return Config.Theme.text;
    if (isCharging)
      return Config.Theme.success;
    if (isCritical)
      return Config.Theme.error;
    if (isLow)
      return Config.Theme.warning;
    return Config.Theme.text;
  }

  text: isFullyCharged ? "" : isReady ? Math.round(percent) + "%" : "--"
  textColor: iconColor

  // === Tooltip ===
  tooltipText: {
    if (!isReady)
      return "Battery status unavailable";

    let lines = [];

    // Status
    if (isFullyCharged) {
      lines.push("Fully charged");
    } else if (isCharging) {
      lines.push("Charging (" + Math.round(percent) + "%)");
    } else {
      lines.push("On battery (" + Math.round(percent) + "%)");
    }

    // Time remaining
    if (isDischarging && battery.timeToEmpty > 0) {
      lines.push(Config.Icons.get("clock") + "  " + Core.Utils.formatDuration(battery.timeToEmpty) + " remaining");
    } else if (isCharging && battery.timeToFull > 0) {
      lines.push(Config.Icons.get("clock") + "  " + Core.Utils.formatDuration(battery.timeToFull) + " until full");
    }

    // Power rate
    if (battery.changeRate) {
      lines.push("⚡ " + Math.abs(battery.changeRate).toFixed(1) + " W");
    }

    // Health
    if (battery.healthPercentage > 0) {
      lines.push(Config.Icons.get("heart") + "   " + "Health: " + Math.round(battery.healthPercentage) + "%");
    }

    return lines.join("\n");
  }

  // === Visual Indicators ===

  // Charging indicator
  Components.PulsingDot {
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottomMargin: 2
    active: root.isCharging
    color: Config.Theme.success
  }

  // Critical battery warning pulse
  Rectangle {
    anchors.fill: parent
    radius: parent.radius
    color: Config.Theme.error
    opacity: 0
    visible: root.isCritical

    SequentialAnimation on opacity {
      running: root.isCritical
      loops: Animation.Infinite

      NumberAnimation {
        to: 0.2
        duration: Core.Style.animSlow * 2
        easing.type: Easing.InOutQuad
      }

      NumberAnimation {
        to: 0
        duration: Core.Style.animSlow * 2
        easing.type: Easing.InOutQuad
      }
    }
  }
}
