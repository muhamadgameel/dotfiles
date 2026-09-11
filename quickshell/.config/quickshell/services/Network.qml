pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../core" as Core

/**
* Network - Service for managing network connections (WiFi and Ethernet)
* Uses nmcli monitor for real-time D-Bus event detection
*/
Singleton {
  id: root

  // === Public State ===
  property var networks: Object.create(null)
  property bool scanning: false
  property string connectingTo: ""
  property string disconnectingFrom: ""
  property string forgettingNetwork: ""
  property string lastError: ""

  // SSID that NetworkManager reported it has no key for, and which is now
  // waiting on a password. Empty when no prompt is pending.
  property string passwordRequiredFor: ""

  // Set by NetworkPanel while it is visible. Gates active rescans, which stall
  // the current connection briefly and are not worth running unattended.
  property bool panelOpen: false

  // WiFi
  property bool wifiEnabled: false
  property bool wifiConnected: false
  property string wifiSSID: ""
  property int wifiSignal: 0
  property string wifiSecurity: ""

  // Ethernet (includes USB tethering)
  property bool ethernetConnected: false
  property string ethernetInterface: ""

  // Connectivity & Active Connection
  property string connectivityStatus: "unknown"
  property string activeInterface: ""
  property string activeIP: ""
  property string activeGateway: ""
  property string activeDNS: ""

  // === Computed Properties ===
  readonly property bool connecting: connectingTo !== ""
  readonly property bool isConnected: wifiConnected || ethernetConnected
  readonly property bool hasInternet: connectivityStatus === "full"

  readonly property string connectionIcon: {
    if (!isConnected)
      return "network-off";
    if (ethernetConnected)
      return "network";
    if (!hasInternet)
      return "wifi-off";
    return getSignalIcon(wifiSignal);
  }

  readonly property string connectionStatusText: {
    if (!isConnected)
      return "Disconnected";
    if (ethernetConnected)
      return "Ethernet";
    return wifiSSID;
  }

  readonly property string connectionTypeName: ethernetConnected ? "Ethernet" : wifiConnected ? "Wi-Fi" : "None"

  readonly property var sortedNetworks: Object.values(networks).sort((a, b) => {
    if (a.connected !== b.connected)
      return b.connected - a.connected;
    if (a.signal !== b.signal)
      return (b.signal ?? 0) - (a.signal ?? 0);
    return (a.ssid ?? "").localeCompare(b.ssid ?? "");
  })

  readonly property string connectivityStatusText: ({
      "full": "✓ Connected",
      "limited": "⚠ Limited",
      "portal": "⚠ Captive Portal",
      "none": "✗ No Internet"
    })[connectivityStatus] ?? "Unknown"

  // === Public API ===
  function getSignalIcon(signal) {
    if (signal >= 80)
      return "wifi-strong";
    if (signal >= 50)
      return "wifi-medium";
    return "wifi-weak";
  }

  function refreshAll() {
    _connectionStatusProcess.running = true;
    scan();
  }

  function setWifiEnabled(enabled) {
    // The desired state goes to the process explicitly. Binding the command to
    // `wifiEnabled` and mutating it in the same call relied on the binding
    // re-evaluating before `running` was set.
    _wifiToggleProcess.command = ["nmcli", "radio", "wifi", enabled ? "on" : "off"];
    _wifiToggleProcess.running = true;
    wifiEnabled = enabled;
  }

  /**
  * Refresh the network list.
  *
  * @param force - Run an active rescan. That makes the radio hop every channel,
  *   which interrupts the current connection for a moment and costs power, so
  *   it is only worth doing while someone is looking at the list. Omit to mean
  *   "active only if the panel is open".
  */
  function scan(force) {
    if (!wifiEnabled || scanning)
      return;

    const active = force ?? panelOpen;

    scanning = true;
    lastError = "";
    _scanProcess.command = ["nmcli", "-t", "-e", "yes", "-f", "SSID,SECURITY,SIGNAL,IN-USE", "device", "wifi", "list", "--rescan", active ? "yes" : "no"];
    _scanProcess.running = true;
  }

  /**
  * Connect to a wireless network.
  *
  * @param ssid - Network to join
  * @param password - Optional pre-shared key. Omit for open or already-saved
  *   networks; if NetworkManager then reports that secrets are required,
  *   passwordRequiredFor is set so the UI can prompt and call this again.
  */
  function connect(ssid, password) {
    if (connecting)
      return;

    connectingTo = ssid;
    lastError = "";
    passwordRequiredFor = "";

    _connectProcess.ssid = ssid;
    _connectProcess.command = password ? ["nmcli", "device", "wifi", "connect", ssid, "password", password] : ["nmcli", "device", "wifi", "connect", ssid];
    _connectProcess.running = true;
  }

  /**
  * Dismiss a pending password prompt without connecting.
  */
  function cancelPasswordPrompt() {
    passwordRequiredFor = "";
    lastError = "";
  }

  function disconnect(ssid) {
    disconnectingFrom = ssid;
    _disconnectProcess.ssid = ssid;
    _disconnectProcess.running = true;
  }

  function forget(ssid) {
    forgettingNetwork = ssid;
    _forgetProcess.ssid = ssid;
    _forgetProcess.running = true;
  }

  // === Initialization ===
  Component.onCompleted: {
    Core.Logger.i("Network", "Service started");
    _wifiStateProcess.running = true;
    _connectionStatusProcess.running = true;
    _connectivityCheckProcess.running = true;
    _monitorProcess.running = true;
  }

  // === Private ===
  readonly property var _wifiTypes: ["802-11-wireless", "wifi"]
  readonly property var _ethernetTypes: ["802-3-ethernet", "ethernet"]
  readonly property var _connectionEvents: [": connected", ": using connection", ": disconnected", ": deactivating", ": unmanaged"]
  readonly property var _errorMappings: [[/No network with SSID/i, "Network not found"], [/Timeout/i, "Connection timeout"]]

  // NetworkManager holds no key for the network - a prompt, not a failure.
  readonly property var _secretsRequired: /secrets? (were|was) required|no secrets provided|secrets are required/i

  // The key we supplied was rejected - re-prompt rather than dead-end.
  readonly property var _badPassword: /psk.*invalid|password.*invalid|incorrect password|invalid.*key/i

  /**
  * Split one line of `nmcli -t` output into its fields.
  *
  * nmcli escapes a literal colon inside a value as "\:" and a literal
  * backslash as "\\". Splitting on every colon - from either end - therefore
  * mangles any SSID containing one. This walks left to right, honours the
  * escapes, and unescapes the values.
  *
  * @returns array of fieldCount strings, or null if the line does not match
  */
  function _parseNmcliLine(line, fieldCount) {
    if (!line)
      return null;

    const fields = [];
    let current = "";

    for (let i = 0; i < line.length; i++) {
      const ch = line[i];

      if (ch === "\\" && i + 1 < line.length) {
        current += line[i + 1];
        i++;
      } else if (ch === ":") {
        fields.push(current);
        current = "";
      } else {
        current += ch;
      }
    }
    fields.push(current);

    return fields.length === fieldCount ? fields : null;
  }

  // Undo nmcli's terse-mode escaping for a value that was split by something
  // other than _parseNmcliLine (a KEY:VALUE line cut at its first colon).
  function _unescapeNmcli(value) {
    return value ? value.replace(/\\(.)/g, "$1") : "";
  }

  function _logError(tag, text) {
    const msg = text.trim();
    if (msg)
      Core.Logger.w("Network", `${tag}: ${msg}`);
  }

  function _triggerRefresh() {
    _refreshDebounce.restart();
    _connectivityCheckProcess.running = true;
  }

  function _updateNetworkConnection(ssid, connected) {
    // Update networks list immediately without waiting for scan
    const updated = Object.assign(Object.create(null), root.networks);
    for (const key in updated) {
      if (key === ssid) {
        updated[key] = Object.assign({}, updated[key], {
          connected: connected
        });
      } else if (connected && updated[key].connected) {
        // If connecting to a new network, mark others as disconnected
        updated[key] = Object.assign({}, updated[key], {
          connected: false
        });
      }
    }
    root.networks = updated;
  }

  // === Timers ===
  Timer {
    id: _refreshDebounce
    interval: 100
    onTriggered: _connectionStatusProcess.running = true
  }

  // Brisk active scans while the panel is open, slow passive cache reads
  // otherwise. This used to force an active rescan every 60s indefinitely.
  Timer {
    id: _scanTimer
    interval: root.panelOpen ? 20000 : 120000
    running: root.wifiEnabled
    repeat: true
    onTriggered: root.scan()
  }

  // === Processes ===

  // Real-time network event monitor
  Process {
    id: _monitorProcess
    command: ["nmcli", "monitor"]

    stdout: SplitParser {
      splitMarker: "\n"
      onRead: data => {
        const line = data.trim();
        if (!line)
          return;

        Core.Logger.d("Network", `Monitor: ${line}`);

        // Connection state changes
        if (root._connectionEvents.some(e => line.includes(e))) {
          root._triggerRefresh();
          return;
        }

        // Connectivity changes
        const connMatch = line.match(/Connectivity is now '(\w+)'/);
        if (connMatch) {
          root.connectivityStatus = connMatch[1];
          _refreshDebounce.restart();
          return;
        }

        // WiFi radio state
        if (line.includes("WiFi is now enabled")) {
          root.wifiEnabled = true;
          root.scan();
        } else if (line.includes("WiFi is now disabled")) {
          root.wifiEnabled = false;
          root.wifiConnected = false;
          root.wifiSSID = "";
          root.wifiSignal = 0;
          root.wifiSecurity = "";
          root.networks = Object.create(null);
        }
      }
    }

    onExited: {
      // `nmcli monitor` exits at once when NetworkManager is not running, so
      // restarting on the spot spun a process as fast as it could fail. Back
      // off, and reset once a run has survived a while.
      const uptime = Date.now() - root._monitorStartedAt;
      if (uptime > root._monitorHealthyMs) {
        root._monitorBackoffMs = root._monitorMinBackoffMs;
      } else {
        root._monitorBackoffMs = Math.min(root._monitorBackoffMs * 2, root._monitorMaxBackoffMs);
      }

      Core.Logger.w("Network", `Monitor exited, retrying in ${root._monitorBackoffMs}ms`);
      _monitorRestart.interval = root._monitorBackoffMs;
      _monitorRestart.restart();
    }

    onRunningChanged: {
      if (running)
        root._monitorStartedAt = Date.now();
    }
  }

  // Backoff state for the nmcli monitor
  property real _monitorStartedAt: 0
  property int _monitorBackoffMs: 1000
  readonly property int _monitorMinBackoffMs: 1000
  readonly property int _monitorMaxBackoffMs: 60000
  readonly property int _monitorHealthyMs: 30000

  Timer {
    id: _monitorRestart
    repeat: false
    onTriggered: _monitorProcess.running = true
  }

  // WiFi radio state check
  Process {
    id: _wifiStateProcess
    command: ["nmcli", "radio", "wifi"]

    stdout: StdioCollector {
      onStreamFinished: {
        root.wifiEnabled = text.trim() === "enabled";
        if (root.wifiEnabled) {
          root.scan();
        }
      }
    }
  }

  // WiFi radio toggle. `command` is set by setWifiEnabled() before each run.
  Process {
    id: _wifiToggleProcess
  }

  // Active connection status
  Process {
    id: _connectionStatusProcess
    command: ["nmcli", "-t", "-e", "yes", "-f", "NAME,TYPE,DEVICE", "connection", "show", "--active"]

    stdout: StdioCollector {
      onStreamFinished: {
        let wifi = false, eth = false;
        let wifiName = "", ethIface = "", activeIface = "";

        for (const line of text.split("\n")) {
          const parts = root._parseNmcliLine(line, 3);
          if (!parts)
            continue;

          const [name, type, device] = parts;

          if (root._wifiTypes.includes(type)) {
            wifi = true;
            wifiName = name;
            activeIface = device;
          } else if (root._ethernetTypes.includes(type)) {
            eth = true;
            ethIface = device;
            activeIface = device;
          }
        }

        root.wifiConnected = wifi;
        root.wifiSSID = wifi ? wifiName : "";
        root.ethernetConnected = eth;
        root.ethernetInterface = ethIface;
        root.activeInterface = activeIface;

        if (activeIface) {
          _connectionDetailsProcess.device = activeIface;
          _connectionDetailsProcess.running = true;
        } else {
          root.activeIP = "";
          root.activeGateway = "";
          root.activeDNS = "";
        }
      }
    }
  }

  // Connection details (IP, gateway, DNS)
  Process {
    id: _connectionDetailsProcess
    property string device: ""
    command: ["nmcli", "-t", "-e", "yes", "-f", "IP4.ADDRESS,IP4.GATEWAY,IP4.DNS", "device", "show", device]

    stdout: StdioCollector {
      onStreamFinished: {
        let ip = "", gateway = "";
        const dnsServers = [];

        for (const line of text.split("\n")) {
          const idx = line.indexOf(":");
          if (idx <= 0)
            continue;

          const key = line.substring(0, idx);
          const value = root._unescapeNmcli(line.substring(idx + 1));

          if (key.startsWith("IP4.ADDRESS") && !ip)
            ip = value;
          else if (key === "IP4.GATEWAY")
            gateway = value;
          else if (key.startsWith("IP4.DNS"))
            dnsServers.push(value);
        }

        root.activeIP = ip;
        root.activeGateway = gateway;
        root.activeDNS = dnsServers.join(", ");
      }
    }
  }

  // Connectivity check
  Process {
    id: _connectivityCheckProcess
    command: ["nmcli", "networking", "connectivity", "check"]
    stdout: StdioCollector {
      onStreamFinished: root.connectivityStatus = text.trim()
    }
  }

  // WiFi scan. `command` is set by scan(), which picks the rescan mode.
  Process {
    id: _scanProcess

    stdout: StdioCollector {
      onStreamFinished: {
        // Nothing at all on stdout means nmcli itself failed - NetworkManager
        // restarting, the Wi-Fi device not ready yet - and stderr says why.
        // Replacing the list with that empty result blanked the panel. Keep the
        // last list instead; a radio that is really off is cleared by the
        // monitor, not by a scan.
        if (text.trim() === "") {
          root.scanning = false;
          Core.Logger.d("Network", "Scan returned nothing; keeping the previous list");
          return;
        }

        // SSIDs are arbitrary strings, including Object prototype names.
        const networksMap = Object.create(null);

        for (const line of text.split("\n")) {
          const parts = root._parseNmcliLine(line, 4);
          if (!parts)
            continue;

          const [ssid, security, signalStr, inUse] = parts;
          if (!ssid)
            continue;

          const signal = parseInt(signalStr) || 0;
          const connected = inUse === "*";

          if (connected) {
            root.wifiSignal = signal;
            root.wifiSecurity = security;
          }

          // Keep the strongest AP, but retain association with any AP of the
          // same SSID regardless of the order nmcli returned them in.
          const previous = networksMap[ssid];
          if (!previous || signal > previous.signal) {
            networksMap[ssid] = {
              ssid,
              security: security || "--",
              signal,
              connected: connected || (previous?.connected ?? false),
              secured: !!(security && security !== "--" && security.trim())
            };
          } else if (connected) {
            networksMap[ssid].connected = true;
          }
        }

        root.networks = networksMap;
        root.scanning = false;
        Core.Logger.d("Network", `Scan complete: ${Object.keys(networksMap).length} networks`);
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        root.scanning = false;
        root._logError("Scan", text);
      }
    }
  }

  // WiFi connect. `command` is set by connect(), which decides whether a
  // password is included.
  Process {
    id: _connectProcess
    property string ssid: ""

    stdout: StdioCollector {
      onStreamFinished: {
        if (text.includes("successfully")) {
          Core.Logger.i("Network", `Connected to: ${_connectProcess.ssid}`);
          // Immediately update networks list to reflect connection
          root._updateNetworkConnection(_connectProcess.ssid, true);
        }
        root.connectingTo = "";
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        root.connectingTo = "";

        const error = text.trim();
        if (!error)
          return;

        // No stored key for this network. That is a prompt, not a failure.
        if (root._secretsRequired.test(error)) {
          root.passwordRequiredFor = _connectProcess.ssid;
          root.lastError = "";
          Core.Logger.d("Network", `Password required for ${_connectProcess.ssid}`);
          return;
        }

        // Wrong key - ask again rather than dead-ending on the raw message.
        if (root._badPassword.test(error)) {
          root.passwordRequiredFor = _connectProcess.ssid;
          root.lastError = "Incorrect password";
          Core.Logger.w("Network", `Connect: ${error}`);
          return;
        }

        // Map common errors to user-friendly messages
        for (const [pattern, message] of root._errorMappings) {
          if (pattern.test(error)) {
            root.lastError = message;
            Core.Logger.w("Network", `Connect: ${error}`);
            return;
          }
        }

        root.lastError = error.split("\n")[0];
        Core.Logger.w("Network", `Connect: ${error}`);
      }
    }
  }

  // WiFi disconnect
  Process {
    id: _disconnectProcess
    property string ssid: ""
    command: ["nmcli", "connection", "down", "id", ssid]

    stdout: StdioCollector {
      onStreamFinished: {
        Core.Logger.i("Network", `Disconnected from: ${_disconnectProcess.ssid}`);
        // Immediately update networks list to reflect disconnection
        root._updateNetworkConnection(_disconnectProcess.ssid, false);
        root.disconnectingFrom = "";
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        root.disconnectingFrom = "";
        root._logError("Disconnect", text);
      }
    }
  }

  // Forget saved network
  Process {
    id: _forgetProcess
    property string ssid: ""
    command: ["nmcli", "connection", "delete", "id", ssid]

    stdout: StdioCollector {
      onStreamFinished: {
        Core.Logger.i("Network", `Forgot network: ${_forgetProcess.ssid}`);
        root.forgettingNetwork = "";
        root.scan();
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        root.forgettingNetwork = "";
        if (text.trim() && !text.includes("not found")) {
          root._logError("Forget", text);
        }
      }
    }
  }
}
