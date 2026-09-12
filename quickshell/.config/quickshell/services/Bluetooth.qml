pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

import "../core" as Core

/**
* Bluetooth - Service for managing Bluetooth connections and devices
*
* Provides:
* - Bluetooth adapter state management
* - Device discovery and pairing
* - Device categorization and icons
*/
Singleton {
  id: root

  // Set by BluetoothPanel while it is visible. Discovery keeps the radio busy
  // and costs power, so it only runs while something is displaying the results.
  property bool panelOpen: false

  // === Adapter State ===
  readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
  readonly property bool available: adapter !== null
  readonly property bool enabled: adapter?.enabled ?? false
  readonly property bool blocked: adapter?.state === BluetoothAdapterState.Blocked
  readonly property bool discovering: adapter?.discovering ?? false

  // === Device Collections ===
  readonly property var devices: adapter?.devices ?? null

  readonly property var connectedDevices: {
    if (!devices)
      return [];
    return devices.values.filter(d => d?.connected);
  }

  readonly property var pairedDevices: {
    if (!devices)
      return [];
    return devices.values.filter(d => d && (d.paired || d.trusted) && !d.connected);
  }

  readonly property var availableDevices: {
    if (!devices)
      return [];
    // Named devices first. The rest are anonymous BLE beacons - phones and
    // watches advertising on rotating random addresses - and burying the device
    // you are looking for under a dozen of them made the list unusable.
    //
    // Each device's sort key is worked out once, up front, not inside the
    // comparator. A comparator runs O(n log n) times and this binding re-runs on
    // every RSSI update while scanning, so deriving the label per comparison
    // repeated the name lookup - and for an unnamed beacon a chain of regex
    // tests - many times per device, per update.
    const candidates = devices.values.filter(d => d && !d.paired && !d.trusted && !d.blocked);
    const keyed = candidates.map(d => ({
          device: d,
          named: root.isNamed(d),
          label: root.deviceLabel(d)
        }));

    keyed.sort((a, b) => {
      if (a.named !== b.named)
        return a.named ? -1 : 1;
      return a.label.localeCompare(b.label);
    });

    return keyed.map(entry => entry.device);
  }

  readonly property var devicesWithBattery: {
    if (!devices)
      return [];
    return devices.values.filter(d => d?.batteryAvailable && d.battery > 0);
  }

  /**
  * The live device object for an address, or null.
  *
  * The panel lists devices by address rather than by object, so its rows survive
  * the service rebuilding these filtered arrays on every discovery update. This
  * is how a row gets back to the thing it is showing.
  */
  function deviceByAddress(address) {
    if (!devices || address === "")
      return null;
    for (const d of devices.values) {
      if (d?.address === address)
        return d;
    }
    return null;
  }

  // === Computed Properties ===
  readonly property int connectedCount: connectedDevices.length
  readonly property bool hasConnectedDevices: connectedCount > 0

  readonly property bool connecting: {
    if (!devices)
      return false;
    return devices.values.some(d => d?.state === BluetoothDeviceState.Connecting || d?.pairing);
  }

  readonly property string firstConnectedName: connectedDevices.length > 0 ? root.deviceLabel(connectedDevices[0]) : ""

  readonly property string statusIcon: {
    if (!available || blocked || !enabled)
      return "bluetooth-off";
    if (discovering)
      return "bluetooth-searching";
    if (hasConnectedDevices)
      return "bluetooth-connected";
    return "bluetooth";
  }

  readonly property string statusText: {
    if (!available)
      return "No adapter";
    if (blocked)
      return "Blocked";
    if (!enabled)
      return "Off";
    if (connectedCount === 1)
      return firstConnectedName || "Connected";
    if (connectedCount > 1)
      return `${connectedCount} devices`;
    return "On";
  }

  // === Public API ===

  function setEnabled(state) {
    if (!adapter)
      return;
    Core.Logger.i("Bluetooth", `${state ? "Enabling" : "Disabling"} Bluetooth`);
    adapter.enabled = state;
  }

  function toggle() {
    setEnabled(!enabled);
  }

  function startDiscovery() {
    if (!adapter || !enabled)
      return;
    Core.Logger.d("Bluetooth", "Starting discovery");
    adapter.discovering = true;
    _discoveryTimer.restart();
  }

  function stopDiscovery() {
    if (!adapter)
      return;
    Core.Logger.d("Bluetooth", "Stopping discovery");
    adapter.discovering = false;
    _discoveryTimer.stop();
  }

  /**
  * Connect to a device that is already paired.
  *
  * Marking it trusted lets it reconnect on its own later, which is only
  * appropriate once it is paired. Use activate() for user taps.
  */
  function connectDevice(device) {
    if (!device)
      return;
    Core.Logger.i("Bluetooth", `Connecting: ${device.name || device.address}`);
    device.trusted = true;
    device.connect();
  }

  /**
  * Act on a device the user tapped.
  *
  * An unpaired device has to be paired first. Connecting straight to one marked
  * it trusted as a side effect, silently granting auto-reconnect to whatever
  * happened to be in range.
  */
  function activate(device) {
    if (!device || isDeviceBusy(device))
      return;

    if (device.connected) {
      disconnectDevice(device);
    } else if (device.paired || device.trusted) {
      connectDevice(device);
    } else {
      pairDevice(device);
    }
  }

  function disconnectDevice(device) {
    if (!device)
      return;
    Core.Logger.i("Bluetooth", `Disconnecting: ${device.name || device.address}`);
    device.disconnect();
  }

  function pairDevice(device) {
    if (!device)
      return;
    Core.Logger.i("Bluetooth", `Pairing: ${device.name || device.address}`);
    device.pair();
  }

  function forgetDevice(device) {
    if (!device)
      return;
    Core.Logger.i("Bluetooth", `Forgetting: ${device.name || device.address}`);
    device.trusted = false;
    device.forget();
  }

  // === Device Helpers ===

  // A device that publishes no name reaches us as its own address with dashes
  // ("24-42-E3-20-81-F1"): BlueZ's Alias falls back to that, and the panel used
  // to list it verbatim.
  readonly property var _addressLike: /^([0-9a-f]{2}[-:]){5}[0-9a-f]{2}$/i

  /**
  * The name a device actually published, or "" if it published none.
  *
  * deviceName is BlueZ's Name; name is its Alias, which the user may have
  * renamed - so the alias wins when it is a real name rather than the address.
  */
  function _publishedName(device) {
    if (!device)
      return "";

    for (const candidate of [device.name, device.deviceName]) {
      const text = (candidate ?? "").trim();
      if (text !== "" && !root._addressLike.test(text))
        return text;
    }

    return "";
  }

  /**
  * Whether this device told us what it is called.
  */
  function isNamed(device) {
    return root._publishedName(device) !== "";
  }

  /**
  * A human-readable label: the published name, else what kind of device it is
  * plus the tail of its address ("Headphones - 40:5B"), which at least says what
  * it is and tells two of them apart.
  */
  function deviceLabel(device) {
    if (!device)
      return "Unknown device";

    const published = root._publishedName(device);
    if (published !== "")
      return published;

    return root._deviceKind(device);
  }

  // BlueZ leaves Icon empty for a device that never identified itself, which is
  // exactly the case this is for - so "Unknown device" is the common answer.
  function _deviceKind(device) {
    const icon = (device?.icon ?? "").toLowerCase();

    if (/headset|headphone/.test(icon))
      return "Headphones";
    if (/audio|speaker/.test(icon))
      return "Speaker";
    if (icon.includes("mouse"))
      return "Mouse";
    if (icon.includes("keyboard"))
      return "Keyboard";
    if (/gamepad|joystick/.test(icon))
      return "Controller";
    if (icon.includes("phone"))
      return "Phone";
    if (/computer|laptop/.test(icon))
      return "Computer";
    if (icon.includes("watch"))
      return "Watch";
    if (/display|video|tv/.test(icon))
      return "Display";
    if (icon.includes("printer"))
      return "Printer";
    if (icon.includes("input"))
      return "Input device";

    return "Unknown device";
  }

  function getDeviceIcon(device) {
    if (!device)
      return "bluetooth";

    const name = (device.name || "").toLowerCase();
    const icon = (device.icon || "").toLowerCase();

    // Audio
    if (/headset|audio|headphone|speaker/.test(icon) || /headphone|airpod|buds|earbuds|speaker/.test(name)) {
      return icon.includes("speaker") || name.includes("speaker") ? "speaker" : "headphones";
    }

    // Input
    if (/mouse|pointing/.test(icon) || name.includes("mouse"))
      return "mouse";
    if (icon.includes("keyboard") || name.includes("keyboard"))
      return "keyboard";
    if (/gamepad|joystick/.test(icon) || name.includes("controller"))
      return "gamepad";

    // Devices
    if (/phone/.test(icon) || /phone|iphone|android|samsung|pixel/.test(name))
      return "phone";
    if (/computer|laptop/.test(icon) || /macbook|laptop|pc/.test(name))
      return "laptop";
    if (icon.includes("watch") || name.includes("watch"))
      return "clock";
    if (/display|video/.test(icon) || name.includes("tv"))
      return "monitor";

    return "bluetooth";
  }

  function isDeviceBusy(device) {
    if (!device)
      return false;
    return device.pairing || device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting;
  }

  function getDeviceStatus(device) {
    if (!device)
      return "";
    if (device.state === BluetoothDeviceState.Connecting)
      return "Connecting...";
    if (device.state === BluetoothDeviceState.Disconnecting)
      return "Disconnecting...";
    if (device.pairing)
      return "Pairing...";
    if (device.blocked)
      return "Blocked";
    if (device.connected)
      return "Connected";
    if (device.paired || device.trusted)
      return "Paired";
    return "";
  }

  function getDeviceBattery(device) {
    if (!device?.batteryAvailable || device.battery <= 0)
      return -1;
    return Math.round(device.battery * 100);
  }

  function getDeviceBatteryText(device) {
    const battery = getDeviceBattery(device);
    return battery < 0 ? "" : battery + "%";
  }

  // === Initialization ===
  Component.onCompleted: {
    Core.Logger.i("Bluetooth", "Service started");
    if (available) {
      Core.Logger.d("Bluetooth", `Adapter: ${adapter.name || "default"}, enabled: ${enabled}`);
    }
  }

  // === Timers ===

  // Auto-stop discovery after 30 seconds
  Timer {
    id: _discoveryTimer
    interval: 30000
    onTriggered: root.stopDiscovery()
  }

  // Auto-start discovery shortly after the adapter comes up, but only if the
  // panel is open. Enabling Bluetooth used to kick off a 30s scan whether or
  // not anything was going to show the results.
  Timer {
    id: _autoDiscoveryTimer
    interval: 1000
    running: false
    onTriggered: {
      if (root.panelOpen)
        root.startDiscovery();
    }
  }

  onPanelOpenChanged: {
    if (panelOpen)
      startDiscovery();
    else
      stopDiscovery();
  }

  // === State Changes ===
  Connections {
    target: root.adapter
    function onStateChanged() {
      if (!root.adapter)
        return;
      Core.Logger.d("Bluetooth", `State: ${root.adapter.state}`);

      if (root.adapter.state === BluetoothAdapterState.Enabled) {
        _autoDiscoveryTimer.restart();
      }
    }
  }
}
