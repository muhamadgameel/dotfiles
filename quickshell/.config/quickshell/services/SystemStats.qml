pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../config" as Config
import "../core" as Core
import "../services" as Services

/**
* SystemStats - CPU, GPU, memory, network, disk and battery figures for the bar
* and the System Monitor
*
* Sensor discovery is a single shell pass over /sys/class/hwmon at startup that
* caches the exact sysfs paths. Each poll is then one file read per metric.
*
* The CPU temperature is coretemp's "Package id 0" sensor: an average over the
* per-core sensors reads several degrees low.
*/
Singleton {
  id: root

  readonly property int pollingInterval: 2000

  // How often the looping nvidia-smi prints while the System Monitor is closed;
  // while it is open, pollingInterval.
  readonly property int nvidiaPollingInterval: 10000
  readonly property int diskPollingInterval: 60000

  // Warning/critical thresholds live in config/Config.qml, with the reasoning
  // for the temperature values.

  // How far a reading must fall back below a threshold before its status may
  // drop, in the reading's own units (degrees, or percentage points). Without it
  // a reading near a threshold flips the status every poll, and each flip into
  // "warning" restarts the bar widget's pulse, which keeps the window redrawing.
  readonly property real hysteresis: 5

  // === CPU ===
  property real cpuTemp: 0
  property real cpuUsage: 0
  property var cpuCores: []      // Per-core usage, indexed by real core id
  // Stable count so views can bind without rebuilding delegates every poll.
  property int cpuCoreCount: 0

  // Clock speeds in MHz, indexed as cpuCores is. Only read while the System
  // Monitor is open, which is the only thing that shows them.
  property var cpuFreqs: []
  property real cpuFreqAvg: 0
  property string cpuGovernor: ""
  property string cpuEpp: ""     // energy_performance_preference, if the driver has one

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

  // Resolved sensor paths (empty until detection finishes)
  property string _cpuTempPath: ""
  property bool _nvidia: false
  // Only set for a battery reporting energy (Wh). One reporting charge (Ah)
  // instead has no energy_full_design, and the health figures below assume it.
  property string _batteryPath: ""
  readonly property bool _monitorOpen: Services.Panels.openPanel === "systemstats"

  // pid -> process name, for the GPU clients seen in the last sample.
  property var _gpuClients: ({})

  // Rows of the report top-apps.awk is printing, until its "end" line.
  property var _topApps: ({
      cpu: [],
      memory: []
    })

  // CPU stats delta tracking
  property var _prevCpuStats: null
  property var _prevCpuCoreStats: ({})

  // The last sample of each counter file, for _rates().
  property var _lastSamples: ({})

  readonly property var _whitespace: /\s+/
  readonly property var _meminfoLine: /^(\w+):\s+(\d+)/
  readonly property var _batteryLine: /^POWER_SUPPLY_(\w+)=(.*)$/
  readonly property var _ppidLine: /^PPid:\s+(\d+)/m

  // Interfaces excluded from the totals.
  //
  // Bridges and container/VM taps carry a copy of traffic already counted on
  // the physical interface, and a VPN tunnel carries a re-encapsulated copy of
  // the same bytes - including either double-counts throughput.

  readonly property var _ignoredIfacePrefixes: ["lo", "veth", "docker", "br-", "virbr", "vnet", "tun", "tap", "wg", "tailscale", "podman", "cni", "flannel", "kube", "ifb", "dummy", "bond", "sit", "gre", "waydroid"]

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

  // One shell pass finds the CPU sensor and the battery.
  Core.Command {
    id: _sensorDetect
    running: true
    command: ["sh", Quickshell.shellPath("services/scripts/detect-sensors.sh")]

    onDone: (code, out) => {
      for (const line of out.split("\n")) {
        const parts = line.trim().split(root._whitespace);
        if (parts.length < 3)
          continue;

        const kind = parts[0];
        const path = parts[2];

        if (kind === "cpu" && root._cpuTempPath === "") {
          root._cpuTempPath = path;
        } else if (kind === "battery" && root._batteryPath === "") {
          root._batteryPath = path;
        }
      }

      if (root._cpuTempPath === "")
        Core.Logger.w("SystemStats", "No supported CPU temperature sensor found");
    }
  }

  // Sysfs metrics: CPU temp, CPU usage, memory, network.
  // Every one of these is a single file read.
  Timer {
    interval: root.pollingInterval
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: {
      if (root._cpuTempPath !== "")
        _cpuTempFile.reload();

      _cpuStatFile.reload();
      _memInfoFile.reload();
      _netDevFile.reload();
      _diskStatsFile.reload();
      _loadAvgFile.reload();

      // Only while someone is watching; otherwise the slow poll has them.
      if (root._monitorOpen) {
        root._reloadBattery();
        _cpuInfoFile.reload();
      }

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
      _governorFile.reload();
      _eppFile.reload();
    }
  }

  // One read gives every core's clock. Reading the 32 scaling_cur_freq files
  // instead asks the hardware 32 times per poll for the same numbers.
  FileView {
    id: _cpuInfoFile
    path: "/proc/cpuinfo"
    printErrors: false

    onLoaded: {
      const freqs = [];
      let total = 0;

      for (const line of text().split("\n")) {
        if (!line.startsWith("cpu MHz"))
          continue;
        const mhz = parseFloat(line.substring(line.indexOf(":") + 1));
        if (isNaN(mhz))
          continue;
        freqs.push(mhz);
        total += mhz;
      }

      if (freqs.length === 0)
        return;

      root.cpuFreqs = freqs;
      root.cpuFreqAvg = total / freqs.length;
    }
  }

  // The scaling driver's own setting, which a power profile changes underneath.
  FileView {
    id: _governorFile
    path: "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
    printErrors: false
    onLoaded: root.cpuGovernor = text().trim()
  }

  FileView {
    id: _eppFile
    path: "/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference"
    printErrors: false
    onLoaded: root.cpuEpp = text().trim()
  }

  function _reloadBattery() {
    if (root._batteryPath !== "")
      _batteryFile.reload();
  }

  // Every figure in one read. Energy and power are microwatt-hours and microwatts.
  FileView {
    id: _batteryFile
    path: root._batteryPath === "" ? "" : root._batteryPath + "uevent"
    printErrors: false

    onLoaded: {
      const values = {};

      for (const line of text().split("\n")) {
        const match = line.match(root._batteryLine);
        if (match)
          values[match[1]] = match[2];
      }

      const number = name => parseInt(values[name], 10) || 0;

      root.batteryCharge = number("CAPACITY");
      root.batteryEnergy = number("ENERGY_NOW") / 1000000;
      root.batteryFull = number("ENERGY_FULL") / 1000000;
      root.batteryDesign = number("ENERGY_FULL_DESIGN") / 1000000;
      root.batteryPower = number("POWER_NOW") / 1000000;
      root.batteryCycles = number("CYCLE_COUNT");
      root.batteryStatus = values["STATUS"] ?? "";
    }
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

  // One long-running nvidia-smi in loop mode (`-l`): nearly all of its cost is
  // start-up, loading NVML, not the query. Without an NVIDIA GPU it exits at once
  // and stays down.
  Process {
    id: _nvidiaProcess
    command: root._nvidiaQuery.concat([String((root._monitorOpen ? root.pollingInterval : root.nvidiaPollingInterval) / 1000)])
    running: true

    stdout: SplitParser {
      splitMarker: "\n"
      onRead: data => {
        if (!root._readNvidia(data))
          return;

        root._nvidia = true;
      }
    }

    // Restart a loop that was working and died (driver reload, nvidia-smi
    // killed). The fixed delay means a persistent failure retries at the old
    // polling rate rather than spinning.
    onExited: {
      if (root._nvidia)
        _nvidiaRestart.restart();
    }
  }

  Timer {
    id: _nvidiaRestart
    interval: root.nvidiaPollingInterval
    repeat: false
    onTriggered: _nvidiaProcess.running = true
  }

  // A new rate needs a new process: the old one exits and the same object starts
  // again with the current command.
  on_MonitorOpenChanged: {
    if (!root._nvidia)
      return;
    _nvidiaProcess.running = false;
    _nvidiaProcess.running = true;
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

  // `pmon` also lists graphics-only clients such as Hyprland and Xwayland,
  // which --query-compute-apps leaves out.
  Timer {
    interval: root.pollingInterval
    repeat: true
    triggeredOnStart: true
    running: root._nvidia && root._monitorOpen
    onTriggered: _gpuProcessQuery.running = true
  }

  Core.Command {
    id: _gpuProcessQuery
    command: ["nvidia-smi", "pmon", "-c", "1", "-s", "m"]

    onDone: (code, out) => root._readGpuProcesses(out)
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

        // Per-core, indexed by the real core id, so a gap in the numbering cannot
        // shift the panel's "Core N" labels.
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

  function _isIgnoredInterface(iface) {
    for (const prefix of root._ignoredIfacePrefixes) {
      if (iface === prefix || iface.startsWith(prefix))
        return true;
    }
    return false;
  }

  // Growth per second of each field since the last sample of `name`, summed
  // over the devices in both and naming the one that grew most, or null for
  // the first sample. A device seen for the first time has nothing to compare
  // with, and a counter that went backwards was reset; neither may cancel
  // growth elsewhere.
  function _rates(name, current, fields) {
    const now = Date.now() / 1000;
    const last = root._lastSamples[name];
    root._lastSamples[name] = {
      sample: current,
      time: now
    };

    const seconds = last ? now - last.time : 0;
    if (seconds <= 0)
      return null;

    const result = {
      busiest: ""
    };
    let busiestGrowth = 0;
    for (const field of fields)
      result[field] = 0;

    for (const key in current) {
      const before = last.sample[key];
      if (!before)
        continue;

      let growth = 0;
      for (const field of fields) {
        const grown = Math.max(0, current[key][field] - before[field]);
        result[field] += grown;
        growth += grown;
      }
      if (growth > busiestGrowth) {
        busiestGrowth = growth;
        result.busiest = key;
      }
    }

    for (const field of fields)
      result[field] /= seconds;
    return result;
  }

  FileView {
    id: _netDevFile
    path: "/proc/net/dev"
    printErrors: false

    onLoaded: {
      const current = {};

      for (const line of text().split("\n").slice(2)) {
        const colonIdx = line.indexOf(":");
        if (colonIdx === -1)
          continue;

        const iface = line.substring(0, colonIdx).trim();
        if (root._isIgnoredInterface(iface))
          continue;

        const stats = line.substring(colonIdx + 1).trim().split(root._whitespace);
        current[iface] = {
          rx: parseInt(stats[0], 10) || 0,
          tx: parseInt(stats[8], 10) || 0
        };
      }

      const rate = root._rates("net", current, ["rx", "tx"]);
      if (!rate)
        return;

      root.netDownSpeed = Math.round(rate.rx);
      root.netUpSpeed = Math.round(rate.tx);

      // The active interface is the one moving bytes right now, not merely the
      // first one with a non-zero lifetime counter.
      if (rate.busiest !== "")
        root.netInterface = rate.busiest;
      else if (!(root.netInterface in current))
        root.netInterface = Object.keys(current)[0] ?? "";
    }
  }

  // Whole disks only. A partition's traffic is already counted on its disk, and
  // zram is compressed RAM rather than a device with a queue.
  readonly property var _virtualDisk: /^(loop|ram|zram|dm-|md|sr|fd)/
  readonly property var _diskPartition: /^(?:nvme\d+n\d+|mmcblk\d+)p\d+$|^(?:sd|vd|hd|xvd)[a-z]+\d+$/

  FileView {
    id: _diskStatsFile
    path: "/proc/diskstats"
    printErrors: false

    onLoaded: {
      const current = {};

      for (const line of text().split("\n")) {
        const parts = line.trim().split(root._whitespace);
        if (parts.length < 10)
          continue;

        const name = parts[2];
        if (root._virtualDisk.test(name) || root._diskPartition.test(name))
          continue;

        current[name] = {
          read: parseInt(parts[5], 10) || 0,
          write: parseInt(parts[9], 10) || 0
        };
      }

      // Sectors are always 512 bytes here, whatever the drive's own size is.
      const rate = root._rates("disk", current, ["read", "write"]);
      if (rate) {
        root.diskReadSpeed = Math.round(rate.read * 512);
        root.diskWriteSpeed = Math.round(rate.write * 512);
      }
    }
  }

  Core.Command {
    id: _diskProcess
    tag: "SystemStats"
    label: "df"
    command: ["df", "-B1", "--output=size,used,target", "/"]

    onDone: (code, out) => {
      const lines = out.trim().split("\n");
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

  // Parsing every process takes ~10 ms, so it happens in awk rather than on
  // the UI thread, and only the top rows come back.
  Process {
    command: ["awk", "-v", "top=5", "-v", "interval=" + root.pollingInterval / 1000, "-f", Quickshell.shellPath("services/scripts/top-apps.awk")]
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

  Core.Command {
    id: _killProcess
    tag: "SystemStats"
    label: "kill"
  }
}
