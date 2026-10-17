import QtQuick

import "../../../components" as Components
import "../../../core" as Core
import "../../../services" as Services

/**
* SystemStats - Compact bar widget showing system health overview
*
* Features:
* - Dynamic icon based on system health (healthy/warning/critical)
* - Primary metric display (CPU%)
* - Tooltip with CPU, memory and temperatures; the panel has the rest
* - Click to open detailed panel
*
* Design: Compact single-indicator that expands on hover/click
*/
BarButton {
  id: root

  signal panelRequested

  // === Icon ===
  icon: Services.SystemStats.healthIcon

  iconColor: Core.Theme.statusColor(Services.SystemStats.healthStatus, Core.Theme.text)

  // === Primary Metric (CPU) ===
  text: Math.round(Services.SystemStats.cpuUsage) + "%"
  textColor: iconColor

  // === Tooltip ===
  tooltipText: {
    const s = Services.SystemStats;
    const parts = [`CPU ${Math.round(s.cpuUsage)}%${s.hasCpuTemp ? ` at ${Core.Utils.formatTemp(s.cpuTemp)}` : ""}`, `RAM ${Core.Utils.formatBytes(s.memUsed, 1)} of ${Core.Utils.formatBytes(s.memTotal, 1)}`];
    if (s.hasGpuTemp)
      parts.push(`GPU at ${Core.Utils.formatTemp(s.gpuTemp)}`);
    return parts.join(" · ");
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
