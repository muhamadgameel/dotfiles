pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core
import "../../services" as Services

/**
* SystemStatsPanel - Detailed system monitoring panel
*
* Displays comprehensive system information:
* - CPU usage with per-core breakdown and top apps
* - Memory usage (RAM + Swap) and top apps
* - GPU usage, VRAM, power and VRAM by process (NVIDIA)
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
    value: Services.SystemStats.cpuUsage / 100
    progressColor: Core.Theme.statusColor(Services.SystemStats.cpuUsageStatus)
    progressHeight: Core.Style.progressHeightL
  }

  Components.Sparkline {
    Layout.fillWidth: true
    values: Services.SystemStats.cpuHistory.map(v => v / 100)
    count: Services.SystemStats.historyLength
    color: Core.Theme.statusColor(Services.SystemStats.cpuUsageStatus)
  }

  // Per-core breakdown.
  //
  // Bound to cpuCoreCount, not the cpuCores array: the array is replaced on
  // every poll, which rebuilt every delegate twice a second - and on a machine
  // with 32+ threads that is the whole section.
  Components.Collapsible {
    title: "Per-Core Details"
    Layout.fillWidth: true
    visible: Services.SystemStats.cpuCoreCount > 0

    Repeater {
      model: Services.SystemStats.cpuCoreCount

      Components.ProgressRow {
        id: coreRow

        required property int index

        readonly property real usage: Services.SystemStats.cpuCores[index] ?? 0

        label: "Core " + index
        labelInfo: Math.round(usage) + "%"
        value: usage / 100
        progressColor: Core.Theme.statusColor(Services.SystemStats.statusLevel(usage, Config.Config.cpuUsageWarning, Config.Config.cpuUsageCritical), Core.Theme.accentAlt)
        progressHeight: Core.Style.progressHeightS
        showPercentage: false
      }
    }
  }

  Components.Collapsible {
    title: "Top Apps"
    Layout.fillWidth: true

    Repeater {
      model: Services.SystemStats.topCpuApps.length

      AppRow {
        required property int index

        app: Services.SystemStats.topCpuApps[index] ?? root._noApp
        detail: root._appDetail(app.value < 0.1 ? "<0.1%" : app.value.toFixed(1) + "%", app.count)
        fraction: app.value / 100
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
    label: "RAM"
    labelInfo: Core.Utils.formatBytes(Services.SystemStats.memUsed, 1) + " / " + Core.Utils.formatBytes(Services.SystemStats.memTotal, 1)
    value: Services.SystemStats.memPercent / 100
    progressColor: Core.Theme.statusColor(Services.SystemStats.memStatus)
    progressHeight: Core.Style.progressHeightL
    showPercentage: false
  }

  Components.Sparkline {
    Layout.fillWidth: true
    values: Services.SystemStats.memHistory.map(v => v / 100)
    count: Services.SystemStats.historyLength
    color: Core.Theme.statusColor(Services.SystemStats.memStatus)
  }

  Components.ProgressRow {
    visible: Services.SystemStats.hasSwap
    label: "Swap"
    labelInfo: Core.Utils.formatBytes(Services.SystemStats.swapUsed, 1) + " / " + Core.Utils.formatBytes(Services.SystemStats.swapTotal, 1)
    value: Services.SystemStats.swapPercent / 100
    progressColor: Services.SystemStats.swapPercent > 50 ? Core.Theme.warning : Core.Theme.accentAlt
    progressHeight: Core.Style.progressHeightM
    showPercentage: false
  }

  Components.Collapsible {
    title: "Top Apps"
    Layout.fillWidth: true

    Repeater {
      model: Services.SystemStats.topMemoryApps.length

      AppRow {
        required property int index

        app: Services.SystemStats.topMemoryApps[index] ?? root._noApp
        detail: root._appDetail(Core.Utils.formatBytes(app.value, 1), app.count)
        fraction: app.value / Services.SystemStats.memTotal
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // GPU SECTION
  // ═══════════════════════════════════════════════════════════════════

  Components.SectionHeader {
    Layout.topMargin: Core.Style.spaceXL
    visible: Services.SystemStats.hasGpuDetails
    icon: "gpu"
    title: "GPU"

    Components.Text {
      text: Services.SystemStats.gpuName.replace(/^NVIDIA (GeForce )?/, "")
      size: Core.Style.fontXS
      color: Core.Theme.textDim
    }
  }

  Components.ProgressRow {
    visible: Services.SystemStats.hasGpuDetails
    label: "Usage"
    labelInfo: Math.round(Services.SystemStats.gpuUsage) + "%"
    value: Services.SystemStats.gpuUsage / 100
    progressHeight: Core.Style.progressHeightL
    showPercentage: false
  }

  Components.Sparkline {
    Layout.fillWidth: true
    visible: Services.SystemStats.hasGpuDetails
    values: Services.SystemStats.gpuHistory.map(v => v / 100)
    count: Services.SystemStats.historyLength
  }

  Components.ProgressRow {
    visible: Services.SystemStats.hasGpuDetails
    label: "VRAM"
    labelInfo: Core.Utils.formatBytes(Services.SystemStats.gpuMemUsed, 1) + " / " + Core.Utils.formatBytes(Services.SystemStats.gpuMemTotal, 1)
    value: Services.SystemStats.gpuMemUsed / Services.SystemStats.gpuMemTotal
    progressColor: Core.Theme.accentAlt
    progressHeight: Core.Style.progressHeightM
    showPercentage: false
  }

  Components.ProgressRow {
    visible: Services.SystemStats.hasGpuDetails && Services.SystemStats.gpuPowerLimit > 0
    label: "Power"
    labelInfo: Math.round(Services.SystemStats.gpuPower) + " / " + Math.round(Services.SystemStats.gpuPowerLimit) + " W"
    value: Services.SystemStats.gpuPower / Services.SystemStats.gpuPowerLimit
    progressColor: Core.Theme.accentAlt
    progressHeight: Core.Style.progressHeightM
    showPercentage: false
  }

  Components.Text {
    visible: Services.SystemStats.hasGpuDetails && Services.SystemStats.gpuThrottle !== ""
    text: Services.SystemStats.gpuThrottle
    size: Core.Style.fontS
    color: Core.Theme.warning
  }

  Components.Collapsible {
    title: "VRAM by Process"
    Layout.fillWidth: true
    visible: Services.SystemStats.hasGpuDetails

    Repeater {
      model: Services.SystemStats.gpuProcesses.length

      Components.ProgressRow {
        required property int index

        readonly property var client: Services.SystemStats.gpuProcesses[index]

        label: client?.name ?? ""
        labelInfo: Core.Utils.formatBytes(client?.memory ?? 0, 0)
        value: (client?.memory ?? 0) / Services.SystemStats.gpuMemTotal
        progressColor: Core.Theme.accentAlt
        progressHeight: Core.Style.progressHeightS
        showPercentage: false
      }
    }
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
    visible: Services.SystemStats.hasCpuTemp
    icon: "chip"
    iconColor: Core.Theme.statusColor(Services.SystemStats.cpuTempStatus, Core.Theme.text)
    label: "CPU"
    value: Services.SystemStats.cpuTemp / 100
    valueText: Core.Utils.formatTemp(Services.SystemStats.cpuTemp)
    progressColor: Core.Theme.statusColor(Services.SystemStats.cpuTempStatus, Core.Theme.success)
    progressHeight: Core.Style.progressHeightM
  }

  // GPU Temperature
  Components.ProgressRow {
    visible: Services.SystemStats.hasGpuTemp
    icon: "gpu"
    iconColor: Core.Theme.statusColor(Services.SystemStats.gpuTempStatus, Core.Theme.text)
    label: "GPU"
    value: Services.SystemStats.gpuTemp / 100
    valueText: Core.Utils.formatTemp(Services.SystemStats.gpuTemp)
    progressColor: Core.Theme.statusColor(Services.SystemStats.gpuTempStatus, Core.Theme.success)
    progressHeight: Core.Style.progressHeightM
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

  // Both directions share one scale, with the peak labelled: without it the
  // trace of a quiet minute looks exactly like a busy one.
  Item {
    Layout.fillWidth: true
    implicitHeight: Core.Style.sparklineHeight

    Components.Sparkline {
      anchors.fill: parent
      values: Services.SystemStats.netDownHistory.map(v => v / Services.SystemStats.netHistoryPeak)
      count: Services.SystemStats.historyLength
      color: Core.Theme.success
    }

    Components.Sparkline {
      anchors.fill: parent
      values: Services.SystemStats.netUpHistory.map(v => v / Services.SystemStats.netHistoryPeak)
      count: Services.SystemStats.historyLength
      color: Core.Theme.accent
    }

    Components.Text {
      anchors.right: parent.right
      anchors.top: parent.top
      text: "peak " + Core.Utils.formatSpeed(Services.SystemStats.netHistoryPeak)
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
    label: Services.SystemStats.diskMount
    labelInfo: Core.Utils.formatBytes(Services.SystemStats.diskUsed, 1) + " / " + Core.Utils.formatBytes(Services.SystemStats.diskTotal, 1)
    value: Services.SystemStats.diskPercent / 100
    progressColor: Core.Theme.statusColor(Services.SystemStats.diskStatus)
    progressHeight: Core.Style.progressHeightL
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
      text: "Updates every " + (Services.SystemStats.pollingInterval / 1000) + "s · graphs show " + Math.round(Services.SystemStats.historyLength * Services.SystemStats.pollingInterval / 60000) + " min"
      size: Core.Style.fontXS
      color: Core.Theme.textMuted
    }

    Components.Spacer {}

    // Health indicator
    RowLayout {
      spacing: Core.Style.spaceXS

      Components.StatusDot {
        size: Core.Style.px(8)
        color: Core.Theme.statusColor(Services.SystemStats.healthStatus, Core.Theme.success)
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

  readonly property var _noApp: ({
      name: "",
      value: 0,
      count: 1,
      pids: []
    })

  function _appDetail(value, count) {
    return count > 1 ? `${value} · ${count} processes` : value;
  }

  // Ending an app takes a second click, as the power actions do.
  property string pendingKill: ""

  onClosed: root.pendingKill = ""

  function endApp(app) {
    if (root.pendingKill !== app.name) {
      root.pendingKill = app.name;
      killTimeout.restart();
      return;
    }

    root.pendingKill = "";
    Services.SystemStats.endApp(app.pids);
  }

  Timer {
    id: killTimeout
    interval: 5000
    repeat: false
    onTriggered: root.pendingKill = ""
  }

  component AppRow: RowLayout {
    id: appRow

    required property var app
    required property string detail
    required property real fraction

    readonly property bool armed: root.pendingKill !== "" && root.pendingKill === appRow.app.name

    Layout.fillWidth: true
    spacing: Core.Style.spaceXS

    Components.ProgressRow {
      Layout.fillWidth: true
      label: appRow.armed ? `End ${appRow.app.name}?` : appRow.app.name
      labelInfo: appRow.armed ? "Click again to confirm" : appRow.detail
      value: appRow.fraction
      progressColor: appRow.armed ? Core.Theme.error : Core.Theme.accentAlt
      progressHeight: Core.Style.progressHeightS
      showPercentage: false
    }

    Components.Button {
      icon: "close"
      iconSize: Core.Style.fontS
      padding: Core.Style.spaceXXS
      iconColor: appRow.armed ? Core.Theme.error : Core.Theme.textDim
      // Kept in the layout, so hovering a row does not shift the bars.
      opacity: appRow.app.pids.length > 0 && (hover.hovered || appRow.armed) ? 1 : 0
      enabled: opacity > 0
      onClicked: root.endApp(appRow.app)
    }

    HoverHandler {
      id: hover
    }
  }

  function _healthText(status) {
    if (status === "critical")
      return "Critical";
    if (status === "warning")
      return "Warning";
    return "Healthy";
  }
}
