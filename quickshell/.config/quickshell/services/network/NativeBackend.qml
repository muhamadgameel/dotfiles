import QtQuick
import Quickshell
import Quickshell.Networking

import "../../core" as Core

/**
* NativeBackend - network state and actions through Quickshell.Networking
*
* Talks to NetworkManager over D-Bus, so there is no `nmcli monitor` and no
* polling. IP, gateway and DNS still come from nmcli (DeviceDetails), because
* the module does not expose them. Created by services/Network.qml when the
* networkBackend setting is "native".
*
* Limits in Quickshell 0.3.1:
* - Only networks in range can be listed, so only those can be forgotten.
* - No hidden or enterprise (802.1X) networks.
* - State goes stale if NetworkManager restarts; restart the shell.
* - Scan churn has crashed the shell for others (quickshell#1021).
*/
Scope {
  id: root

  // Whether the network panel is visible. Gates the scanner.
  property bool panelOpen: false

  // === State ===
  // Rows are plain values, never the module's WifiNetwork objects: those are
  // deleted when a network drops out of range, and QML that held on to them
  // has crashed. Actions look the live object up by SSID when they run.
  readonly property var networks: {
    const map = Object.create(null);
    for (const network of _wifiNetworks) {
      if (!network.name)
        continue;
      map[network.name] = {
        ssid: network.name,
        security: _securityLabel(network.security),
        signal: Math.round(network.signalStrength * 100),
        connected: network.connected,
        secured: _isSecured(network.security),
        known: network.known
      };
    }
    return map;
  }

  // The scanner runs continuously while the panel is open; there is no one-off
  // scan to start or report on.
  readonly property bool scanning: false
  readonly property bool canScan: false

  property string connectingTo: ""
  property string disconnectingFrom: ""
  property string forgettingNetwork: ""
  property string lastError: ""
  property string passwordRequiredFor: ""

  // WiFi
  readonly property bool wifiEnabled: Networking.wifiEnabled
  readonly property bool wifiConnected: _activeWifi !== null
  readonly property string wifiSSID: _activeWifi?.name ?? ""
  readonly property int wifiSignal: Math.round((_activeWifi?.signalStrength ?? 0) * 100)
  readonly property string wifiSecurity: _activeWifi ? _securityLabel(_activeWifi.security) : ""

  // Ethernet (includes USB tethering)
  readonly property bool ethernetConnected: _wiredDevice !== null
  readonly property string ethernetInterface: _wiredDevice?.name ?? ""

  // Connectivity & Active Connection
  readonly property string connectivityStatus: {
    switch (Networking.connectivity) {
    case NetworkConnectivity.Full:
      return "full";
    case NetworkConnectivity.Limited:
      return "limited";
    case NetworkConnectivity.Portal:
      return "portal";
    case NetworkConnectivity.None:
      return "none";
    default:
      return "unknown";
    }
  }
  readonly property string activeInterface: ethernetConnected ? ethernetInterface : wifiConnected ? _wifiDevice.name : ""
  readonly property string activeIP: _details.ip
  readonly property string activeGateway: _details.gateway
  readonly property string activeDNS: _details.dns

  // === Actions ===
  function refreshAll() {
    _refreshDetails();
    Networking.checkConnectivity();
  }

  function setWifiEnabled(enabled) {
    Networking.wifiEnabled = enabled;
  }

  // No one-off scan exists; the scanner already runs while the panel is open.
  function scan(force) {
  }

  function connect(ssid, password) {
    if (connectingTo !== "")
      return;

    const network = _network(ssid);
    if (!network) {
      lastError = "Network not found";
      return;
    }

    const check = _connectCheck(network.security, network.known, password ?? "");
    lastError = check === "prompt" ? "" : check;
    // A typed key that failed the check keeps its prompt open, to fix it.
    passwordRequiredFor = check === "prompt" || (check !== "" && password) ? ssid : "";
    if (check !== "")
      return;

    if (_unwantedProfile !== ssid)
      _unwantedProfile = "";

    connectingTo = ssid;
    _attemptTarget = network;
    _attemptWithPassword = !!password;
    _attemptWasKnown = network.known;
    _attemptStarted = false;
    _connectTimer.interval = _startTimeoutMs;
    _connectTimer.restart();

    if (password)
      network.connectWithPsk(password);
    else
      network.connect();
  }

  function cancelPasswordPrompt() {
    // A first attempt at an unsaved network saves its profile even when the
    // key is wrong. Giving up removes it again, rather than leaving
    // NetworkManager retrying a bad key - unless NetworkManager has since got
    // in with it, or is trying it right now.
    const network = _unwantedProfile !== "" && _unwantedProfile === passwordRequiredFor ? _network(_unwantedProfile) : null;
    if (network && !network.connected && !network.stateChanging)
      network.forget();
    _unwantedProfile = "";

    passwordRequiredFor = "";
    lastError = "";
  }

  // Disconnects the device, which stays disconnected until the next manual
  // connect, a resume or a reboot - the same as the nmcli backend.
  function disconnect(ssid) {
    if (disconnectingFrom !== "")
      return;

    const network = _network(ssid);
    if (!network?.connected)
      return;

    disconnectingFrom = ssid;
    _disconnectTimer.restart();
    network.disconnect();
  }

  function forget(ssid) {
    if (forgettingNetwork !== "")
      return;

    // Nothing saved, nothing to delete.
    const network = _network(ssid);
    if (!network?.known)
      return;

    forgettingNetwork = ssid;
    _forgetTimer.restart();
    network.forget();
  }

  // === Private ===
  readonly property var _wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
  readonly property var _wiredDevice: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected) ?? null
  readonly property var _wifiNetworks: _wifiDevice?.networks.values ?? []
  readonly property var _activeWifi: _wifiNetworks.find(n => n.connected) ?? null

  // The connect attempt in progress.
  property var _attemptTarget: null
  property bool _attemptWithPassword: false
  property bool _attemptWasKnown: false
  property bool _attemptStarted: false

  // SSID whose profile the last failed attempt created.
  property string _unwantedProfile: ""

  // How long NetworkManager gets to start an attempt, and then to finish it.
  // Failures that the module has no reason for (a rejected D-Bus call, DHCP
  // giving up) are only noticed by these.
  readonly property int _startTimeoutMs: 15000
  readonly property int _activationTimeoutMs: 90000

  function _network(ssid) {
    return _wifiNetworks.find(n => n.name === ssid) ?? null;
  }

  function _securityLabel(security) {
    return security === WifiSecurityType.Open || security === WifiSecurityType.Unknown ? "--" : WifiSecurityType.toString(security);
  }

  function _isSecured(security) {
    return security !== WifiSecurityType.Open && security !== WifiSecurityType.Owe && security !== WifiSecurityType.Unknown;
  }

  // Networks a typed password can be used for. Enterprise and WEP ones cannot.
  function _takesPsk(security) {
    return security === WifiSecurityType.WpaPsk || security === WifiSecurityType.Wpa2Psk || security === WifiSecurityType.Sae;
  }

  // NetworkManager's rule for a WPA key: 8 to 63 bytes, or 64 hex digits. It
  // rejects anything else without saying why. WPA3 takes any length.
  function _pskValid(security, password) {
    if (security === WifiSecurityType.Sae)
      return true;
    const bytes = encodeURIComponent(password).replace(/%[0-9A-F]{2}/g, "x").length;
    return (bytes >= 8 && bytes <= 63) || /^[0-9a-fA-F]{64}$/.test(password);
  }

  /**
  * Whether a connect can go ahead, checked before anything reaches
  * NetworkManager.
  *
  * @returns "" to go ahead, "prompt" to ask for a key first, or an error
  */
  function _connectCheck(security, known, password) {
    const takesPsk = _takesPsk(security);
    const unsupported = `${WifiSecurityType.toString(security)} networks are not supported`;

    if (password !== "") {
      if (!takesPsk)
        return unsupported;
      if (!_pskValid(security, password))
        return "Password must be 8 to 63 characters";
      return "";
    }

    if (known || !_isSecured(security))
      return "";

    // Unsaved and secured. Connecting without a key would still save a
    // profile, then fail - ask for the key first.
    return takesPsk ? "prompt" : unsupported;
  }

  function _finishAttempt() {
    connectingTo = "";
    _attemptTarget = null;
    _unwantedProfile = "";
    _connectTimer.stop();
    _failGrace.stop();
  }

  /**
  * @param reason - A ConnectionFailReason, or null when the module gave none
  * @param message - Error to show when there is no reason
  */
  function _failAttempt(reason, message) {
    if (connectingTo === "")
      return;

    const ssid = connectingTo;
    const security = _attemptTarget?.security ?? WifiSecurityType.Unknown;

    connectingTo = "";
    _attemptTarget = null;
    _connectTimer.stop();
    _failGrace.stop();

    const why = reason === null ? message : ConnectionFailReason.toString(reason);
    Core.Logger.w("Network", `Connect to ${ssid} failed: ${why}`);

    // A wrong key shows up as NoSecrets, WifiAuthTimeout or even
    // WifiNetworkLost: WPA3, which WPA2 networks also use when the card
    // supports it, rejects a key before it associates, and NetworkManager
    // reports that as the network not being found. So any reported failure on
    // a network that takes a key asks for it again.
    if (reason !== null && _takesPsk(security)) {
      passwordRequiredFor = ssid;
      if (reason === ConnectionFailReason.WifiNetworkLost)
        lastError = _attemptWithPassword ? "Incorrect password, or the network is out of range" : "Network not found";
      else
        lastError = _attemptWithPassword ? "Incorrect password" : "";
      if (_attemptWithPassword && !_attemptWasKnown)
        _unwantedProfile = ssid;
      return;
    }

    // Nothing here says the key was wrong, so a saved profile stays.
    _unwantedProfile = "";

    if (reason === ConnectionFailReason.NoSecrets)
      lastError = "No saved credentials for this network";
    else if (reason === ConnectionFailReason.WifiNetworkLost)
      lastError = "Network not found";
    else if (reason === ConnectionFailReason.WifiAuthTimeout)
      lastError = "Connection timeout";
    else
      lastError = message || "Could not connect";
  }

  function _refreshDetails() {
    _details.device = activeInterface;
    _details.refresh();
  }

  function _syncScanner() {
    if (_wifiDevice)
      _wifiDevice.scannerEnabled = panelOpen && wifiEnabled;
  }

  // Details are re-read when the link changes; NetworkManager only reports a
  // connection as connected once its IP configuration is up.
  onActiveInterfaceChanged: _refreshDetails()
  onWifiSSIDChanged: _refreshDetails()

  // Networks that are neither saved nor connected leave the list the moment
  // the scanner stops, so closing waits until the panel has slid away.
  onPanelOpenChanged: {
    if (panelOpen) {
      _scannerOffDelay.stop();
      _syncScanner();
    } else {
      _scannerOffDelay.restart();
    }
  }
  on_WifiDeviceChanged: _syncScanner()

  onWifiEnabledChanged: {
    _syncScanner();
    if (!wifiEnabled) {
      passwordRequiredFor = "";
      lastError = "";
      _unwantedProfile = "";
    }
  }

  onNetworksChanged: {
    if (connectingTo !== "" && networks[connectingTo]?.connected)
      _finishAttempt();

    // NetworkManager can retry a profile on its own and get in. Its prompt no
    // longer applies, and a profile that works is not one to remove.
    if (_unwantedProfile !== "" && networks[_unwantedProfile]?.connected)
      _unwantedProfile = "";
    if (passwordRequiredFor !== "" && networks[passwordRequiredFor]?.connected) {
      passwordRequiredFor = "";
      lastError = "";
    }

    if (disconnectingFrom !== "" && !networks[disconnectingFrom]?.connected) {
      disconnectingFrom = "";
      _disconnectTimer.stop();
    }

    if (forgettingNetwork !== "" && !networks[forgettingNetwork]?.known) {
      forgettingNetwork = "";
      _forgetTimer.stop();
    }
  }

  Component.onCompleted: {
    Core.Logger.i("Network", "Native backend started");
    _syncScanner();
    _refreshDetails();
  }

  // The scanner is a property of the device, which outlives this backend.
  Component.onDestruction: {
    if (_wifiDevice)
      _wifiDevice.scannerEnabled = false;
  }

  // === Attempt tracking ===
  Connections {
    target: root._attemptTarget

    function onConnectionFailed(reason) {
      root._failAttempt(reason, "");
    }

    function onStateChanged() {
      const state = root._attemptTarget?.state;
      if (state === ConnectionState.Connecting && !root._attemptStarted) {
        root._attemptStarted = true;
        _connectTimer.interval = root._activationTimeoutMs;
        _connectTimer.restart();
      } else if (state === ConnectionState.Disconnected && root._attemptStarted) {
        // connectionFailed, when there is one, can land just after this.
        _failGrace.restart();
      }
    }
  }

  Timer {
    id: _connectTimer
    onTriggered: root._failAttempt(null, root._attemptStarted ? "Connection timeout" : "Could not connect")
  }

  Timer {
    id: _scannerOffDelay
    interval: Core.Style.slideHideDuration + 150
    onTriggered: root._syncScanner()
  }

  Timer {
    id: _failGrace
    interval: 1000
    onTriggered: root._failAttempt(null, "Could not connect")
  }

  Timer {
    id: _disconnectTimer
    interval: 15000
    onTriggered: {
      root.lastError = "Could not disconnect";
      root.disconnectingFrom = "";
    }
  }

  Timer {
    id: _forgetTimer
    interval: 10000
    onTriggered: {
      root.lastError = "Could not forget network";
      root.forgettingNetwork = "";
    }
  }

  DeviceDetails {
    id: _details
  }
}
