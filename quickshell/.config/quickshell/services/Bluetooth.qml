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
    return devices.values.filter(d => d && !d.paired && !d.trusted && !d.blocked);
  }

  readonly property var devicesWithBattery: {
    if (!devices)
      return [];
    return devices.values.filter(d => d?.batteryAvailable && d.battery > 0);
  }

  // === Computed Properties ===
  readonly property int connectedCount: connectedDevices.length
  readonly property bool hasConnectedDevices: connectedCount > 0

  readonly property bool connecting: {
    if (!devices)
      return false;
    return devices.values.some(d => d?.state === BluetoothDeviceState.Connecting || d?.pairing);
  }

  readonly property string firstConnectedName: {
    const dev = connectedDevices[0];
    return dev?.name || dev?.deviceName || "";
  }

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

  function connectDevice(device) {
    if (!device)
      return;
    Core.Logger.i("Bluetooth", `Connecting: ${device.name || device.address}`);
    device.trusted = true;
    device.connect();
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

  // Auto-start discovery when enabled
  Timer {
    id: _autoDiscoveryTimer
    interval: 1000
    running: false
    onTriggered: root.startDiscovery()
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
