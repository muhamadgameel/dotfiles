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
* - CPU usage, clocks and temperature, with per-core breakdown and top apps
* - Memory usage (RAM + Swap) and top apps
* - GPU usage, VRAM, power, temperature and VRAM by process (NVIDIA)
* - Battery health and cycles
* - Network throughput
* - Disk usage and I/O
*/
Components.SlidingPanel {
  id: root

  panelId: "systemstats"

  // Header configuration
  headerIcon: Services.SystemStats.healthIcon
  headerTitle: "System Monitor"
  headerSubtitle: "Up " + Core.Utils.formatUptime(Services.SystemStats.uptime)

  // ═══════════════════════════════════════════════════════════════════
  // CPU SECTION
  // ═══════════════════════════════════════════════════════════════════

  Components.SectionHeader {
    icon: "cpu"
    title: "CPU"

    Components.Text {
      visible: Services.SystemStats.hasCpuTemp
      text: Core.Utils.formatTemp(Services.SystemStats.cpuTemp)
      size: Core.Style.fontXS
      color: Core.Theme.statusColor(Services.SystemStats.cpuTempStatus, Core.Theme.textDim)
    }

    // Runnable tasks, averaged over 1, 5 and 15 minutes. Past one per thread
    // the machine has more work than it can run at once.
    Components.Text {
      text: "load " + Services.SystemStats.loadAverage.map(v => v.toFixed(2)).join(" · ")
      size: Core.Style.fontXS
      color: Services.SystemStats.loadAverage[0] > Services.SystemStats.cpuCoreCount ? Core.Theme.warning : Core.Theme.textDim
    }
  }

  Components.ProgressRow {
    value: Services.SystemStats.cpuUsage / 100
    progressColor: Core.Theme.statusColor(Services.SystemStats.cpuUsageStatus)
    progressHeight: Core.Style.progressHeightL
  }

  Components.Sparkline {
    id: cpuGraph

    Layout.fillWidth: true
    values: Services.SystemStats.cpuHistory
    count: Services.SystemStats.historyLength
    color: Core.Theme.statusColor(Services.SystemStats.cpuUsageStatus)
    // A quiet window stays low instead of magnifying the idle wobble.
    minimumSpan: 10
    label: `peak ${Math.round(cpuGraph.peak)}%`
  }

  Components.Text {
    text: root._cpuDetail()
    size: Core.Style.fontXS
    color: Core.Theme.textMuted
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

        readonly property real freq: Services.SystemStats.cpuFreqs[index] ?? 0

        label: "Core " + index
        labelInfo: (freq > 0 ? Core.Utils.formatFrequency(freq) + " · " : "") + Math.round(usage) + "%"
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
    icon: "memory"
    title: "Memory"

    Components.Text {
      visible: Services.SystemStats.hasSwap
      text: "swap " + Core.Utils.formatBytes(Services.SystemStats.swapUsed, 1) + " / " + Core.Utils.formatBytes(Services.SystemStats.swapTotal, 1)
      size: Core.Style.fontXS
      color: Services.SystemStats.swapPercent > 50 ? Core.Theme.warning : Core.Theme.textDim
    }
  }

  Components.ProgressRow {
    label: "In use"
    labelInfo: Core.Utils.formatBytes(Services.SystemStats.memUsed, 1) + " / " + Core.Utils.formatBytes(Services.SystemStats.memTotal, 1)
    value: Services.SystemStats.memPercent / 100
    progressColor: Core.Theme.statusColor(Services.SystemStats.memStatus)
    progressHeight: Core.Style.progressHeightL
    showPercentage: false
  }

  // RAM never approaches zero, so this axis holds the window's own range.
  Components.Sparkline {
    id: memGraph

    Layout.fillWidth: true
    values: Services.SystemStats.memHistory
    count: Services.SystemStats.historyLength
    color: Core.Theme.statusColor(Services.SystemStats.memStatus)
    zoomToRange: true
    minimumSpan: Services.SystemStats.memTotal * 0.05
    // The floor is not zero here, so an area beneath the line would mean nothing.
    fillOpacity: 0
    label: `${Core.Utils.formatBytes(memGraph.axisMin, 1)} – ${Core.Utils.formatBytes(memGraph.axisMax, 1)}`
  }

  Components.ProgressRow {
    visible: Services.SystemStats.swapUsed > 0
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
    visible: Services.SystemStats.hasGpuDetails
    icon: "gpu"
    title: "GPU"

    Components.Text {
      text: Services.SystemStats.gpuName.replace(/^NVIDIA (GeForce )?/, "")
      size: Core.Style.fontXS
      color: Core.Theme.textDim
    }

    Components.Text {
      visible: Services.SystemStats.hasGpuTemp
      text: Core.Utils.formatTemp(Services.SystemStats.gpuTemp)
      size: Core.Style.fontXS
      color: Core.Theme.statusColor(Services.SystemStats.gpuTempStatus, Core.Theme.textDim)
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
    id: gpuGraph

    Layout.fillWidth: true
    visible: Services.SystemStats.hasGpuDetails
    values: Services.SystemStats.gpuHistory
    count: Services.SystemStats.historyLength
    minimumSpan: 10
    label: `peak ${Math.round(gpuGraph.peak)}%`
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
  // BATTERY SECTION
  // ═══════════════════════════════════════════════════════════════════

  Components.SectionHeader {
    visible: Services.SystemStats.hasBattery
    icon: "battery-full"
    title: "Battery"

    Components.Text {
      text: Services.SystemStats.batteryStatus
      size: Core.Style.fontXS
      color: Core.Theme.textDim
    }
  }

  Components.ProgressRow {
    visible: Services.SystemStats.hasBattery
    label: "Charge"
    labelInfo: Math.round(Services.SystemStats.batteryCharge) + "%"
    value: Services.SystemStats.batteryCharge / 100
    progressColor: Services.SystemStats.batteryCharge <= 15 && Services.SystemStats.batteryDischarging ? Core.Theme.error : Core.Theme.accent
    progressHeight: Core.Style.progressHeightL
    showPercentage: false
  }

  // What a full charge holds now, against what it held new.
  Components.ProgressRow {
    visible: Services.SystemStats.hasBattery
    label: "Health"
    labelInfo: `${Services.SystemStats.batteryFull.toFixed(1)} / ${Services.SystemStats.batteryDesign.toFixed(1)} Wh`
    value: Services.SystemStats.batteryHealth / 100
    progressColor: Services.SystemStats.batteryHealth < 70 ? Core.Theme.warning : Core.Theme.accentAlt
    progressHeight: Core.Style.progressHeightM
    showPercentage: false
  }

  Components.Text {
    visible: Services.SystemStats.hasBattery
    text: root._batteryDetail()
    size: Core.Style.fontXS
    color: Core.Theme.textMuted
  }

  // ═══════════════════════════════════════════════════════════════════
  // NETWORK SECTION
  // ═══════════════════════════════════════════════════════════════════

  Components.SectionHeader {
    icon: "network"
    title: "Network"

    Components.Text {
      text: Services.SystemStats.netInterface
      size: Core.Style.fontXS
      color: Core.Theme.textDim
    }

    Components.Text {
      text: Core.Icons.get("arrow-down") + " " + Core.Utils.formatSpeed(Services.SystemStats.netDownSpeed)
      size: Core.Style.fontXS
      color: Core.Theme.success
    }

    Components.Text {
      text: Core.Icons.get("arrow-up") + " " + Core.Utils.formatSpeed(Services.SystemStats.netUpSpeed)
      size: Core.Style.fontXS
      color: Core.Theme.accent
    }
  }

  // Both directions share one scale, so up and down stay comparable.
  Item {
    Layout.fillWidth: true
    implicitHeight: Core.Style.sparklineHeight

    Components.Sparkline {
      anchors.fill: parent
      values: Services.SystemStats.netDownHistory
      count: Services.SystemStats.historyLength
      scaleMax: Services.SystemStats.netHistoryPeak
      color: Core.Theme.success
    }

    Components.Sparkline {
      anchors.fill: parent
      values: Services.SystemStats.netUpHistory
      count: Services.SystemStats.historyLength
      scaleMax: Services.SystemStats.netHistoryPeak
      color: Core.Theme.accent
      label: "peak " + Core.Utils.formatSpeed(Services.SystemStats.netHistoryPeak)
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // DISK SECTION
  // ═══════════════════════════════════════════════════════════════════

  Components.SectionHeader {
    icon: "disk"
    title: "Storage"

    Components.Text {
      text: Core.Utils.formatBytes(Services.SystemStats.diskTotal - Services.SystemStats.diskUsed, 1) + " free"
      size: Core.Style.fontXS
      color: Services.SystemStats.diskStatus !== "normal" ? Core.Theme.warning : Core.Theme.textDim
    }

    Components.Text {
      text: Core.Icons.get("arrow-down") + " " + Core.Utils.formatSpeed(Services.SystemStats.diskReadSpeed)
      size: Core.Style.fontXS
      color: Core.Theme.success
    }

    Components.Text {
      text: Core.Icons.get("arrow-up") + " " + Core.Utils.formatSpeed(Services.SystemStats.diskWriteSpeed)
      size: Core.Style.fontXS
      color: Core.Theme.accent
    }
  }

  Components.ProgressRow {
    label: Services.SystemStats.diskMount
    labelInfo: Core.Utils.formatBytes(Services.SystemStats.diskUsed, 1) + " / " + Core.Utils.formatBytes(Services.SystemStats.diskTotal, 1)
    value: Services.SystemStats.diskPercent / 100
    progressColor: Core.Theme.statusColor(Services.SystemStats.diskStatus)
    progressHeight: Core.Style.progressHeightL
    showPercentage: false
  }

  Item {
    Layout.fillWidth: true
    implicitHeight: Core.Style.sparklineHeight

    Components.Sparkline {
      anchors.fill: parent
      values: Services.SystemStats.diskReadHistory
      count: Services.SystemStats.historyLength
      scaleMax: Services.SystemStats.diskHistoryPeak
      color: Core.Theme.success
    }

    Components.Sparkline {
      anchors.fill: parent
      values: Services.SystemStats.diskWriteHistory
      count: Services.SystemStats.historyLength
      scaleMax: Services.SystemStats.diskHistoryPeak
      color: Core.Theme.accent
      label: "peak " + Core.Utils.formatSpeed(Services.SystemStats.diskHistoryPeak)
    }
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

  function _cpuDetail() {
    const parts = [];

    if (Services.SystemStats.cpuFreqAvg > 0)
      parts.push(Core.Utils.formatFrequency(Services.SystemStats.cpuFreqAvg) + " average");
    if (Services.SystemStats.cpuGovernor !== "")
      parts.push(Services.SystemStats.cpuGovernor);
    if (Services.SystemStats.cpuEpp !== "")
      parts.push(Services.SystemStats.cpuEpp);

    return parts.join(" · ");
  }

  function _batteryDetail() {
    const parts = [`${Math.round(Services.SystemStats.batteryHealth)}% health`, `${Services.SystemStats.batteryCycles} cycles`];

    if (Services.SystemStats.batteryPower > 0)
      parts.push(`${Services.SystemStats.batteryPower.toFixed(1)} W`);

    if (Services.SystemStats.batteryTimeLeft > 0)
      parts.push(`${Core.Utils.formatDuration(Services.SystemStats.batteryTimeLeft, true)} left`);

    return parts.join(" · ");
  }

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
