pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../core" as Core

/**
* SystemStats - Service for monitoring system hardware metrics
*
* Provides real-time monitoring of:
* - CPU temperature (Intel coretemp package, AMD k10temp/zenpower Tctl)
* - GPU temperature (AMD via hwmon, NVIDIA via nvidia-smi)
* - CPU usage (overall and per-core)
* - Memory usage (RAM + Swap)
* - Network speeds (download/upload)
* - Disk usage (root filesystem)
*
* Sensor discovery is a single shell pass over /sys/class/hwmon at startup that
* caches the exact sysfs paths. Each poll is then one file read per metric.
*
* On Intel this resolves the "Package id 0" sensor specifically. Averaging
* temp1..temp20 (as this previously did) mixes the package reading with the
* per-core readings and silently ignores any core sensor numbered above 20 -
* on a 48-sensor part that averaged an arbitrary 6 of them and under-reported
* the package by several degrees.
*
* Usage:
*   import "../services" as Services
*   Text { text: Core.Utils.formatTemp(Services.SystemStats.cpuTemp) }
*   Text { text: Services.SystemStats.cpuTempStatus }  // normal/warning/critical
*/
Singleton {
  id: root

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════

  readonly property int pollingInterval: 2000

  // nvidia-smi costs a process spawn of ~100-300ms, so it runs far less often
  // than the sysfs reads rather than on every tick.
  readonly property int nvidiaPollingInterval: 10000
  readonly property int diskPollingInterval: 60000

  // Thresholds (used by statusLevel function and widgets)
  readonly property real tempWarning: 70
  readonly property real tempCritical: 85
  readonly property real usageWarning: 70
  readonly property real usageCritical: 90
  readonly property real memWarning: 80
  readonly property real memCritical: 90
  readonly property real diskWarning: 85
  readonly property real diskCritical: 95

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC METRICS
  // ═══════════════════════════════════════════════════════════════════════════

  // === CPU ===
  property real cpuTemp: 0
  property real cpuUsage: 0
  property var cpuCores: []      // Per-core usage, indexed by real core id
  property int cpuCoreCount: 0   // Stable count so views can bind without
                                 // rebuilding their delegates every poll

  // === GPU ===
  property real gpuTemp: 0

  // === Memory ===
  property real memUsed: 0      // bytes
  property real memTotal: 0     // bytes
  property real memPercent: 0
  property real swapUsed: 0     // bytes
  property real swapTotal: 0    // bytes
  property real swapPercent: 0

  // === Network ===
  property real netDownSpeed: 0  // bytes/sec
  property real netUpSpeed: 0    // bytes/sec
  property string netInterface: ""

  // === Disk ===
  property real diskUsed: 0     // bytes
  property real diskTotal: 0    // bytes
  property real diskPercent: 0
  property string diskMount: "/"

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPUTED PROPERTIES
  // ═══════════════════════════════════════════════════════════════════════════

  // Detection flags
  readonly property bool hasCpuTemp: cpuTemp > 0
  readonly property bool hasGpuTemp: gpuTemp > 0
  readonly property bool hasSwap: swapTotal > 0
  readonly property bool hasNetworkData: netDownSpeed > 0 || netUpSpeed > 0

  // Status levels: "normal", "warning", "critical"
  readonly property string cpuTempStatus: statusLevel(cpuTemp, tempWarning, tempCritical)
  readonly property string gpuTempStatus: statusLevel(gpuTemp, tempWarning, tempCritical)
  readonly property string cpuUsageStatus: statusLevel(cpuUsage, usageWarning, usageCritical)
  readonly property string memStatus: statusLevel(memPercent, memWarning, memCritical)
  readonly property string diskStatus: statusLevel(diskPercent, diskWarning, diskCritical)

  // Overall health status
  readonly property string healthStatus: {
    const statuses = [cpuTempStatus, gpuTempStatus, cpuUsageStatus, memStatus, diskStatus];
    if (statuses.includes("critical"))
      return "critical";
    if (statuses.includes("warning"))
      return "warning";
    return "healthy";
  }

  readonly property string healthIcon: {
    if (healthStatus === "critical")
      return "fire";
    if (healthStatus === "warning")
      return "thermometer-high";
    return "gauge";
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE STATE
  // ═══════════════════════════════════════════════════════════════════════════

  // Resolved sensor paths (empty until detection finishes)
  property string _cpuSensorType: ""   // "coretemp", "k10temp", "zenpower"
  property string _cpuTempPath: ""
  property string _gpuType: ""         // "amd", "nvidia"
  property string _gpuTempPath: ""

  // CPU stats delta tracking
  property var _prevCpuStats: null
  property var _prevCpuCoreStats: ({})

  // Network delta tracking: iface -> { rx, tx }
  property var _prevNetStats: ({})
  property real _prevNetTime: 0

  // Interfaces excluded from the totals.
  //
  // Bridges and container/VM taps carry a copy of traffic already counted on
  // the physical interface, and a VPN tunnel carries a re-encapsulated copy of
  // the same bytes - including either double-counts throughput.
  readonly property var _ignoredIfacePrefixes: ["lo", "veth", "docker", "br-", "virbr", "vnet", "tun", "tap", "wg", "tailscale", "podman", "cni", "flannel", "kube", "ifb", "dummy", "bond", "sit", "gre", "waydroid"]

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC FUNCTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /**
  * Determine status level based on value and thresholds
  * @returns "normal", "warning", or "critical"
  */
  function statusLevel(value, warningThreshold, criticalThreshold) {
    if (value >= criticalThreshold)
      return "critical";
    if (value >= warningThreshold)
      return "warning";
    return "normal";
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SENSOR DETECTION
  // ═══════════════════════════════════════════════════════════════════════════

  // One shell pass resolves both the CPU and the GPU sensor path, replacing two
  // separate 16-iteration async walks over the same hwmon directories.
  Process {
    id: _sensorDetect
    running: true
    command: ["sh", "-c", root._detectScript]

    stdout: StdioCollector {
      onStreamFinished: {
        for (const line of text.split("\n")) {
          const parts = line.trim().split(/\s+/);
          if (parts.length < 3)
            continue;

          const kind = parts[0];
          const type = parts[1];
          const path = parts[2];

          if (kind === "cpu" && root._cpuTempPath === "") {
            root._cpuSensorType = type;
            root._cpuTempPath = path;
            Core.Logger.i("SystemStats", `CPU sensor: ${type} at ${path}`);
          } else if (kind === "gpu" && root._gpuTempPath === "") {
            root._gpuType = type;
            root._gpuTempPath = path;
            Core.Logger.i("SystemStats", `GPU sensor: ${type} at ${path}`);
          }
        }

        if (root._cpuTempPath === "")
          Core.Logger.w("SystemStats", "No supported CPU temperature sensor found");

        // No hwmon GPU: probe NVIDIA once. If it answers, its slow timer starts.
        if (root._gpuType === "")
          _nvidiaProcess.running = true;
      }
    }
  }

  // Kept as a plain string so the shell body is not fighting QML template
  // interpolation for its "$" and "${...}" syntax.
  readonly property string _detectScript: 'for h in /sys/class/hwmon/hwmon*/; do
  [ -r "$h/name" ] || continue
  n=$(cat "$h/name" 2>/dev/null) || continue
  case "$n" in
    coretemp|k10temp|zenpower|zenpower3)
      f=""
      for lbl in "$h"temp*_label; do
        [ -e "$lbl" ] || continue
        case "$(cat "$lbl" 2>/dev/null)" in
          "Package id 0"|Tctl|Tdie) f="${lbl%_label}_input"; break ;;
        esac
      done
      [ -n "$f" ] && [ -e "$f" ] || f="${h}temp1_input"
      [ -e "$f" ] && echo "cpu $n $f"
      ;;
    amdgpu)
      [ -e "${h}temp1_input" ] && echo "gpu amd ${h}temp1_input"
      ;;
  esac
done'

  // ═══════════════════════════════════════════════════════════════════════════
  // POLLING TIMERS
  // ═══════════════════════════════════════════════════════════════════════════

  // Sysfs metrics: CPU temp, AMD GPU temp, CPU usage, memory, network.
  // Every one of these is a single file read.
  Timer {
    interval: root.pollingInterval
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: {
      if (root._cpuTempPath !== "")
        _cpuTempFile.reload();
      if (root._gpuType === "amd")
        _gpuTempFile.reload();

      _cpuStatFile.reload();
      _memInfoFile.reload();
      _netDevFile.reload();
    }
  }

  // NVIDIA needs a process spawn, so it polls on its own slower cadence.
  Timer {
    interval: root.nvidiaPollingInterval
    repeat: true
    running: root._gpuType === "nvidia"
    onTriggered: _nvidiaProcess.running = true
  }

  // Disk usage barely moves; once a minute is plenty.
  Timer {
    interval: root.diskPollingInterval
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: _diskProcess.running = true
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMPERATURE READERS
  // ═══════════════════════════════════════════════════════════════════════════

  FileView {
    id: _cpuTempFile
    path: root._cpuTempPath
    printErrors: false

    onLoaded: {
      const milli = parseInt(text().trim(), 10);
      if (!isNaN(milli))
        root.cpuTemp = Math.round(milli / 1000);
    }
  }

  FileView {
    id: _gpuTempFile
    path: root._gpuType === "amd" ? root._gpuTempPath : ""
    printErrors: false

    onLoaded: {
      const milli = parseInt(text().trim(), 10);
      if (!isNaN(milli))
        root.gpuTemp = Math.round(milli / 1000);
    }
  }

  Process {
    id: _nvidiaProcess
    command: ["nvidia-smi", "--query-gpu=temperature.gpu", "--format=csv,noheader,nounits"]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        const temp = parseInt(text.trim(), 10);
        if (isNaN(temp) || temp <= 0)
          return;

        root.gpuTemp = temp;
        if (root._gpuType === "") {
          root._gpuType = "nvidia";
          Core.Logger.i("SystemStats", "NVIDIA GPU detected");
        }
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        if (root._gpuType === "")
          Core.Logger.d("SystemStats", "No NVIDIA GPU detected");
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CPU USAGE READER
  // ═══════════════════════════════════════════════════════════════════════════

  // Percentage of non-idle jiffies between two /proc/stat samples.
  // Returns null when there is no usable previous sample.
  function _deltaUsage(prev, current) {
    if (!prev)
      return null;

    const total = current.user + current.nice + current.system + current.idle + current.iowait + current.irq + current.softirq + current.steal;
    const prevTotal = prev.user + prev.nice + prev.system + prev.idle + prev.iowait + prev.irq + prev.softirq + prev.steal;

    const diffTotal = total - prevTotal;
    if (diffTotal <= 0)
      return null;

    const diffIdle = (current.idle + current.iowait) - (prev.idle + prev.iowait);
    return parseFloat(((diffTotal - diffIdle) / diffTotal * 100).toFixed(1));
  }

  FileView {
    id: _cpuStatFile
    path: "/proc/stat"
    printErrors: false

    onLoaded: {
      const cores = root.cpuCores.slice();
      let maxCoreIndex = -1;

      for (const line of text().split("\n")) {
        if (!line.startsWith("cpu"))
          continue;

        const parts = line.split(/\s+/);
        const name = parts[0];

        const stats = {
          user: parseInt(parts[1], 10) || 0,
          nice: parseInt(parts[2], 10) || 0,
          system: parseInt(parts[3], 10) || 0,
          idle: parseInt(parts[4], 10) || 0,
          iowait: parseInt(parts[5], 10) || 0,
          irq: parseInt(parts[6], 10) || 0,
          softirq: parseInt(parts[7], 10) || 0,
          steal: parseInt(parts[8], 10) || 0
        };

        if (name === "cpu") {
          const overall = root._deltaUsage(root._prevCpuStats, stats);
          if (overall !== null)
            root.cpuUsage = overall;
          root._prevCpuStats = stats;
          continue;
        }

        // Per-core. Indexed by the real core id so panel labels stay correct -
        // compacting the array with filter() used to shift "Core N" labels off
        // the cores they described.
        const coreIndex = parseInt(name.substring(3), 10);
        if (isNaN(coreIndex))
          continue;

        if (coreIndex > maxCoreIndex)
          maxCoreIndex = coreIndex;

        const usage = root._deltaUsage(root._prevCpuCoreStats[coreIndex], stats);
        cores[coreIndex] = usage !== null ? usage : (cores[coreIndex] ?? 0);
        root._prevCpuCoreStats[coreIndex] = stats;
      }

      if (maxCoreIndex < 0)
        return;

      const count = maxCoreIndex + 1;
      cores.length = count;
      for (let i = 0; i < count; i++) {
        if (cores[i] === undefined)
          cores[i] = 0;
      }

      root.cpuCores = cores;

      // Assigned separately, and only on change, so views bound to the count do
      // not rebuild their delegates on every poll.
      if (root.cpuCoreCount !== count)
        root.cpuCoreCount = count;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MEMORY READER
  // ═══════════════════════════════════════════════════════════════════════════

  FileView {
    id: _memInfoFile
    path: "/proc/meminfo"
    printErrors: false

    onLoaded: {
      const values = {};

      for (const line of text().split("\n")) {
        const match = line.match(/^(\w+):\s+(\d+)/);
        if (match)
          values[match[1]] = parseInt(match[2], 10) * 1024;  // kB -> bytes
      }

      // RAM
      const memTotal = values["MemTotal"] || 0;
      const memAvailable = values["MemAvailable"] ?? values["MemFree"] ?? 0;
      const memUsed = Math.max(0, memTotal - memAvailable);

      root.memTotal = memTotal;
      root.memUsed = memUsed;
      root.memPercent = memTotal > 0 ? Math.round((memUsed / memTotal) * 100) : 0;

      // Swap
      const swapTotal = values["SwapTotal"] || 0;
      const swapFree = values["SwapFree"] || 0;
      const swapUsed = Math.max(0, swapTotal - swapFree);

      root.swapTotal = swapTotal;
      root.swapUsed = swapUsed;
      root.swapPercent = swapTotal > 0 ? Math.round((swapUsed / swapTotal) * 100) : 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NETWORK READER
  // ═══════════════════════════════════════════════════════════════════════════

  function _isIgnoredInterface(iface) {
    for (const prefix of root._ignoredIfacePrefixes) {
      if (iface === prefix || iface.startsWith(prefix))
        return true;
    }
    return false;
  }

  FileView {
    id: _netDevFile
    path: "/proc/net/dev"
    printErrors: false

    onLoaded: {
      const now = Date.now() / 1000;
      const lines = text().split("\n");
      const current = {};

      let totalRx = 0;
      let totalTx = 0;

      for (let i = 2; i < lines.length; i++) {
        const line = lines[i].trim();
        if (!line)
          continue;

        const colonIdx = line.indexOf(":");
        if (colonIdx === -1)
          continue;

        const iface = line.substring(0, colonIdx).trim();
        if (root._isIgnoredInterface(iface))
          continue;

        const stats = line.substring(colonIdx + 1).trim().split(/\s+/);
        const rx = parseInt(stats[0], 10) || 0;
        const tx = parseInt(stats[8], 10) || 0;

        current[iface] = {
          rx: rx,
          tx: tx
        };
        totalRx += rx;
        totalTx += tx;
      }

      const dt = now - root._prevNetTime;
      if (root._prevNetTime > 0 && dt > 0) {
        let prevRx = 0;
        let prevTx = 0;
        let busiestIface = "";
        let busiestDelta = 0;

        for (const iface in current) {
          const prev = root._prevNetStats[iface];
          if (!prev)
            continue;  // Appeared this tick - no delta to take yet

          prevRx += prev.rx;
          prevTx += prev.tx;

          // The active interface is the one moving bytes right now, not merely
          // the first one with a non-zero lifetime counter.
          const delta = (current[iface].rx - prev.rx) + (current[iface].tx - prev.tx);
          if (delta > busiestDelta) {
            busiestDelta = delta;
            busiestIface = iface;
          }
        }

        // Counters vanish with their interface; clamp instead of reporting the
        // resulting negative as a spike.
        root.netDownSpeed = Math.max(0, Math.round((totalRx - prevRx) / dt));
        root.netUpSpeed = Math.max(0, Math.round((totalTx - prevTx) / dt));

        if (busiestIface !== "")
          root.netInterface = busiestIface;
        else if (!(root.netInterface in current))
          root.netInterface = Object.keys(current)[0] ?? "";
      }

      root._prevNetStats = current;
      root._prevNetTime = now;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DISK READER
  // ═══════════════════════════════════════════════════════════════════════════

  Process {
    id: _diskProcess
    command: ["df", "-B1", "--output=size,used,target", "/"]

    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n");
        if (lines.length < 2)
          return;

        const parts = lines[1].trim().split(/\s+/);
        if (parts.length < 3)
          return;

        const total = parseInt(parts[0], 10) || 0;
        const used = parseInt(parts[1], 10) || 0;

        root.diskTotal = total;
        root.diskUsed = used;
        root.diskPercent = total > 0 ? Math.round((used / total) * 100) : 0;
        root.diskMount = parts[2] || "/";
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        const msg = text.trim();
        if (msg)
          Core.Logger.w("SystemStats", `df: ${msg}`);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  Component.onCompleted: Core.Logger.i("SystemStats", "Service initializing...")
}
