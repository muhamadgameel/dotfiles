pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import "../config" as Config
import "network" as Backends

/**
* Network - Wi-Fi and Ethernet state and actions for the UI
*
* A backend in services/network does the work and exposes raw state. What the
* UI derives from that state - icons, labels, sorting - lives here.
*
* The networkBackend setting picks the backend, and only that one is created:
* - "nmcli" (default): NmcliBackend
* - "native": NativeBackend, on Quickshell.Networking. A preview.
*
* Switch with `qs ipc call network backend native` (or `nmcli`).
*/
Singleton {
  id: root

  readonly property string backendName: Config.Config.networkBackend === "native" ? "native" : "nmcli"

  // Null for a moment at startup, until the loader has created it.
  readonly property var backend: backendName === "native" ? nativeBackend.item : nmcliBackend.item

  // === State (from the backend) ===
  // SSID -> { ssid, security, signal, connected, secured, known }. `known`
  // means a profile is saved for it.
  readonly property var networks: backend?.networks ?? ({})
  readonly property bool scanning: backend?.scanning ?? false
  // False when the backend keeps the list fresh on its own.
  readonly property bool canScan: backend?.canScan ?? false
  readonly property string connectingTo: backend?.connectingTo ?? ""
  readonly property string disconnectingFrom: backend?.disconnectingFrom ?? ""
  readonly property string forgettingNetwork: backend?.forgettingNetwork ?? ""
  readonly property string lastError: backend?.lastError ?? ""

  // SSID that NetworkManager reported it has no key for, and which is now
  // waiting on a password. Empty when no prompt is pending.
  readonly property string passwordRequiredFor: backend?.passwordRequiredFor ?? ""

  // Whether the network panel is open, on any screen. Read from Panels rather
  // than set by the panel: moving it to another monitor closes one instance
  // after the other has opened, which left this false while it was showing.
  readonly property bool panelOpen: Panels.openPanel === "network"

  // WiFi
  readonly property bool wifiEnabled: backend?.wifiEnabled ?? false
  readonly property bool wifiConnected: backend?.wifiConnected ?? false
  readonly property string wifiSSID: backend?.wifiSSID ?? ""
  readonly property int wifiSignal: backend?.wifiSignal ?? 0
  readonly property string wifiSecurity: backend?.wifiSecurity ?? ""

  // Ethernet (includes USB tethering)
  readonly property bool ethernetConnected: backend?.ethernetConnected ?? false

  // Connectivity & Active Connection
  readonly property string connectivityStatus: backend?.connectivityStatus ?? "unknown"
  readonly property string activeInterface: backend?.activeInterface ?? ""
  readonly property string activeIP: backend?.activeIP ?? ""
  readonly property string activeGateway: backend?.activeGateway ?? ""
  readonly property string activeDNS: backend?.activeDNS ?? ""

  // === Computed Properties ===
  readonly property bool connecting: connectingTo !== ""
  readonly property bool isConnected: wifiConnected || ethernetConnected
  readonly property bool hasInternet: connectivityStatus === "full"

  // For a while after Wi-Fi comes on, until something connects.
  // NetworkManager scans every channel before it autoconnects, which takes 3-6
  // seconds, and "Disconnected" made that look like nothing was happening.
  readonly property bool searching: _searchArmed && wifiEnabled && !isConnected

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
      return searching ? "Searching..." : "Disconnected";
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
    backend?.refreshAll();
  }

  function setWifiEnabled(enabled) {
    backend?.setWifiEnabled(enabled);
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
    backend?.scan(force);
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
    backend?.connect(ssid, password);
  }

  /**
  * Dismiss a pending password prompt without connecting.
  */
  function cancelPasswordPrompt() {
    backend?.cancelPasswordPrompt();
  }

  /**
  * Disconnect Wi-Fi, and stay disconnected until the next manual connect.
  *
  * @param ssid - Network being disconnected, for the row's busy state
  */
  function disconnect(ssid) {
    backend?.disconnect(ssid);
  }

  /**
  * Delete every saved Wi-Fi profile for a network.
  */
  function forget(ssid) {
    backend?.forget(ssid);
  }

  // === Searching ===
  property bool _searchArmed: false

  onWifiEnabledChanged: {
    _searchArmed = wifiEnabled && !isConnected;
    if (_searchArmed)
      _searchTimer.restart();
    else
      _searchTimer.stop();
  }

  onIsConnectedChanged: {
    if (isConnected) {
      _searchArmed = false;
      _searchTimer.stop();
    }
  }

  // Long enough for a slow scan; past it, nothing known is in range.
  Timer {
    id: _searchTimer
    interval: 20000
    onTriggered: root._searchArmed = false
  }

  // === Backends ===
  LazyLoader {
    id: nmcliBackend
    active: root.backendName === "nmcli"

    component: Backends.NmcliBackend {
      panelOpen: root.panelOpen
    }
  }

  LazyLoader {
    id: nativeBackend
    active: root.backendName === "native"

    component: Backends.NativeBackend {
      panelOpen: root.panelOpen
    }
  }
}
