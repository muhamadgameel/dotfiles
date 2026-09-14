pragma Singleton

import QtQuick
import Quickshell

import "network" as Backends

/**
* Network - Wi-Fi and Ethernet state and actions for the UI
*
* The backend in services/network does the work and exposes raw state. What
* the UI derives from that state - icons, labels, sorting - lives here.
*/
Singleton {
  id: root

  // === State (from the backend) ===
  readonly property var networks: backend.networks
  readonly property bool scanning: backend.scanning
  readonly property string connectingTo: backend.connectingTo
  readonly property string disconnectingFrom: backend.disconnectingFrom
  readonly property string forgettingNetwork: backend.forgettingNetwork
  readonly property string lastError: backend.lastError

  // SSID that NetworkManager reported it has no key for, and which is now
  // waiting on a password. Empty when no prompt is pending.
  readonly property string passwordRequiredFor: backend.passwordRequiredFor

  // Set by NetworkPanel while it is visible.
  property bool panelOpen: false

  // WiFi
  readonly property bool wifiEnabled: backend.wifiEnabled
  readonly property bool wifiConnected: backend.wifiConnected
  readonly property string wifiSSID: backend.wifiSSID
  readonly property int wifiSignal: backend.wifiSignal
  readonly property string wifiSecurity: backend.wifiSecurity

  // Ethernet (includes USB tethering)
  readonly property bool ethernetConnected: backend.ethernetConnected
  readonly property string ethernetInterface: backend.ethernetInterface

  // Connectivity & Active Connection
  readonly property string connectivityStatus: backend.connectivityStatus
  readonly property string activeInterface: backend.activeInterface
  readonly property string activeIP: backend.activeIP
  readonly property string activeGateway: backend.activeGateway
  readonly property string activeDNS: backend.activeDNS

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
    backend.refreshAll();
  }

  function setWifiEnabled(enabled) {
    backend.setWifiEnabled(enabled);
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
    backend.scan(force);
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
    backend.connect(ssid, password);
  }

  /**
  * Dismiss a pending password prompt without connecting.
  */
  function cancelPasswordPrompt() {
    backend.cancelPasswordPrompt();
  }

  /**
  * Disconnect Wi-Fi, and stay disconnected until the next manual connect.
  *
  * @param ssid - Network being disconnected, for the row's busy state
  */
  function disconnect(ssid) {
    backend.disconnect(ssid);
  }

  /**
  * Delete every saved Wi-Fi profile for a network.
  */
  function forget(ssid) {
    backend.forget(ssid);
  }

  // === Backend ===
  Backends.NmcliBackend {
    id: backend

    panelOpen: root.panelOpen
  }
}
