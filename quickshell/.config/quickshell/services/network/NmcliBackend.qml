import QtQuick
import Quickshell
import Quickshell.Io

import "../../core" as Core

/**
* NmcliBackend - network state and actions through nmcli
*
* Uses nmcli monitor for real-time D-Bus event detection. Created by
* services/Network.qml, which is what the UI talks to.
*/
Scope {
  id: root

  // === Public State ===
  property var networks: Object.create(null)
  property bool scanning: false
  readonly property bool canScan: true
  property string connectingTo: ""
  property string disconnectingFrom: ""
  property string forgettingNetwork: ""
  property string lastError: ""

  // SSID that NetworkManager reported it has no key for, and which is now
  // waiting on a password. Empty when no prompt is pending.
  property string passwordRequiredFor: ""

  // Whether the network panel is visible. Gates active rescans, which stall
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
  readonly property string activeIP: _details.ip
  readonly property string activeGateway: _details.gateway
  readonly property string activeDNS: _details.dns

  // === Actions ===
  function refreshAll() {
    _connectionStatusProcess.running = true;
    // Rescans once it has confirmed the radio is on.
    _wifiStateProcess.running = true;
  }

  function setWifiEnabled(enabled) {
    // The desired state goes to the process explicitly. Binding the command to
    // `wifiEnabled` and mutating it in the same call relied on the binding
    // re-evaluating before `running` was set.
    _wifiToggleProcess.command = ["nmcli", "radio", "wifi", enabled ? "on" : "off"];
    _wifiToggleProcess.running = true;

    // Shown at once. _wifiToggleProcess reads the radio back when it finishes,
    // which corrects this if the switch did not take.
    wifiEnabled = enabled;
    if (!enabled)
      _clearWifiState();
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
    if (!wifiEnabled)
      return;

    const active = force ?? panelOpen;

    // Queue rather than drop: the scan already running may have started before
    // the change this call is reacting to.
    if (scanning) {
      _scanQueued = true;
      _scanQueuedActive = _scanQueuedActive || active;
      return;
    }

    // lastError is deliberately left alone. Clearing it here meant the 20s
    // timer wiped a connect error - "Incorrect password" included - while the
    // user was still reading it.
    // Which networks are saved only matters on the panel's rows. nmcli monitor
    // says nothing when a profile is added or deleted, so it is re-read here.
    if (panelOpen)
      _savedProcess.running = true;

    scanning = true;
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
    if (connectingTo !== "")
      return;

    connectingTo = ssid;
    lastError = "";
    passwordRequiredFor = "";

    _connectProcess.ssid = ssid;
    _connectProcess.withPassword = !!password;
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

  /**
  * Disconnect Wi-Fi, and stay disconnected.
  *
  * Disconnects the device rather than bringing its profile down. `nmcli
  * connection down` leaves the device free to autoconnect, so NetworkManager
  * would join another saved network in range within seconds. The device
  * autoconnects again after the next manual connect, a resume or a reboot.
  *
  * @param ssid - Network being disconnected, for the row's busy state
  */
  function disconnect(ssid) {
    // One at a time: a second call would retarget the running process's
    // result at the wrong row.
    if (disconnectingFrom !== "" || _wifiDevice === "")
      return;

    disconnectingFrom = ssid;
    _disconnectProcess.ssid = ssid;
    _disconnectProcess.command = ["nmcli", "device", "disconnect", _wifiDevice];
    _disconnectProcess.running = true;
  }

  /**
  * Delete every saved Wi-Fi profile for a network.
  */
  function forget(ssid) {
    if (forgettingNetwork !== "")
      return;

    forgettingNetwork = ssid;
    _forgetProcess.ssid = ssid;
    _forgetProcess.command = ["sh", "-c", _forgetScript, "sh", ssid];
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
  // `nmcli monitor` lines that can change what is connected or whether the
  // radio is on. The monitor prints nothing for the radio itself, so each of
  // these re-reads it too (see _refreshDebounce).
  // - ": unavailable": a cable unplugged or the radio switched off, which skip
  //   "disconnected" entirely.
  // - "primary connection": the default route moved to another link.
  // - "NetworkManager is running": it restarted, and anything may have changed.
  readonly property var _connectionEvents: [": connected", ": using connection", ": disconnected", ": deactivating", ": unmanaged", ": unavailable", ": device removed", "primary connection", "NetworkManager is running"]
  readonly property var _errorMappings: [[/No network with SSID/i, "Network not found"], [/Timeout/i, "Connection timeout"]]

  // Wi-Fi interface of the active connection, which disconnect() acts on.
  property string _wifiDevice: ""

  // A scan asked for while one was running, run when it finishes.
  property bool _scanQueued: false
  property bool _scanQueuedActive: false

  // Deletes every saved Wi-Fi profile whose SSID is $1. Profiles are matched on
  // the SSID they hold and deleted by UUID. Deleting by *name*, as before,
  // missed a profile named differently from its SSID, and would have deleted a
  // wired or VPN profile that happened to share the name.
  readonly property string _forgetScript: `
    nmcli -t -f UUID,TYPE connection show | while IFS=: read -r uuid type; do
      [ "$type" = 802-11-wireless ] || continue
      [ "$(nmcli -e no -g 802-11-wireless.ssid connection show uuid "$uuid")" = "$1" ] || continue
      nmcli connection delete uuid "$uuid" || exit
    done`

  // SSIDs that have a saved Wi-Fi profile, as read by _savedProcess.
  property var _savedSsids: []

  // Prints the SSID of every saved Wi-Fi profile, one per line. The guard
  // matters: `connection show` with no profile named lists every connection.
  readonly property string _savedScript: `
    uuids=$(nmcli -t -f UUID,TYPE connection show | awk -F: '$2 == "802-11-wireless" { printf "uuid %s ", $1 }')
    [ -z "$uuids" ] || nmcli -e no -g 802-11-wireless.ssid connection show $uuids`

  // NetworkManager asked for a key. Without one supplied, that is the first
  // prompt. With one supplied, it is how nmcli reports a key the network
  // rejected - see _connectProcess.
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

  function _logError(tag, text) {
    const msg = text.trim();
    if (msg)
      Core.Logger.w("Network", `${tag}: ${msg}`);
  }

  // The first line of nmcli's stderr worth showing. After a NetworkManager
  // upgrade, and until the daemon restarts, every command's stderr starts with
  // a "Warning: ... versions don't match" line, which used to become the error.
  function _firstError(text) {
    return text.split("\n").map(line => line.trim()).find(line => line && !line.startsWith("Warning:")) ?? "";
  }

  // Everything that only means something while the radio is on. The connection
  // itself is left to _connectionStatusProcess, which the monitor re-runs as
  // the device goes down.
  function _clearWifiState() {
    networks = Object.create(null);
    wifiSignal = 0;
    wifiSecurity = "";
    passwordRequiredFor = "";
    lastError = "";
  }

  function _triggerRefresh() {
    _refreshDebounce.restart();
  }

  function _updateNetworkConnection(ssid, connected) {
    // Update networks list immediately without waiting for scan
    const updated = Object.assign(Object.create(null), root.networks);
    for (const key in updated) {
      if (key === ssid) {
        // A network that has connected has a saved profile.
        updated[key] = Object.assign({}, updated[key], {
          connected: connected,
          known: connected || updated[key].known
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

  // Sets each row's `known` from _savedSsids.
  function _markSaved(map) {
    const marked = Object.create(null);
    for (const ssid in map) {
      marked[ssid] = Object.assign({}, map[ssid], {
        known: _savedSsids.includes(ssid)
      });
    }
    return marked;
  }

  // === Timers ===
  // Collapses a burst of monitor events into one refresh. A single connection
  // change prints several lines ("using connection", "connecting", "connected"),
  // and the connectivity check used to fire on every one of them outside this
  // debounce - each a real HTTP request to NetworkManager's check endpoint.
  Timer {
    id: _refreshDebounce
    interval: 100
    onTriggered: {
      _connectionStatusProcess.running = true;
      _connectivityCheckProcess.running = true;
      // Re-reads the radio and then the cached scan list, so the rows'
      // Connected badges and the signal in the bar follow a change the panel
      // did not make: autoconnect, a dropped link, an rfkill key.
      _wifiStateProcess.running = true;
    }
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
      }
    }

    onExited: {
      // Restarting on the spot would spin a process as fast as it could fail.
      // Back off, and reset once a run has survived a while. (A stopped
      // NetworkManager does not end the monitor: it prints "NetworkManager is
      // stopped" and waits.)
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

  // Wi-Fi radio state. Read at startup, after every connection event and after
  // each toggle - `nmcli monitor` prints nothing when the radio changes, so
  // this is how an rfkill key or a terminal `nmcli radio wifi off` is noticed.
  Process {
    id: _wifiStateProcess
    command: ["nmcli", "radio", "wifi"]

    stdout: StdioCollector {
      id: _wifiStateOut
    }

    onExited: exitCode => {
      // A failed read is not an answer. Taking it as "disabled" turned Wi-Fi
      // off in the shell for the whole session if NetworkManager was not up yet.
      const state = _wifiStateOut.text.trim();
      if (exitCode !== 0 || (state !== "enabled" && state !== "disabled"))
        return;

      root.wifiEnabled = state === "enabled";
      if (root.wifiEnabled)
        root.scan(false);
      else
        root._clearWifiState();
    }
  }

  // Wi-Fi radio toggle. `command` is set by setWifiEnabled() before each run.
  Process {
    id: _wifiToggleProcess

    stderr: StdioCollector {
      onStreamFinished: root._logError("Wi-Fi toggle", text)
    }

    // Read back what actually happened. A refused toggle fails, but a radio
    // held off by rfkill reports success, so only the read-back catches both.
    onExited: _wifiStateProcess.running = true
  }

  // Active connection status
  Process {
    id: _connectionStatusProcess
    command: ["nmcli", "-t", "-e", "yes", "-f", "NAME,TYPE,DEVICE,STATE", "connection", "show", "--active"]

    stdout: StdioCollector {
      onStreamFinished: {
        let wifi = false, eth = false;
        let wifiName = "", wifiIface = "", ethIface = "", activeIface = "";

        for (const line of text.split("\n")) {
          const parts = root._parseNmcliLine(line, 4);
          if (!parts)
            continue;

          const [name, type, device, state] = parts;

          // `--active` also lists connections still activating or deactivating.
          // Counting those showed a network as connected while it was still
          // authenticating, including ones about to fail.
          if (state !== "activated")
            continue;

          if (root._wifiTypes.includes(type)) {
            wifi = true;
            wifiName = name;
            wifiIface = device;
            activeIface = device;
          } else if (root._ethernetTypes.includes(type)) {
            eth = true;
            ethIface = device;
            activeIface = device;
          }
        }

        root.wifiConnected = wifi;
        root.wifiSSID = wifi ? wifiName : "";
        root._wifiDevice = wifiIface;
        root.ethernetConnected = eth;
        root.ethernetInterface = ethIface;
        root.activeInterface = activeIface;

        _details.device = activeIface;
        _details.refresh();
      }
    }
  }

  // Connection details (IP, gateway, DNS)
  DeviceDetails {
    id: _details
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
  //
  // The processes below act on exitCode, not on what nmcli printed. `exited`
  // arrives after both streams have been read, so the collected text is
  // complete by then. Matching stdout text reported every failure as success.
  Process {
    id: _scanProcess

    stdout: StdioCollector {
      id: _scanOut
    }

    stderr: StdioCollector {
      onStreamFinished: root._logError("Scan", text)
    }

    onExited: exitCode => {
      root.scanning = false;

      // A failed run (NetworkManager restarting, the device not ready) keeps
      // the last list rather than blanking the panel. An empty list from a
      // run that succeeded is real - nothing in range, or the radio went off -
      // and used to be mistaken for a failure, so the old list never cleared.
      if (exitCode !== 0) {
        Core.Logger.d("Network", `Scan failed (exit ${exitCode}); keeping the previous list`);
      } else if (root.wifiEnabled) {
        // SSIDs are arbitrary strings, including Object prototype names.
        const networksMap = Object.create(null);
        let inUseSignal = 0, inUseSecurity = "";

        for (const line of _scanOut.text.split("\n")) {
          const parts = root._parseNmcliLine(line, 4);
          if (!parts)
            continue;

          const [ssid, security, signalStr, inUse] = parts;
          if (!ssid)
            continue;

          const signal = parseInt(signalStr) || 0;
          const connected = inUse === "*";

          if (connected) {
            inUseSignal = signal;
            inUseSecurity = security;
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
              secured: !!(security && security !== "--" && security.trim()),
              known: root._savedSsids.includes(ssid)
            };
          } else if (connected) {
            networksMap[ssid].connected = true;
          }
        }

        root.networks = networksMap;
        // Reset when nothing is in use, rather than keeping the last network's.
        root.wifiSignal = inUseSignal;
        root.wifiSecurity = inUseSecurity;
        Core.Logger.d("Network", `Scan complete: ${Object.keys(networksMap).length} networks`);
      }

      if (root._scanQueued) {
        const active = root._scanQueuedActive;
        root._scanQueued = false;
        root._scanQueuedActive = false;
        root.scan(active);
      }
    }
  }

  // WiFi connect. `command` is set by connect(), which decides whether a
  // password is included.
  Process {
    id: _connectProcess
    property string ssid: ""
    property bool withPassword: false

    stderr: StdioCollector {
      id: _connectErr
    }

    onExited: exitCode => {
      const ssid = _connectProcess.ssid;
      root.connectingTo = "";

      if (exitCode === 0) {
        Core.Logger.i("Network", `Connected to: ${ssid}`);
        // Immediately update networks list to reflect connection
        root._updateNetworkConnection(ssid, true);
        return;
      }

      const stderr = _connectErr.text;

      // NetworkManager wants a key. When one was supplied, this is a wrong
      // password: nmcli reports a rejected key as "Secrets were required", not
      // as anything about the password. Checking this before _badPassword used
      // to re-prompt silently, with no sign the key had been wrong.
      if (root._secretsRequired.test(stderr)) {
        root.passwordRequiredFor = ssid;
        if (_connectProcess.withPassword) {
          root.lastError = "Incorrect password";
          Core.Logger.w("Network", `Connect: ${stderr.trim()}`);
        } else {
          root.lastError = "";
          Core.Logger.d("Network", `Password required for ${ssid}`);
        }
        return;
      }

      // Wrong key - ask again rather than dead-ending on the raw message.
      if (root._badPassword.test(stderr)) {
        root.passwordRequiredFor = ssid;
        root.lastError = "Incorrect password";
        Core.Logger.w("Network", `Connect: ${stderr.trim()}`);
        return;
      }

      Core.Logger.w("Network", `Connect (exit ${exitCode}): ${stderr.trim()}`);

      // Map common errors to user-friendly messages
      for (const [pattern, message] of root._errorMappings) {
        if (pattern.test(stderr)) {
          root.lastError = message;
          return;
        }
      }

      root.lastError = root._firstError(stderr) || "Could not connect";
    }
  }

  // WiFi disconnect. `command` is set by disconnect().
  Process {
    id: _disconnectProcess
    property string ssid: ""

    stderr: StdioCollector {
      id: _disconnectErr
    }

    onExited: exitCode => {
      root.disconnectingFrom = "";

      if (exitCode !== 0) {
        root.lastError = root._firstError(_disconnectErr.text) || "Could not disconnect";
        root._logError("Disconnect", _disconnectErr.text);
        return;
      }

      Core.Logger.i("Network", `Disconnected from: ${_disconnectProcess.ssid}`);
      // Immediately update networks list to reflect disconnection
      root._updateNetworkConnection(_disconnectProcess.ssid, false);
    }
  }

  // Forget saved network. `command` is set by forget().
  Process {
    id: _forgetProcess
    property string ssid: ""

    stderr: StdioCollector {
      id: _forgetErr
    }

    onExited: exitCode => {
      root.forgettingNetwork = "";

      if (exitCode !== 0) {
        root.lastError = root._firstError(_forgetErr.text) || "Could not forget network";
        root._logError("Forget", _forgetErr.text);
        return;
      }

      // Also reached when nothing was saved for this network: there was
      // nothing to delete, which is the outcome asked for.
      Core.Logger.i("Network", `Forgot network: ${_forgetProcess.ssid}`);
      root.scan();
    }
  }

  // Saved Wi-Fi profiles. Started by scan() while the panel is open.
  Process {
    id: _savedProcess
    command: ["sh", "-c", root._savedScript]

    stdout: StdioCollector {
      id: _savedOut
    }

    stderr: StdioCollector {
      onStreamFinished: root._logError("Saved networks", text)
    }

    onExited: exitCode => {
      if (exitCode !== 0)
        return;
      root._savedSsids = _savedOut.text.split("\n").filter(ssid => ssid !== "");
      root.networks = root._markSaved(root.networks);
    }
  }
}
