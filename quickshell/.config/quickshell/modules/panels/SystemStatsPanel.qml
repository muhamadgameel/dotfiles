import QtQuick
import QtQuick.Layouts

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core
import "../../layouts" as Layouts
import "../../services" as Services

/**
* SystemStatsPanel - Detailed system monitoring panel
*
* Displays comprehensive system information:
* - CPU usage with per-core breakdown
* - Memory usage (RAM + Swap)
* - Temperatures (CPU + GPU)
* - Network throughput
* - Disk usage
*/
Layouts.SlidingPanel {
  id: root

  namespace: "quickshell-systemstats"
  hasBackdrop: true

  // Header configuration
  headerIcon: Services.SystemStats.healthIcon
  headerTitle: "System Monitor"

  // ═══════════════════════════════════════════════════════════════════
  // CPU SECTION
  // ═══════════════════════════════════════════════════════════════════

  // size: Core.Style.spaceXL
  Components.Spacer {}

  Components.Text {
    icon: "cpu"
    text: "CPU"
    size: Core.Style.fontXL
    weight: Core.Style.weightBold
  }

  Layouts.ProgressRow {
    Layout.fillWidth: true
    value: Services.SystemStats.cpuUsage / 100
    progressColor: _statusColor(Services.SystemStats.cpuUsageStatus)
    progressHeight: 8
  }

  // Per-core breakdown
  Layouts.Collapsible {
    title: "Per-Core Details"
    expanded: false
    Layout.fillWidth: true
    visible: Services.SystemStats.cpuCores.length > 0

    Repeater {
      model: Services.SystemStats.cpuCores

      Layouts.ProgressRow {
        Layout.fillWidth: true
        label: "Core " + index
        labelInfo: Math.round(modelData) + "%"
        value: modelData / 100
        progressColor: modelData > 90 ? Config.Theme.error : modelData > 70 ? Config.Theme.warning : Config.Theme.accentAlt
        progressHeight: 4
        showPercentage: false
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // MEMORY SECTION
  // ═══════════════════════════════════════════════════════════════════

  Components.Text {
    Layout.topMargin: Core.Style.spaceXL
    icon: "memory"
    text: "Memory"
    size: Core.Style.fontXL
    weight: Core.Style.weightBold
  }

  Layouts.ProgressRow {
    Layout.fillWidth: true
    label: "RAM"
    labelInfo: Services.SystemStats.formatBytes(Services.SystemStats.memUsed, 1) + " / " + Services.SystemStats.formatBytes(Services.SystemStats.memTotal, 1)
    value: Services.SystemStats.memPercent / 100
    progressColor: _statusColor(Services.SystemStats.memStatus)
    progressHeight: 8
    showPercentage: false
  }

  Layouts.ProgressRow {
    Layout.fillWidth: true
    visible: Services.SystemStats.hasSwap
    label: "Swap"
    labelInfo: Services.SystemStats.formatBytes(Services.SystemStats.swapUsed, 1) + " / " + Services.SystemStats.formatBytes(Services.SystemStats.swapTotal, 1)
    value: Services.SystemStats.swapPercent / 100
    progressColor: Services.SystemStats.swapPercent > 50 ? Config.Theme.warning : Config.Theme.accentAlt
    progressHeight: 6
    showPercentage: false
  }

  // ═══════════════════════════════════════════════════════════════════
  // TEMPERATURE SECTION
  // ═══════════════════════════════════════════════════════════════════

  Components.Text {
    Layout.topMargin: Core.Style.spaceXL
    visible: Services.SystemStats.hasCpuTemp || Services.SystemStats.hasGpuTemp
    icon: "thermometer"
    text: "Temperatures"
    size: Core.Style.fontXL
    weight: Core.Style.weightBold
  }

  // CPU Temperature
  Layouts.ProgressRow {
    Layout.fillWidth: true
    visible: Services.SystemStats.hasCpuTemp
    icon: "chip"
    iconColor: _statusColor(Services.SystemStats.cpuTempStatus, Config.Theme.text)
    label: "CPU"
    value: Services.SystemStats.cpuTemp / 100
    valueText: Services.SystemStats.formatTemp(Services.SystemStats.cpuTemp)
    progressColor: _statusColor(Services.SystemStats.cpuTempStatus, Config.Theme.success)
    progressHeight: 6
  }

  // GPU Temperature
  Layouts.ProgressRow {
    Layout.fillWidth: true
    visible: Services.SystemStats.hasGpuTemp
    icon: "gpu"
    iconColor: _statusColor(Services.SystemStats.gpuTempStatus, Config.Theme.text)
    label: "GPU"
    value: Services.SystemStats.gpuTemp / 100
    valueText: Services.SystemStats.formatTemp(Services.SystemStats.gpuTemp)
    progressColor: _statusColor(Services.SystemStats.gpuTempStatus, Config.Theme.success)
    progressHeight: 6
  }

  // No temperature sensors message
  Components.Text {
    visible: !Services.SystemStats.hasCpuTemp && !Services.SystemStats.hasGpuTemp
    text: "No temperature sensors detected"
    size: Core.Style.fontS
    color: Config.Theme.textMuted
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
  }

  // ═══════════════════════════════════════════════════════════════════
  // NETWORK SECTION
  // ═══════════════════════════════════════════════════════════════════

  Components.Text {
    Layout.topMargin: Core.Style.spaceXL
    icon: "network"
    text: "Network"
    size: Core.Style.fontXL
    weight: Core.Style.weightBold
  }

  GridLayout {
    Layout.fillWidth: true
    columns: 2
    rowSpacing: Core.Style.spaceS
    columnSpacing: Core.Style.spaceL

    // Download
    RowLayout {
      spacing: Core.Style.spaceS

      Components.Icon {
        icon: "arrow-down"
        size: Core.Style.fontL
        color: Config.Theme.success
      }

      ColumnLayout {
        spacing: 0

        Components.Text {
          text: "Download"
          size: Core.Style.fontXS
          color: Config.Theme.textMuted
        }

        Components.Text {
          text: Services.SystemStats.formatSpeed(Services.SystemStats.netDownSpeed)
          size: Core.Style.fontM
          font.weight: Core.Style.weightBold
        }
      }
    }

    // Upload
    RowLayout {
      spacing: Core.Style.spaceS

      Components.Icon {
        icon: "arrow-up"
        size: Core.Style.fontL
        color: Config.Theme.accent
      }

      ColumnLayout {
        spacing: 0

        Components.Text {
          text: "Upload"
          size: Core.Style.fontXS
          color: Config.Theme.textMuted
        }

        Components.Text {
          text: Services.SystemStats.formatSpeed(Services.SystemStats.netUpSpeed)
          size: Core.Style.fontM
          font.weight: Core.Style.weightBold
        }
      }
    }

    Components.Text {
      Layout.topMargin: Core.Style.spaceXS
      text: Services.SystemStats.netInterface ? "Interface: " + Services.SystemStats.netInterface : "No active interface"
      size: Core.Style.fontXS
      color: Config.Theme.textMuted
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // DISK SECTION
  // ═══════════════════════════════════════════════════════════════════

  Components.Text {
    Layout.topMargin: Core.Style.spaceXL
    icon: "disk"
    text: "Storage"
    size: Core.Style.fontXL
    weight: Core.Style.weightBold
  }

  Layouts.ProgressRow {
    Layout.fillWidth: true
    label: Services.SystemStats.diskMount
    labelInfo: Services.SystemStats.formatBytes(Services.SystemStats.diskUsed, 1) + " / " + Services.SystemStats.formatBytes(Services.SystemStats.diskTotal, 1)
    value: Services.SystemStats.diskPercent / 100
    progressColor: _statusColor(Services.SystemStats.diskStatus)
    progressHeight: 10
    showPercentage: false
  }

  Components.Text {
    text: Services.SystemStats.formatBytes(Services.SystemStats.diskTotal - Services.SystemStats.diskUsed, 1) + " free"
    size: Core.Style.fontXS
    color: Services.SystemStats.diskStatus !== "normal" ? Config.Theme.warning : Config.Theme.textMuted
  }

  // ═══════════════════════════════════════════════════════════════════
  // FOOTER
  // ═══════════════════════════════════════════════════════════════════

  Components.Divider {
    Layout.topMargin: Core.Style.spaceS
  }

  RowLayout {
    Layout.fillWidth: true

    Components.Text {
      text: "Updates every 2s"
      size: Core.Style.fontXS
      color: Config.Theme.textMuted
    }

    Components.Spacer {}

    // Health indicator
    RowLayout {
      spacing: Core.Style.spaceXS

      Components.StatusDot {
        size: 8
        color: _statusColor(Services.SystemStats.healthStatus, Config.Theme.success)
      }

      Components.Text {
        text: _healthText(Services.SystemStats.healthStatus)
        size: Core.Style.fontXS
        color: Config.Theme.textMuted
      }
    }
  }

  Components.Spacer {
    size: Core.Style.spaceL
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPER FUNCTIONS
  // ═══════════════════════════════════════════════════════════════════

  function _statusColor(status, normalColor) {
    if (status === "critical")
      return Config.Theme.error;
    if (status === "warning")
      return Config.Theme.warning;
    return normalColor !== undefined ? normalColor : Config.Theme.accent;
  }

  function _healthText(status) {
    if (status === "critical")
      return "Critical";
    if (status === "warning")
      return "Warning";
    return "Healthy";
  }
}
