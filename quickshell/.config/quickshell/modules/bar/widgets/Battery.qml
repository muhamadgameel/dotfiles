import QtQuick
import Quickshell.Services.UPower

import "../../../components" as Components
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
BarButton {
  id: root

  signal panelRequested

  // === Configuration ===
  readonly property real lowThreshold: 30
  readonly property real criticalThreshold: 15

  // === UPower State ===
  readonly property var battery: UPower.displayDevice
  readonly property bool hasBattery: battery?.type === UPowerDeviceType.Battery && (battery.isPresent ?? battery.ready)
  readonly property bool isReady: hasBattery && battery.ready && battery.percentage !== undefined
  readonly property real percent: isReady ? battery.percentage * 100 : 0

  // Battery states
  readonly property bool isOnBattery: UPower.onBattery
  readonly property bool isCharging: isReady && battery.state === UPowerDeviceState.Charging
  readonly property bool isDischarging: isReady && battery.state === UPowerDeviceState.Discharging
  readonly property bool isLow: isReady && !isCharging && percent <= lowThreshold
  readonly property bool isCritical: isReady && !isCharging && percent <= criticalThreshold

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
      return Core.Theme.textMuted;
    if (isCharging)
      return Core.Theme.success;
    if (isCritical)
      return Core.Theme.error;
    if (isLow)
      return Core.Theme.warning;
    return Core.Theme.text;
  }

  text: isReady ? Math.round(percent) + "%" : "--"
  textColor: iconColor

  // === Tooltip ===
  tooltipText: {
    if (!isReady)
      return "Battery status unavailable";

    let lines = [];

    // Status
    if (isCharging) {
      lines.push("Charging (" + Math.round(percent) + "%)");
    } else {
      lines.push("On battery (" + Math.round(percent) + "%)");
    }

    // Time remaining
    if (isDischarging && battery.timeToEmpty > 0) {
      lines.push(Core.Icons.get("clock") + "  " + Core.Utils.formatDuration(battery.timeToEmpty) + " remaining");
    } else if (isCharging && battery.timeToFull > 0) {
      lines.push(Core.Icons.get("clock") + "  " + Core.Utils.formatDuration(battery.timeToFull) + " until full");
    }

    // Power rate
    if (battery.changeRate) {
      lines.push("⚡ " + Math.abs(battery.changeRate).toFixed(1) + " W");
    }

    // Health
    if (battery.healthPercentage > 0) {
      lines.push(Core.Icons.get("heart") + "   " + "Health: " + Math.round(battery.healthPercentage) + "%");
    }

    lines.push("");
    lines.push("Click for details");

    return lines.join("\n");
  }

  // === Click to open panel ===
  onClicked: root.panelRequested()

  // === Visual Indicators ===

  // Charging indicator
  Components.StatusDot {
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottomMargin: Core.Style.spaceXXS
    visible: root.isCharging
    pulse: true
    color: Core.Theme.success
  }

  // Critical battery warning overlay
  Components.WarningOverlay {
    active: root.isCritical
    severity: "critical"
  }
}
