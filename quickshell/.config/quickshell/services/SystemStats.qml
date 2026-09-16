pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../config" as Config
import "../core" as Core
import "../services" as Services

/**
* SystemStats - Service for monitoring system hardware metrics
*
* Provides real-time monitoring of:
* - CPU temperature (Intel coretemp package, AMD k10temp/zenpower Tctl)
* - GPU temperature (AMD via hwmon, NVIDIA via one looping nvidia-smi)
* - NVIDIA usage, VRAM, power draw and throttling, from the same query
* - NVIDIA VRAM by process, while the System Monitor is open
* - CPU usage (overall and per-core)
* - Memory usage (RAM + Swap)
* - Network speeds (download/upload)
* - Disk usage (root filesystem) and read/write throughput
* - Battery health, cycles and draw (laptops reporting energy)
* - Top apps by CPU and memory, while the System Monitor is open
* - Recent history of CPU, memory, GPU and network, for the panel's sparklines
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

  // How often the NVIDIA temperature is sampled. One long-running nvidia-smi
  // prints at this interval (see _nvidiaProcess), so it costs no spawn per
  // sample - the interval only bounds how fresh the reading is.
  readonly property int nvidiaPollingInterval: 10000
  readonly property int diskPollingInterval: 60000

  // Warning/critical thresholds live in config/Config.qml, with the reasoning
  // for the temperature values.

  // How far a reading must fall back below a threshold before its status may
  // drop, in the reading's own units (degrees, or percentage points).
  //
  // Without it a sensor sitting near a threshold flipped the status on nearly
  // every poll. It was found with the CPU idling at 70-72 C against an old 70 C
  // warning: the bar icon flickered orange-white every few seconds, and each flip
  // back into "warning" restarted the widget's pulse animation, keeping the
  // window rendering at the display refresh rate almost continuously. The
  // thresholds have since moved, but any reading can sit near any threshold.
  readonly property real hysteresis: 5

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC METRICS
  // ═══════════════════════════════════════════════════════════════════════════

  // === CPU ===
  property real cpuTemp: 0
  property real cpuUsage: 0
  property var cpuCores: []      // Per-core usage, indexed by real core id
  // Stable count so views can bind without rebuilding delegates every poll.
  property int cpuCoreCount: 0

  // === GPU ===
  property real gpuTemp: 0

  // NVIDIA only; empty or 0 until the first reading.
  property string gpuName: ""
  property real gpuUsage: 0       // percent
  property real gpuMemUsed: 0     // bytes
  property real gpuMemTotal: 0    // bytes
  property real gpuPower: 0       // watts
  property real gpuPowerLimit: 0  // watts, the limit the driver enforces now
  // Why the driver is holding the GPU back, or "" when it is not.
  property string gpuThrottle: ""
  // [{ name, memory }] per app, largest first. Sampled while the System
  // Monitor is open.
  property var gpuProcesses: []

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
  property real diskReadSpeed: 0   // bytes/sec, all physical disks
  property real diskWriteSpeed: 0

  // === Battery ===
  // The bar widget reads UPower, which smooths the charge and the time left.
  // These are the facts UPower's display device does not carry: what the pack
  // holds today against when it was new, and how often it has been cycled.
  property real batteryCharge: 0   // percent
  property real batteryEnergy: 0   // Wh now
  property real batteryFull: 0     // Wh when charged today
  property real batteryDesign: 0   // Wh when new
  property real batteryPower: 0    // W, in or out
  property int batteryCycles: 0
  property string batteryStatus: ""

  readonly property bool hasBattery: batteryDesign > 0
  readonly property real batteryHealth: batteryDesign > 0 ? batteryFull / batteryDesign * 100 : 0
  readonly property bool batteryDischarging: batteryStatus === "Discharging"
  // Time left at the current draw. UPower's own estimate is better; this only
  // has to be right enough to read beside the draw it came from.
  readonly property real batteryTimeLeft: batteryDischarging && batteryPower > 0 ? batteryEnergy / batteryPower * 3600 : 0

  // === System ===
  property var loadAverage: [0, 0, 0]  // 1, 5 and 15 minute averages
  property real uptime: 0              // seconds

  // === History ===
  // The last historyLength readings, oldest first, for the panel's sparklines.
  // Recorded on the poll below, which runs whether or not anything is looking,
  // so an opened panel already has a trace behind it.
  readonly property int historyLength: 60  // 2 minutes at pollingInterval
  property var cpuHistory: []      // percent
  property var memHistory: []      // bytes used, so a zoomed axis can name them
  property var gpuHistory: []      // NVIDIA usage; stepped, see nvidiaPollingInterval
  property var netDownHistory: []  // bytes/sec
  property var netUpHistory: []
  property var diskReadHistory: []
  property var diskWriteHistory: []

  // Each pair shares one scale, so the two directions stay comparable.
  readonly property real netHistoryPeak: Math.max(1, ...netDownHistory, ...netUpHistory)
  readonly property real diskHistoryPeak: Math.max(1, ...diskReadHistory, ...diskWriteHistory)

  // === Apps ===
  // [{ name, value, count, pids }] largest first, while the System Monitor is
  // open. value is percent of all CPUs, or bytes of private memory. A helper
  // process counts toward the app that started it when both run the same
  // executable, and pids holds the app's own processes - the ones endApp()
  // signals. Kernel threads are one row with no pids.
  property var topCpuApps: []
  property var topMemoryApps: []

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPUTED PROPERTIES
  // ═══════════════════════════════════════════════════════════════════════════

  // Detection flags
  readonly property bool hasCpuTemp: cpuTemp > 0
  readonly property bool hasGpuTemp: gpuTemp > 0
  readonly property bool hasGpuDetails: gpuMemTotal > 0
  readonly property bool hasSwap: swapTotal > 0

  // Status levels: "normal", "warning", "critical"
  //
  // Updated from each new reading rather than bound to statusLevel(), because
  // hysteresis needs the previous status - and a binding cannot read its own
  // last value. Read-only by convention; only the handlers below write them.
  property string cpuTempStatus: "normal"
  property string gpuTempStatus: "normal"
  property string cpuUsageStatus: "normal"
  property string memStatus: "normal"
  property string diskStatus: "normal"

  onCpuTempChanged: cpuTempStatus = statusLevel(cpuTemp, Config.Config.cpuTempWarning, Config.Config.cpuTempCritical, cpuTempStatus)
  onGpuTempChanged: gpuTempStatus = statusLevel(gpuTemp, Config.Config.gpuTempWarning, Config.Config.gpuTempCritical, gpuTempStatus)
  onCpuUsageChanged: cpuUsageStatus = statusLevel(cpuUsage, Config.Config.cpuUsageWarning, Config.Config.cpuUsageCritical, cpuUsageStatus)
  onMemPercentChanged: memStatus = statusLevel(memPercent, Config.Config.memWarning, Config.Config.memCritical, memStatus)
  onDiskPercentChanged: diskStatus = statusLevel(diskPercent, Config.Config.diskWarning, Config.Config.diskCritical, diskStatus)

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
  property string _cpuTempPath: ""
  property string _gpuType: ""         // "amd", "nvidia"
  property string _gpuTempPath: ""
  // Only set for a battery reporting energy (Wh). One reporting charge (Ah)
  // instead has no energy_full_design, and the health figures below assume it.
  property string _batteryPath: ""
  readonly property bool _monitorOpen: Services.Panels.openPanel === "systemstats"

  // pid -> process name, for the GPU clients seen in the last sample.
  property var _gpuClients: ({})

  // Rows of the report _topAppsScript is printing, until its "end" line.
  property var _topApps: ({
      cpu: [],
      memory: []
    })

  // CPU stats delta tracking
  property var _prevCpuStats: null
  property var _prevCpuCoreStats: ({})

  // Network delta tracking: iface -> { rx, tx }
  property var _prevNetStats: ({})
  property real _prevNetTime: 0

  // Disk delta tracking: device -> { read, write }, in 512-byte sectors
  property var _prevDiskStats: ({})
  property real _prevDiskTime: 0

  readonly property var _whitespace: /\s+/
  readonly property var _meminfoLine: /^(\w+):\s+(\d+)/
  readonly property var _ppidLine: /^PPid:\s+(\d+)/m

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
  * Status level for a reading, with hysteresis.
  *
  * A reading climbs into a level by reaching its threshold, but only leaves it
  * once it has fallen `hysteresis` below that threshold - so a value wobbling
  * across the line holds steady instead of flickering between two levels.
  *
  * @param previous - this reading's status last time; omit for plain thresholds
  * @returns "normal", "warning", or "critical"
  */
  function statusLevel(value, warningThreshold, criticalThreshold, previous) {
    const wasCritical = previous === "critical";
    const wasWarning = wasCritical || previous === "warning";

    if (value >= criticalThreshold || (wasCritical && value >= criticalThreshold - root.hysteresis))
      return "critical";
    if (value >= warningThreshold || (wasWarning && value >= warningThreshold - root.hysteresis))
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
          const parts = line.trim().split(root._whitespace);
          if (parts.length < 3)
            continue;

          const kind = parts[0];
          const type = parts[1];
          const path = parts[2];

          if (kind === "cpu" && root._cpuTempPath === "") {
            root._cpuTempPath = path;
            Core.Logger.i("SystemStats", `CPU sensor: ${type} at ${path}`);
          } else if (kind === "gpu" && root._gpuTempPath === "") {
            root._gpuType = type;
            root._gpuTempPath = path;
            Core.Logger.i("SystemStats", `GPU sensor: ${type} at ${path}`);
          } else if (kind === "battery" && root._batteryPath === "") {
            root._batteryPath = path;
            Core.Logger.i("SystemStats", `Battery: ${path}`);
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
done
for b in /sys/class/power_supply/*/; do
  [ "$(cat "$b/type" 2>/dev/null)" = "Battery" ] || continue
  [ -e "${b}energy_full_design" ] || continue
  echo "battery sysfs $b"
  break
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
      _diskStatsFile.reload();
      _loadAvgFile.reload();

      // Only while someone is watching the draw; otherwise the slow poll has it.
      if (root._monitorOpen)
        root._reloadBattery();

      // Last tick's readings: this one's are still being read.
      root._recordHistory();
    }
  }

  function _recordHistory() {
    // Nothing has been read yet on the first tick, and a zero recorded there
    // would hold a zoomed axis down for the whole window.
    if (root.memTotal === 0)
      return;

    root.cpuHistory = root._appended(root.cpuHistory, root.cpuUsage);
    root.memHistory = root._appended(root.memHistory, root.memUsed);
    root.gpuHistory = root._appended(root.gpuHistory, root.gpuUsage);
    root.netDownHistory = root._appended(root.netDownHistory, root.netDownSpeed);
    root.netUpHistory = root._appended(root.netUpHistory, root.netUpSpeed);
    root.diskReadHistory = root._appended(root.diskReadHistory, root.diskReadSpeed);
    root.diskWriteHistory = root._appended(root.diskWriteHistory, root.diskWriteSpeed);
  }

  function _appended(history, value) {
    const next = history.concat(value);
    return next.length > root.historyLength ? next.slice(next.length - root.historyLength) : next;
  }

  // Disk usage barely moves; once a minute is plenty.
  Timer {
    interval: root.diskPollingInterval
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: {
      _diskProcess.running = true;
      _uptimeFile.reload();
      root._reloadBattery();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BATTERY READER
  // ═══════════════════════════════════════════════════════════════════════════

  function _reloadBattery() {
    if (root._batteryPath === "")
      return;

    _batteryChargeFile.reload();
    _batteryEnergyFile.reload();
    _batteryFullFile.reload();
    _batteryDesignFile.reload();
    _batteryPowerFile.reload();
    _batteryCyclesFile.reload();
    _batteryStatusFile.reload();
  }

  // Energy and power are microwatt-hours and microwatts.
  function _microUnits(text) {
    const value = parseInt(text.trim(), 10);
    return isNaN(value) ? 0 : value / 1000000;
  }

  FileView {
    id: _batteryChargeFile
    path: root._batteryPath === "" ? "" : root._batteryPath + "capacity"
    printErrors: false
    onLoaded: root.batteryCharge = parseInt(text().trim(), 10) || 0
  }

  FileView {
    id: _batteryEnergyFile
    path: root._batteryPath === "" ? "" : root._batteryPath + "energy_now"
    printErrors: false
    onLoaded: root.batteryEnergy = root._microUnits(text())
  }

  FileView {
    id: _batteryFullFile
    path: root._batteryPath === "" ? "" : root._batteryPath + "energy_full"
    printErrors: false
    onLoaded: root.batteryFull = root._microUnits(text())
  }

  FileView {
    id: _batteryDesignFile
    path: root._batteryPath === "" ? "" : root._batteryPath + "energy_full_design"
    printErrors: false
    onLoaded: root.batteryDesign = root._microUnits(text())
  }

  FileView {
    id: _batteryPowerFile
    path: root._batteryPath === "" ? "" : root._batteryPath + "power_now"
    printErrors: false
    onLoaded: root.batteryPower = root._microUnits(text())
  }

  FileView {
    id: _batteryCyclesFile
    path: root._batteryPath === "" ? "" : root._batteryPath + "cycle_count"
    printErrors: false
    onLoaded: root.batteryCycles = parseInt(text().trim(), 10) || 0
  }

  FileView {
    id: _batteryStatusFile
    path: root._batteryPath === "" ? "" : root._batteryPath + "status"
    printErrors: false
    onLoaded: root.batteryStatus = text().trim()
  }

  // Runnable tasks averaged over 1, 5 and 15 minutes, and how long the machine
  // has been up. Both are one short read.
  FileView {
    id: _loadAvgFile
    path: "/proc/loadavg"
    printErrors: false

    onLoaded: {
      const parts = text().trim().split(root._whitespace);
      if (parts.length >= 3)
        root.loadAverage = [parseFloat(parts[0]) || 0, parseFloat(parts[1]) || 0, parseFloat(parts[2]) || 0];
    }
  }

  FileView {
    id: _uptimeFile
    path: "/proc/uptime"
    printErrors: false

    onLoaded: root.uptime = parseFloat(text().trim().split(root._whitespace)[0]) || 0
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

  // One long-running nvidia-smi in loop mode (`-l`), printing a reading every
  // nvidiaPollingInterval, instead of a fresh process every tick.
  //
  // Nearly all of nvidia-smi's cost is start-up - loading NVML and opening the
  // driver - not the query. Measured over a minute at a 10 s cadence: six
  // respawns took ~100 ms of CPU, the single looping process too little to
  // register. That was essentially all of the shell's child-process CPU. Same
  // shape as Network's long-running `nmcli monitor`.
  //
  // Started once by sensor detection as a probe. On a machine without an
  // NVIDIA GPU it exits straight away and stays down.
  Process {
    id: _nvidiaProcess
    command: root._nvidiaQuery.concat([String(root.nvidiaPollingInterval / 1000)])
    running: false

    stdout: SplitParser {
      splitMarker: "\n"
      onRead: data => {
        if (!root._readNvidia(data))
          return;

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

    // Restart a loop that was working and died (driver reload, nvidia-smi
    // killed). The fixed delay means a persistent failure retries at the old
    // polling rate rather than spinning.
    onExited: {
      if (root._gpuType === "nvidia")
        _nvidiaRestart.restart();
    }
  }

  Timer {
    id: _nvidiaRestart
    interval: root.nvidiaPollingInterval
    repeat: false
    onTriggered: _nvidiaProcess.running = true
  }

  // A faster second loop while the System Monitor is open, so its GPU rows move
  // with the CPU and memory rows. It stops when the panel closes.
  Process {
    command: root._nvidiaQuery.concat([String(root.pollingInterval / 1000)])
    running: root._gpuType === "nvidia" && root._monitorOpen

    stdout: SplitParser {
      splitMarker: "\n"
      onRead: data => root._readNvidia(data)
    }
  }

  readonly property var _nvidiaQuery: ["nvidia-smi", "--query-gpu=temperature.gpu,utilization.gpu,memory.used,memory.total,power.draw,enforced.power.limit,clocks_event_reasons.active,name", "--format=csv,noheader,nounits", "-l"]

  // One line of _nvidiaQuery. A field the driver reports as "[N/A]" keeps its
  // last value. Returns false for anything that is not a reading.
  function _readNvidia(line) {
    const fields = line.trim().split(", ");
    const temp = parseInt(fields[0], 10);
    if (fields.length < 8 || isNaN(temp) || temp <= 0)
      return false;

    const number = (text, scale) => {
      const value = parseFloat(text);
      return isNaN(value) ? null : value * scale;
    };
    const mib = 1024 * 1024;

    root.gpuTemp = temp;
    root.gpuUsage = number(fields[1], 1) ?? root.gpuUsage;
    root.gpuMemUsed = number(fields[2], mib) ?? root.gpuMemUsed;
    root.gpuMemTotal = number(fields[3], mib) ?? root.gpuMemTotal;
    root.gpuPower = number(fields[4], 1) ?? root.gpuPower;
    root.gpuPowerLimit = number(fields[5], 1) ?? root.gpuPowerLimit;

    // clocks_event_reasons hardware bits: 0x40 thermal, 0x08/0x80 slowdown and
    // power brake. The software thermal and power-cap bits (0x20, 0x04) are set
    // whenever a laptop GPU leaves idle, so they say nothing.
    const reasons = parseInt(fields[6], 16);
    if (reasons & 0x40)
      root.gpuThrottle = "Thermal throttling";
    else if (reasons & 0x88)
      root.gpuThrottle = "Hardware slowdown";
    else
      root.gpuThrottle = "";

    root.gpuName = fields.slice(7).join(", ");
    return true;
  }

  // `pmon` also lists graphics-only clients such as hyprpaper and Hyprland,
  // which --query-compute-apps leaves out.
  Timer {
    interval: root.pollingInterval
    repeat: true
    triggeredOnStart: true
    running: root._gpuType === "nvidia" && root._monitorOpen
    onTriggered: _gpuProcessQuery.running = true
  }

  Process {
    id: _gpuProcessQuery
    command: ["nvidia-smi", "pmon", "-c", "1", "-s", "m"]

    stdout: StdioCollector {
      onStreamFinished: root._readGpuProcesses(text)
    }
  }

  FileView {
    id: _procFile
    blockAllReads: true
    printErrors: false
  }

  function _readProc(pid, file) {
    _procFile.path = `/proc/${pid}/${file}`;
    return _procFile.text();
  }

  // Rows are "gpu pid type fb ccpm command", fb in MiB. pmon's own command
  // column is truncated, so the name comes from /proc instead.
  function _readGpuProcesses(text) {
    const clients = {};
    const memory = {};

    for (const line of text.split("\n")) {
      const fields = line.trim().split(root._whitespace);
      const pid = parseInt(fields[1], 10);
      const mib = parseInt(fields[3], 10);
      if (line.startsWith("#") || isNaN(pid) || isNaN(mib))
        continue;

      clients[pid] = root._gpuClients[pid] ?? root._gpuClientName(pid);
      if (clients[pid] === "")
        continue;

      const name = DesktopEntries.heuristicLookup(clients[pid])?.name || clients[pid];
      memory[name] = (memory[name] ?? 0) + mib * 1024 * 1024;
    }

    root._gpuClients = clients;
    root.gpuProcesses = Object.keys(memory).map(name => ({
          name: name,
          memory: memory[name]
        })).sort((a, b) => b.memory - a.memory);
  }

  // Chromium and Electron draw from a "--type=gpu-process" helper two levels
  // below the process that owns the window, and only that one has the app's
  // name.
  function _gpuClientName(pid) {
    let owner = pid;
    for (let hops = 0; hops < 4 && root._readProc(owner, "cmdline").includes("--type="); hops++) {
      const parent = root._readProc(owner, "status").match(root._ppidLine);
      if (!parent)
        break;
      owner = parent[1];
    }
    return root._readProc(owner, "comm").trim();
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

        const parts = line.split(root._whitespace);
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
        const match = line.match(root._meminfoLine);
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

        const stats = line.substring(colonIdx + 1).trim().split(root._whitespace);
        const rx = parseInt(stats[0], 10) || 0;
        const tx = parseInt(stats[8], 10) || 0;

        current[iface] = {
          rx: rx,
          tx: tx
        };
      }

      const dt = now - root._prevNetTime;
      if (root._prevNetTime > 0 && dt > 0) {
        let deltaRx = 0;
        let deltaTx = 0;
        let busiestIface = "";
        let busiestDelta = 0;

        for (const iface in current) {
          const prev = root._prevNetStats[iface];
          if (!prev)
            continue;  // Appeared this tick - no delta to take yet

          // Sum only matched samples. A new interface's lifetime counters are
          // not traffic from this interval, and a reset must not cancel traffic
          // on another interface.
          const rx = Math.max(0, current[iface].rx - prev.rx);
          const tx = Math.max(0, current[iface].tx - prev.tx);
          deltaRx += rx;
          deltaTx += tx;

          // The active interface is the one moving bytes right now, not merely
          // the first one with a non-zero lifetime counter.
          const delta = rx + tx;
          if (delta > busiestDelta) {
            busiestDelta = delta;
            busiestIface = iface;
          }
        }

        root.netDownSpeed = Math.round(deltaRx / dt);
        root.netUpSpeed = Math.round(deltaTx / dt);

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

  // Whole disks only. A partition's traffic is already counted on its disk, and
  // zram is compressed RAM rather than a device with a queue.
  readonly property var _virtualDisk: /^(loop|ram|zram|dm-|md|sr|fd)/
  readonly property var _diskPartition: /^(?:nvme\d+n\d+|mmcblk\d+)p\d+$|^(?:sd|vd|hd|xvd)[a-z]+\d+$/

  FileView {
    id: _diskStatsFile
    path: "/proc/diskstats"
    printErrors: false

    onLoaded: {
      const now = Date.now() / 1000;
      const current = {};

      for (const line of text().split("\n")) {
        const parts = line.trim().split(root._whitespace);
        if (parts.length < 10)
          continue;

        const name = parts[2];
        if (root._virtualDisk.test(name) || root._diskPartition.test(name))
          continue;

        // Sectors are always 512 bytes here, whatever the drive's own size is.
        current[name] = {
          read: parseInt(parts[5], 10) || 0,
          write: parseInt(parts[9], 10) || 0
        };
      }

      const dt = now - root._prevDiskTime;
      if (root._prevDiskTime > 0 && dt > 0) {
        let read = 0;
        let written = 0;

        for (const name in current) {
          const prev = root._prevDiskStats[name];
          if (!prev)
            continue;  // Appeared this tick - no delta to take yet

          read += Math.max(0, current[name].read - prev.read);
          written += Math.max(0, current[name].write - prev.write);
        }

        root.diskReadSpeed = Math.round(read * 512 / dt);
        root.diskWriteSpeed = Math.round(written * 512 / dt);
      }

      root._prevDiskStats = current;
      root._prevDiskTime = now;
    }
  }

  Process {
    id: _diskProcess
    command: ["df", "-B1", "--output=size,used,target", "/"]

    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n");
        if (lines.length < 2)
          return;

        const parts = lines[1].trim().split(root._whitespace);
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
  // TOP APPS
  // ═══════════════════════════════════════════════════════════════════════════

  // Parsing every process takes ~10 ms, so it happens in awk rather than on
  // the UI thread, and only the top rows come back.
  Process {
    command: ["awk", "-v", "top=5", "-v", "interval=" + root.pollingInterval / 1000, root._topAppsScript]
    running: root._monitorOpen

    stdout: SplitParser {
      onRead: line => root._readTopApp(line)
    }
  }

  // "cpu|memory <tab> value <tab> count <tab> pids <tab> name", then "end".
  function _readTopApp(line) {
    const fields = line.split("\t");
    if (fields[0] === "end") {
      root.topCpuApps = root._topApps.cpu;
      root.topMemoryApps = root._topApps.memory;
      root._topApps = {
        cpu: [],
        memory: []
      };
    } else if (fields.length >= 5 && fields[0] in root._topApps) {
      // A process name may itself contain a tab, and an empty one matches an
      // arbitrary desktop entry.
      const comm = fields.slice(4).join("\t");
      root._topApps[fields[0]].push({
        name: (comm !== "" && DesktopEntries.heuristicLookup(comm)?.name) || comm,
        value: parseFloat(fields[1]),
        count: parseInt(fields[2], 10),
        pids: fields[3] === "" ? [] : fields[3].split(",")
      });
    }
  }

  /**
  * Ask an app to quit, by signalling the processes it started.
  *
  * SIGTERM rather than SIGKILL: a browser closes its windows and saves its
  * session, and the helpers it started exit with it.
  */
  function endApp(pids) {
    if (!pids || pids.length === 0)
      return;

    Core.Logger.i("SystemStats", `ending ${pids.join(", ")}`);
    _killProcess.command = ["kill", "-TERM"].concat(pids);
    _killProcess.running = true;
  }

  Process {
    id: _killProcess

    stderr: StdioCollector {
      onStreamFinished: {
        const msg = text.trim();
        if (msg)
          Core.Logger.w("SystemStats", `kill: ${msg}`);
      }
    }
  }

  // Each sample reads /proc/*/stat and /proc/*/statm in one grep. An app is
  // grouped under its topmost ancestor running the same executable, so
  // Chromium's helpers count as Chromium but a build in a terminal does not
  // count as the terminal. Memory is resident minus shared: summing RSS counts
  // shared pages once per process. CPU includes the time a process reaped from
  // children, less what those children were already charged, so a build of
  // short-lived compilers is not invisible.
  readonly property string _topAppsScript: `
    function sample(   line, f, n, colon, pid, open, cmd, missing, stale) {
      getline line < "/proc/stat"
      close("/proc/stat")
      split(line, f, " ")
      total = 0
      for (n = 2; n <= 9; n++)
        total += f[n]

      split("", comm); split("", ppid); split("", ticks); split("", memory)
      cmd = "grep -aH . /proc/[0-9]*/stat /proc/[0-9]*/statm 2>/dev/null"
      while ((cmd | getline line) > 0) {
        colon = index(line, ":")
        split(substr(line, 7, colon - 7), f, "/")
        pid = "p" f[1]
        if (f[2] == "statm") {
          split(substr(line, colon + 1), f, " ")
          memory[pid] = (f[2] - f[3]) * page
          continue
        }
        open = index(line, "(")
        n = split(line, f, /[)] /)
        comm[pid] = substr(line, open + 1, length(line) - length(f[n]) - open - 2)
        split(f[n], f, " ")
        ppid[pid] = "p" f[2]
        ticks[pid] = f[12] + f[13] + f[14] + f[15]
        if (pid == self || ppid[pid] == self)
          delete comm[pid]
        else if (pid == "p2" || ppid[pid] == "p2") {
          comm[pid] = "Kernel"
          exe[pid] = ""
        }
      }
      close(cmd)

      for (pid in exe)
        if (!(pid in comm))
          stale[pid] = 1
      for (pid in stale)
        delete exe[pid]

      for (pid in comm)
        if (!(pid in exe))
          missing = missing " /proc/" substr(pid, 2) "/exe"
      if (missing != "") {
        cmd = "stat -c %N" missing " 2>/dev/null"
        while ((cmd | getline line) > 0) {
          match(line, /[0-9]+/)
          pid = "p" substr(line, RSTART, RLENGTH)
          exe[pid] = match(line, /-> .*/) ? substr(line, RSTART + 4, RLENGTH - 5) : ""
          sub(/ [(]deleted[)]$/, "", exe[pid])
        }
        close(cmd)
      }
    }

    function report(   pid, app, cpu, mem, count) {
      split("", roots)
      for (pid in comm) {
        app = pid
        while ((ppid[app] in comm) && exe[app] != "" && exe[ppid[app]] == exe[app])
          app = ppid[app]
        if (app == pid && comm[app] != "Kernel")
          roots[comm[app]] = roots[comm[app]] "," substr(pid, 2)
        cpu[comm[app]] += ticks[pid] - ((pid in before) ? before[pid] : 0)
        mem[comm[app]] += memory[pid]
        count[comm[app]]++
      }
      for (pid in before)
        if (!(pid in comm)) {
          app = beforePpid[pid]
          while ((app in beforePpid) && !(app in comm))
            app = beforePpid[app]
          if (!(app in comm))
            continue
          while ((ppid[app] in comm) && exe[app] != "" && exe[ppid[app]] == exe[app])
            app = ppid[app]
          cpu[comm[app]] -= before[pid]
        }
      emit("cpu", cpu, count, 100 / elapsed, "%.2f")
      emit("memory", mem, count, 1, "%.0f")
      print "end"
      fflush()
    }

    function emit(kind, values, count, scale, format,   i, name, best, used) {
      for (i = 0; i < top; i++) {
        best = ""
        for (name in values)
          if (!(name in used) && values[name] > 0 && (best == "" || values[name] > values[best]))
            best = name
        if (best == "")
          return
        used[best] = 1
        print kind, sprintf(format, values[best] * scale), count[best], substr(roots[best], 2), best
      }
    }

    BEGIN {
      OFS = sprintf("%c", 9)
      self = "p" PROCINFO["pid"]
      "getconf PAGESIZE" | getline page
      sample()
      wait = 0.5
      while (1) {
        split("", before); split("", beforePpid)
        for (pid in ticks) {
          before[pid] = ticks[pid]
          beforePpid[pid] = ppid[pid]
        }
        elapsed = total
        system("sleep " wait)
        wait = interval
        sample()
        elapsed = total - elapsed
        if (elapsed > 0)
          report()
      }
    }`

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  Component.onCompleted: Core.Logger.i("SystemStats", "Service initializing...")
}
