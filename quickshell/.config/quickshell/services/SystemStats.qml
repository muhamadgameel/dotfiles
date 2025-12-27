pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../core" as Core

/**
* SystemStats - Service for monitoring system hardware metrics
*
* Provides real-time monitoring of:
* - CPU temperature (Intel coretemp, AMD k10temp/zenpower)
* - GPU temperature (NVIDIA via nvidia-smi, AMD via hwmon)
* - CPU usage (overall and per-core)
* - Memory usage (RAM + Swap)
* - Network speeds (download/upload)
* - Disk usage (root filesystem)
*
* Features:
* - Efficient FileView-based reading (no process spawning for most metrics)
* - Auto-detection of CPU/GPU sensors
* - Configurable thresholds for warning/critical states
* - Health status computation
*
* Usage:
*   import "../services" as Services
*   Text { text: Services.SystemStats.cpuTemp + "°C" }
*   Text { text: Services.SystemStats.cpuTempStatus }  // "normal", "warning", "critical"
*/
Singleton {
  id: root

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════

  readonly property int pollingInterval: 2000

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
  property var cpuCores: []  // Per-core usage percentages

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

  // Sensor detection
  property string _cpuSensorType: ""   // "coretemp", "k10temp", "zenpower"
  property string _cpuHwmonPath: ""
  property string _gpuType: ""         // "nvidia", "amd"
  property string _gpuHwmonPath: ""

  // CPU stats delta tracking
  property var _prevCpuStats: null
  property var _prevCpuCoreStats: []

  // Network delta tracking
  property real _prevRxBytes: 0
  property real _prevTxBytes: 0
  property real _prevNetTime: 0

  // Intel multi-core temp collection
  property var _intelTemps: []
  property int _intelTempIndex: 0

  readonly property var _supportedCpuSensors: ["coretemp", "k10temp", "zenpower"]

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

  /**
  * Format bytes as human-readable size
  */
  function formatBytes(bytes, decimals) {
    if (!bytes || bytes === 0)
      return "0 B";
    const k = 1024;
    const dm = decimals !== undefined ? decimals : 1;
    const sizes = ["B", "KB", "MB", "GB", "TB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + " " + sizes[i];
  }

  /**
  * Format bytes per second as human-readable speed
  */
  function formatSpeed(bytesPerSecond) {
    if (!bytesPerSecond || bytesPerSecond === 0)
      return "0 B/s";
    const k = 1024;
    const sizes = ["B/s", "KB/s", "MB/s", "GB/s"];
    const i = Math.floor(Math.log(bytesPerSecond) / Math.log(k));
    return parseFloat((bytesPerSecond / Math.pow(k, i)).toFixed(1)) + " " + sizes[i];
  }

  /**
  * Format temperature with degree symbol
  */
  function formatTemp(temp) {
    return Math.round(temp) + "°C";
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  Component.onCompleted: {
    Core.Logger.i("SystemStats", "Service initializing...");
    _detectCpuSensor();
    _detectGpu();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // POLLING TIMERS
  // ═══════════════════════════════════════════════════════════════════════════

  // CPU Temperature polling
  Timer {
    interval: root.pollingInterval
    repeat: true
    running: root._cpuHwmonPath !== ""
    triggeredOnStart: true
    onTriggered: root._readCpuTemp()
  }

  // GPU Temperature polling
  Timer {
    interval: root.pollingInterval
    repeat: true
    running: root._gpuType !== ""
    triggeredOnStart: true
    onTriggered: {
      if (root._gpuType === "nvidia") {
        _nvidiaProcess.running = true;
      } else {
        _gpuTempFile.reload();
      }
    }
  }

  // System metrics polling (CPU, Memory, Network)
  Timer {
    interval: root.pollingInterval
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: {
      _cpuStatFile.reload();
      _memInfoFile.reload();
      _netDevFile.reload();
    }
  }

  // Disk polling (less frequent - every 1 minute)
  Timer {
    interval: 600000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: _diskProcess.running = true
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CPU SENSOR DETECTION
  // ═══════════════════════════════════════════════════════════════════════════

  function _detectCpuSensor() {
    _cpuSensorDetector.currentIndex = 0;
    _cpuSensorDetector.checkNext();
  }

  FileView {
    id: _cpuSensorDetector
    property int currentIndex: 0
    printErrors: false

    function checkNext() {
      if (currentIndex >= 16) {
        Core.Logger.w("SystemStats", "No supported CPU sensor found");
        return;
      }
      path = `/sys/class/hwmon/hwmon${currentIndex}/name`;
      reload();
    }

    onLoaded: {
      const name = text().trim();
      if (root._supportedCpuSensors.includes(name)) {
        root._cpuSensorType = name;
        root._cpuHwmonPath = `/sys/class/hwmon/hwmon${currentIndex}`;
        Core.Logger.i("SystemStats", `CPU sensor: ${name} at hwmon${currentIndex}`);
      } else {
        currentIndex++;
        Qt.callLater(checkNext);
      }
    }

    onLoadFailed: {
      currentIndex++;
      Qt.callLater(checkNext);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GPU DETECTION
  // ═══════════════════════════════════════════════════════════════════════════

  function _detectGpu() {
    _gpuDetector.currentIndex = 0;
    _gpuDetector.checkNext();
  }

  FileView {
    id: _gpuDetector
    property int currentIndex: 0
    printErrors: false

    function checkNext() {
      if (currentIndex >= 16) {
        // No AMD GPU found, try NVIDIA
        _nvidiaProcess.running = true;
        return;
      }
      path = `/sys/class/hwmon/hwmon${currentIndex}/name`;
      reload();
    }

    onLoaded: {
      const name = text().trim();
      if (name === "amdgpu") {
        root._gpuType = "amd";
        root._gpuHwmonPath = `/sys/class/hwmon/hwmon${currentIndex}`;
        Core.Logger.i("SystemStats", `AMD GPU at hwmon${currentIndex}`);
      } else {
        currentIndex++;
        Qt.callLater(checkNext);
      }
    }

    onLoadFailed: {
      currentIndex++;
      Qt.callLater(checkNext);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMPERATURE READERS
  // ═══════════════════════════════════════════════════════════════════════════

  function _readCpuTemp() {
    if (_cpuSensorType === "coretemp") {
      // Intel: collect temps from multiple cores and average
      root._intelTemps = [];
      root._intelTempIndex = 1;
      _readNextIntelCore();
    } else {
      // AMD: read single Tctl value
      _cpuTempFile.path = `${_cpuHwmonPath}/temp1_input`;
      _cpuTempFile.reload();
    }
  }

  function _readNextIntelCore() {
    if (_intelTempIndex > 20) {
      // Done collecting, calculate average
      if (_intelTemps.length > 0) {
        const sum = _intelTemps.reduce((a, b) => a + b, 0);
        cpuTemp = Math.round(sum / _intelTemps.length);
      }
      return;
    }
    _cpuTempFile.path = `${_cpuHwmonPath}/temp${_intelTempIndex}_input`;
    _cpuTempFile.reload();
  }

  FileView {
    id: _cpuTempFile
    printErrors: false

    onLoaded: {
      const temp = parseInt(text().trim()) / 1000;
      if (root._cpuSensorType === "coretemp") {
        root._intelTemps.push(temp);
        root._intelTempIndex++;
        Qt.callLater(root._readNextIntelCore);
      } else {
        root.cpuTemp = Math.round(temp);
      }
    }

    onLoadFailed: {
      if (root._cpuSensorType === "coretemp") {
        root._intelTempIndex++;
        Qt.callLater(root._readNextIntelCore);
      }
    }
  }

  FileView {
    id: _gpuTempFile
    path: root._gpuHwmonPath ? `${root._gpuHwmonPath}/temp1_input` : ""
    printErrors: false

    onLoaded: {
      root.gpuTemp = Math.round(parseInt(text().trim()) / 1000);
    }
  }

  Process {
    id: _nvidiaProcess
    command: ["nvidia-smi", "--query-gpu=temperature.gpu", "--format=csv,noheader,nounits"]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        const temp = parseInt(text.trim());
        if (!isNaN(temp) && temp > 0) {
          root.gpuTemp = temp;
          if (root._gpuType === "") {
            root._gpuType = "nvidia";
            Core.Logger.i("SystemStats", "NVIDIA GPU detected");
          }
        }
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        if (!text.includes("NVIDIA") && root._gpuType === "") {
          Core.Logger.d("SystemStats", "No NVIDIA GPU detected");
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CPU USAGE READER
  // ═══════════════════════════════════════════════════════════════════════════

  FileView {
    id: _cpuStatFile
    path: "/proc/stat"

    onLoaded: {
      const lines = text().split('\n');
      const coreUsages = [];

      for (const line of lines) {
        if (!line.startsWith('cpu'))
          continue;

        const parts = line.split(/\s+/);
        const name = parts[0];

        const stats = {
          user: parseInt(parts[1]) || 0,
          nice: parseInt(parts[2]) || 0,
          system: parseInt(parts[3]) || 0,
          idle: parseInt(parts[4]) || 0,
          iowait: parseInt(parts[5]) || 0,
          irq: parseInt(parts[6]) || 0,
          softirq: parseInt(parts[7]) || 0,
          steal: parseInt(parts[8]) || 0
        };

        const idle = stats.idle + stats.iowait;
        const total = Object.values(stats).reduce((a, b) => a + b, 0);

        if (name === "cpu") {
          // Overall CPU
          if (root._prevCpuStats) {
            const prevIdle = root._prevCpuStats.idle + root._prevCpuStats.iowait;
            const prevTotal = Object.values(root._prevCpuStats).reduce((a, b) => a + b, 0);
            const diffTotal = total - prevTotal;
            const diffIdle = idle - prevIdle;
            if (diffTotal > 0) {
              root.cpuUsage = parseFloat(((diffTotal - diffIdle) / diffTotal * 100).toFixed(1));
            }
          }
          root._prevCpuStats = stats;
        } else {
          // Per-core CPU
          const coreIndex = parseInt(name.substring(3));
          const prevCore = root._prevCpuCoreStats[coreIndex];

          if (prevCore) {
            const prevIdle = prevCore.idle + prevCore.iowait;
            const prevTotal = Object.values(prevCore).reduce((a, b) => a + b, 0);
            const diffTotal = total - prevTotal;
            const diffIdle = idle - prevIdle;
            if (diffTotal > 0) {
              coreUsages[coreIndex] = parseFloat(((diffTotal - diffIdle) / diffTotal * 100).toFixed(1));
            }
          }
          root._prevCpuCoreStats[coreIndex] = stats;
        }
      }

      if (coreUsages.length > 0) {
        root.cpuCores = coreUsages.filter(u => u !== undefined);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MEMORY READER
  // ═══════════════════════════════════════════════════════════════════════════

  FileView {
    id: _memInfoFile
    path: "/proc/meminfo"

    onLoaded: {
      const lines = text().split('\n');
      const values = {};

      for (const line of lines) {
        const match = line.match(/^(\w+):\s+(\d+)/);
        if (match) {
          values[match[1]] = parseInt(match[2]) * 1024;  // Convert KB to bytes
        }
      }

      // RAM
      const memTotal = values["MemTotal"] || 0;
      const memAvailable = values["MemAvailable"] || values["MemFree"] || 0;
      const memUsed = memTotal - memAvailable;

      root.memTotal = memTotal;
      root.memUsed = memUsed;
      root.memPercent = memTotal > 0 ? Math.round((memUsed / memTotal) * 100) : 0;

      // Swap
      const swapTotal = values["SwapTotal"] || 0;
      const swapFree = values["SwapFree"] || 0;
      const swapUsed = swapTotal - swapFree;

      root.swapTotal = swapTotal;
      root.swapUsed = swapUsed;
      root.swapPercent = swapTotal > 0 ? Math.round((swapUsed / swapTotal) * 100) : 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NETWORK READER
  // ═══════════════════════════════════════════════════════════════════════════

  FileView {
    id: _netDevFile
    path: "/proc/net/dev"

    onLoaded: {
      const now = Date.now() / 1000;
      const lines = text().split('\n');
      let totalRx = 0, totalTx = 0;
      let activeIface = "";

      for (let i = 2; i < lines.length; i++) {
        const line = lines[i].trim();
        if (!line)
          continue;

        const colonIdx = line.indexOf(':');
        if (colonIdx === -1)
          continue;

        const iface = line.substring(0, colonIdx).trim();

        // Skip loopback and virtual interfaces
        if (iface === 'lo' || iface.startsWith('veth') || iface.startsWith('docker') || iface.startsWith('br-') || iface.startsWith('virbr'))
          continue;

        const stats = line.substring(colonIdx + 1).trim().split(/\s+/);
        const rx = parseInt(stats[0], 10) || 0;
        const tx = parseInt(stats[8], 10) || 0;

        totalRx += rx;
        totalTx += tx;

        if (!activeIface && (rx > 0 || tx > 0)) {
          activeIface = iface;
        }
      }

      if (root._prevNetTime > 0) {
        const dt = now - root._prevNetTime;
        if (dt > 0) {
          root.netDownSpeed = Math.max(0, Math.round((totalRx - root._prevRxBytes) / dt));
          root.netUpSpeed = Math.max(0, Math.round((totalTx - root._prevTxBytes) / dt));
        }
      }

      root._prevRxBytes = totalRx;
      root._prevTxBytes = totalTx;
      root._prevNetTime = now;
      root.netInterface = activeIface;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DISK READER
  // ═══════════════════════════════════════════════════════════════════════════

  Process {
    id: _diskProcess
    command: ["df", "-B1", "/"]

    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.split("\n");
        if (lines.length < 2)
          return;

        // Parse the second line (first is header)
        const parts = lines[1].split(/\s+/);
        if (parts.length < 6)
          return;

        const total = parseInt(parts[1]) || 0;
        const used = parseInt(parts[2]) || 0;

        root.diskTotal = total;
        root.diskUsed = used;
        root.diskPercent = total > 0 ? Math.round((used / total) * 100) : 0;
        root.diskMount = parts[5] || "/";
      }
    }
  }
}
