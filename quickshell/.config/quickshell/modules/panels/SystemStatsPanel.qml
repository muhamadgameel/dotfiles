pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import "../../components" as Components
import "../../core" as Core
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
Components.SlidingPanel {
  id: root

  panelId: "systemstats"

  // Header configuration
  headerIcon: Services.SystemStats.healthIcon
  headerTitle: "System Monitor"

  // ═══════════════════════════════════════════════════════════════════
  // CPU SECTION
  // ═══════════════════════════════════════════════════════════════════

  Components.SectionHeader {
    Layout.topMargin: Core.Style.spaceL
    icon: "cpu"
    title: "CPU"
  }

  Components.ProgressRow {
    Layout.fillWidth: true
    value: Services.SystemStats.cpuUsage / 100
    progressColor: root._statusColor(Services.SystemStats.cpuUsageStatus)
    progressHeight: Core.Style.px(8)
  }

  // Per-core breakdown.
  //
  // Bound to cpuCoreCount, not the cpuCores array: the array is replaced on
  // every poll, which rebuilt every delegate twice a second - and on a machine
  // with 32+ threads that is the whole section.
  Components.Collapsible {
    title: "Per-Core Details"
    expanded: false
    Layout.fillWidth: true
    visible: Services.SystemStats.cpuCoreCount > 0

    Repeater {
      model: Services.SystemStats.cpuCoreCount

      Components.ProgressRow {
        id: coreRow

        required property int index

        readonly property real usage: Services.SystemStats.cpuCores[index] ?? 0

        Layout.fillWidth: true
        label: "Core " + index
        labelInfo: Math.round(usage) + "%"
        value: usage / 100
        progressColor: usage > 90 ? Core.Theme.error : usage > 70 ? Core.Theme.warning : Core.Theme.accentAlt
        progressHeight: Core.Style.px(4)
        showPercentage: false
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // MEMORY SECTION
  // ═══════════════════════════════════════════════════════════════════

  Components.SectionHeader {
    Layout.topMargin: Core.Style.spaceXL
    icon: "memory"
    title: "Memory"
  }

  Components.ProgressRow {
    Layout.fillWidth: true
    label: "RAM"
    labelInfo: Core.Utils.formatBytes(Services.SystemStats.memUsed, 1) + " / " + Core.Utils.formatBytes(Services.SystemStats.memTotal, 1)
    value: Services.SystemStats.memPercent / 100
    progressColor: root._statusColor(Services.SystemStats.memStatus)
    progressHeight: Core.Style.px(8)
    showPercentage: false
  }

  Components.ProgressRow {
    Layout.fillWidth: true
    visible: Services.SystemStats.hasSwap
    label: "Swap"
    labelInfo: Core.Utils.formatBytes(Services.SystemStats.swapUsed, 1) + " / " + Core.Utils.formatBytes(Services.SystemStats.swapTotal, 1)
    value: Services.SystemStats.swapPercent / 100
    progressColor: Services.SystemStats.swapPercent > 50 ? Core.Theme.warning : Core.Theme.accentAlt
    progressHeight: Core.Style.px(6)
    showPercentage: false
  }

  // ═══════════════════════════════════════════════════════════════════
  // TEMPERATURE SECTION
  // ═══════════════════════════════════════════════════════════════════

  Components.SectionHeader {
    Layout.topMargin: Core.Style.spaceXL
    visible: Services.SystemStats.hasCpuTemp || Services.SystemStats.hasGpuTemp
    icon: "thermometer"
    title: "Temperatures"
  }

  // CPU Temperature
  Components.ProgressRow {
    Layout.fillWidth: true
    visible: Services.SystemStats.hasCpuTemp
    icon: "chip"
    iconColor: root._statusColor(Services.SystemStats.cpuTempStatus, Core.Theme.text)
    label: "CPU"
    value: Services.SystemStats.cpuTemp / 100
    valueText: Core.Utils.formatTemp(Services.SystemStats.cpuTemp)
    progressColor: root._statusColor(Services.SystemStats.cpuTempStatus, Core.Theme.success)
    progressHeight: Core.Style.px(6)
  }

  // GPU Temperature
  Components.ProgressRow {
    Layout.fillWidth: true
    visible: Services.SystemStats.hasGpuTemp
    icon: "gpu"
    iconColor: root._statusColor(Services.SystemStats.gpuTempStatus, Core.Theme.text)
    label: "GPU"
    value: Services.SystemStats.gpuTemp / 100
    valueText: Core.Utils.formatTemp(Services.SystemStats.gpuTemp)
    progressColor: root._statusColor(Services.SystemStats.gpuTempStatus, Core.Theme.success)
    progressHeight: Core.Style.px(6)
  }

  // No temperature sensors message
  Components.Text {
    visible: !Services.SystemStats.hasCpuTemp && !Services.SystemStats.hasGpuTemp
    text: "No temperature sensors detected"
    size: Core.Style.fontS
    color: Core.Theme.textMuted
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
  }

  // ═══════════════════════════════════════════════════════════════════
  // NETWORK SECTION
  // ═══════════════════════════════════════════════════════════════════

  Components.SectionHeader {
    Layout.topMargin: Core.Style.spaceXL
    icon: "network"
    title: "Network"
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
        color: Core.Theme.success
      }

      ColumnLayout {
        spacing: 0

        Components.Text {
          text: "Download"
          size: Core.Style.fontXS
          color: Core.Theme.textMuted
        }

        Components.Text {
          text: Core.Utils.formatSpeed(Services.SystemStats.netDownSpeed)
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
        color: Core.Theme.accent
      }

      ColumnLayout {
        spacing: 0

        Components.Text {
          text: "Upload"
          size: Core.Style.fontXS
          color: Core.Theme.textMuted
        }

        Components.Text {
          text: Core.Utils.formatSpeed(Services.SystemStats.netUpSpeed)
          size: Core.Style.fontM
          font.weight: Core.Style.weightBold
        }
      }
    }

    Components.Text {
      Layout.topMargin: Core.Style.spaceXS
      text: Services.SystemStats.netInterface ? "Interface: " + Services.SystemStats.netInterface : "No active interface"
      size: Core.Style.fontXS
      color: Core.Theme.textMuted
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // DISK SECTION
  // ═══════════════════════════════════════════════════════════════════

  Components.SectionHeader {
    Layout.topMargin: Core.Style.spaceXL
    icon: "disk"
    title: "Storage"
  }

  Components.ProgressRow {
    Layout.fillWidth: true
    label: Services.SystemStats.diskMount
    labelInfo: Core.Utils.formatBytes(Services.SystemStats.diskUsed, 1) + " / " + Core.Utils.formatBytes(Services.SystemStats.diskTotal, 1)
    value: Services.SystemStats.diskPercent / 100
    progressColor: root._statusColor(Services.SystemStats.diskStatus)
    progressHeight: Core.Style.px(10)
    showPercentage: false
  }

  Components.Text {
    text: Core.Utils.formatBytes(Services.SystemStats.diskTotal - Services.SystemStats.diskUsed, 1) + " free"
    size: Core.Style.fontXS
    color: Services.SystemStats.diskStatus !== "normal" ? Core.Theme.warning : Core.Theme.textMuted
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
      text: "Updates every " + (Services.SystemStats.pollingInterval / 1000) + "s"
      size: Core.Style.fontXS
      color: Core.Theme.textMuted
    }

    Components.Spacer {}

    // Health indicator
    RowLayout {
      spacing: Core.Style.spaceXS

      Components.StatusDot {
        size: Core.Style.px(8)
        color: root._statusColor(Services.SystemStats.healthStatus, Core.Theme.success)
      }

      Components.Text {
        text: root._healthText(Services.SystemStats.healthStatus)
        size: Core.Style.fontXS
        color: Core.Theme.textMuted
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
      return Core.Theme.error;
    if (status === "warning")
      return Core.Theme.warning;
    return normalColor !== undefined ? normalColor : Core.Theme.accent;
  }

  function _healthText(status) {
    if (status === "critical")
      return "Critical";
    if (status === "warning")
      return "Warning";
    return "Healthy";
  }
}
