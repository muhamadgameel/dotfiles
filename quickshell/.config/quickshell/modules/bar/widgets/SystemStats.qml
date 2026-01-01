import QtQuick

import "../../../components" as Components
import "../../../config" as Config
import "../../../core" as Core
import "../../../services" as Services

/**
* SystemStats - Compact bar widget showing system health overview
*
* Features:
* - Dynamic icon based on system health (healthy/warning/critical)
* - Primary metric display (CPU%)
* - Rich tooltip with all system stats
* - Click to open detailed panel
*
* Design: Compact single-indicator that expands on hover/click
*/
Components.Button {
  id: root

  signal panelRequested

  // === Icon ===
  icon: Services.SystemStats.healthIcon
  iconSize: Core.Style.fontL

  iconColor: {
    switch (Services.SystemStats.healthStatus) {
    case "critical":
      return Config.Theme.error;
    case "warning":
      return Config.Theme.warning;
    default:
      return Config.Theme.text;
    }
  }

  // === Primary Metric (CPU) ===
  text: Math.round(Services.SystemStats.cpuUsage) + "%"
  textColor: iconColor

  // === Rich Tooltip ===
  tooltipText: {
    const stats = Services.SystemStats;
    let lines = [];

    // Header
    lines.push("󰓅  System Monitor");
    lines.push("─────────────────");

    // CPU
    const cpuIcon = stats.cpuUsage > 70 ? "󰈸" : "";
    lines.push(cpuIcon + " CPU: " + Math.round(stats.cpuUsage) + "%");

    // Memory
    const memIcon = "";
    const memUsed = stats.formatBytes(stats.memUsed, 1);
    const memTotal = stats.formatBytes(stats.memTotal, 1);
    lines.push(memIcon + " RAM: " + memUsed + " / " + memTotal + " (" + stats.memPercent + "%)");

    // Swap (only if in use)
    if (stats.hasSwap) {
      const swapUsed = stats.formatBytes(stats.swapUsed, 1);
      const swapTotal = stats.formatBytes(stats.swapTotal, 1);
      lines.push(" Swap: " + swapUsed + " / " + swapTotal + " (" + stats.swapPercent + "%)");
    }

    // Temperatures
    if (stats.hasCpuTemp || stats.hasGpuTemp) {
      lines.push("");
      if (stats.hasCpuTemp) {
        const tempIcon = stats.cpuTemp > 70 ? "󰔐" : "󰔏";
        lines.push(tempIcon + "  CPU: " + stats.formatTemp(stats.cpuTemp));
      }
      if (stats.hasGpuTemp) {
        const gpuIcon = stats.gpuTemp > 70 ? "󰢮" : "󰢮";
        lines.push(gpuIcon + "  GPU: " + stats.formatTemp(stats.gpuTemp));
      }
    }

    // Network
    lines.push("");
    lines.push("󰛳 Network:");
    lines.push("↓ " + stats.formatSpeed(stats.netDownSpeed));
    lines.push("↑ " + stats.formatSpeed(stats.netUpSpeed));

    // Disk
    lines.push("");
    const diskIcon = stats.diskPercent > 85 ? "󰋊" : "󰋊";
    const diskUsed = stats.formatBytes(stats.diskUsed, 1);
    const diskTotal = stats.formatBytes(stats.diskTotal, 1);
    lines.push(diskIcon + "  Disk (/): " + diskUsed + " / " + diskTotal + " (" + stats.diskPercent + "%)");

    // Footer hint
    lines.push("");
    lines.push("Click for details");

    return lines.join("\n");
  }

  // === Click to open panel ===
  onClicked: function (button) {
    if (button === Qt.LeftButton) {
      root.panelRequested();
    }
  }

  // === Visual Indicators ===

  // Warning/critical flash overlay
  Components.WarningOverlay {
    active: Services.SystemStats.healthStatus !== "healthy"
    severity: Services.SystemStats.healthStatus
  }
}
