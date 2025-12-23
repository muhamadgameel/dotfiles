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
  property var networks: ({})
  property bool scanning: false
  property string connectingTo: ""
  property string disconnectingFrom: ""
  property string forgettingNetwork: ""
  property string lastError: ""

  // WiFi
  property bool wifiEnabled: true
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
    return b.signal - a.signal;
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
    wifiEnabled = enabled;
    _wifiToggleProcess.running = true;
  }

  function scan() {
    if (!wifiEnabled || scanning)
      return;
    scanning = true;
    lastError = "";
    _scanProcess.running = true;
  }

  function connect(ssid) {
    if (connecting)
      return;
    connectingTo = ssid;
    lastError = "";
    _connectProcess.ssid = ssid;
    _connectProcess.running = true;
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
    _connectionStatusProcess.running = true;
    _connectivityCheckProcess.running = true;
    scan();
    _monitorProcess.running = true;
  }

  // === Private ===
  readonly property var _wifiTypes: ["802-11-wireless", "wifi"]
  readonly property var _ethernetTypes: ["802-3-ethernet", "ethernet"]
  readonly property var _connectionEvents: [": connected", ": using connection", ": disconnected", ": deactivating", ": unmanaged"]
  readonly property var _errorMappings: [[/psk.*invalid|password.*invalid|incorrect password/i, "Incorrect password"], [/No network with SSID/i, "Network not found"], [/Timeout/i, "Connection timeout"]]

  // Parse nmcli colon-separated line from the end (handles SSIDs with colons)
  function _parseNmcliLine(line, fieldCount) {
    const result = [];
    let remaining = line;

    for (let i = 0; i < fieldCount - 1; i++) {
      const idx = remaining.lastIndexOf(":");
      if (idx === -1)
        return null;
      result.unshift(remaining.substring(idx + 1));
      remaining = remaining.substring(0, idx);
    }
    result.unshift(remaining);
    return result;
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
    const updated = Object.assign({}, networks);
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
    networks = updated;
  }

  // === Timers ===
  Timer {
    id: _refreshDebounce
    interval: 100
    onTriggered: _connectionStatusProcess.running = true
  }

  Timer {
    id: _scanTimer
    interval: 60000
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
          root.networks = ({});
        }
      }
    }

    onExited: {
      Core.Logger.w("Network", "Monitor exited, restarting...");
      Qt.callLater(() => _monitorProcess.running = true);
    }
  }

  // WiFi radio toggle
  Process {
    id: _wifiToggleProcess
    command: ["nmcli", "radio", "wifi", root.wifiEnabled ? "on" : "off"]
  }

  // Active connection status
  Process {
    id: _connectionStatusProcess
    command: ["nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "connection", "show", "--active"]

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
    command: ["nmcli", "-t", "-f", "IP4.ADDRESS,IP4.GATEWAY,IP4.DNS", "device", "show", device]

    stdout: StdioCollector {
      onStreamFinished: {
        let ip = "", gateway = "";
        const dnsServers = [];

        for (const line of text.split("\n")) {
          const idx = line.indexOf(":");
          if (idx <= 0)
            continue;

          const key = line.substring(0, idx);
          const value = line.substring(idx + 1);

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

  // WiFi scan
  Process {
    id: _scanProcess
    command: ["nmcli", "-t", "-f", "SSID,SECURITY,SIGNAL,IN-USE", "device", "wifi", "list", "--rescan", "yes"]

    stdout: StdioCollector {
      onStreamFinished: {
        const networksMap = {};

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

          // Keep highest signal entry for each SSID
          if (!networksMap[ssid] || signal > networksMap[ssid].signal) {
            networksMap[ssid] = {
              ssid,
              security: security || "--",
              signal,
              connected,
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

  // WiFi connect
  Process {
    id: _connectProcess
    property string ssid: ""
    command: ["nmcli", "device", "wifi", "connect", ssid]

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
