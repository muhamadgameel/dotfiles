pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../components" as Components
import "../../core" as Core
import "../../services" as Services

/**
* BluetoothPanel - Sliding panel for Bluetooth device management
*
* Features:
* - Bluetooth toggle
* - Adapter info section
* - Device discovery
* - Connected/paired/available device lists
* - Connect/disconnect/forget actions
*/
Components.SlidingPanel {
  id: root

  panelId: "bluetooth"
  contentSpacing: Core.Style.spaceM

  headerIcon: Services.Bluetooth.statusIcon
  headerIconColor: Services.Bluetooth.enabled ? Core.Theme.accentAlt : Core.Theme.textMuted
  headerTitle: "Bluetooth"
  headerSubtitle: Services.Bluetooth.statusText

  // === Pinned: the toggle, adapter details and the list's heading ===
  // The device list below scrolls under these with the panel's own scrollbar.
  pinned: [
    // Bluetooth Toggle
    Components.FormRow {
      label: "Bluetooth"
      toggleChecked: Services.Bluetooth.enabled
      onToggled: checked => Services.Bluetooth.setEnabled(checked)
    },

    // Adapter Info (collapsible)
    Components.InfoList {
      Layout.fillWidth: true
      visible: Services.Bluetooth.available && Services.Bluetooth.enabled
      title: "Adapter Info"
      icon: "info"

      rows: [
        {
          label: "Adapter",
          value: Services.Bluetooth.adapter?.name || "Default"
        },
        {
          label: "State",
          value: Services.Bluetooth.statusText
        },
        {
          label: "Connected",
          value: Services.Bluetooth.connectedCount.toString()
        },
      ]
    },
    Components.SectionHeader {
      title: "Devices"
      visible: Services.Bluetooth.enabled

      Components.Text {
        visible: Services.Bluetooth.discovering
        text: "Scanning..."
        color: Core.Theme.textDim
        size: Core.Style.fontS
      }

      Components.ScanButton {
        scanning: Services.Bluetooth.discovering
        tooltipText: "Scan for devices"
        onClicked: Services.Bluetooth.startDiscovery()
      }
    }
  ]

  readonly property int _totalDevices: Services.Bluetooth.connectedDevices.length + Services.Bluetooth.pairedDevices.length + Services.Bluetooth.availableDevices.length

  // === Device List ===
  // Sections slide as others appear, grow or empty out - a device that connects
  // moves from Available to Connected, and everything between glides rather
  // than jumping.
  Components.AnimatedColumn {
    id: deviceList

    Layout.fillWidth: true
    visible: Services.Bluetooth.enabled && root._totalDevices > 0
    spacing: Core.Style.spaceXS
    animated: root.revealed

    // Connected Devices
    DeviceSection {
      width: deviceList.width
      animated: root.revealed
      title: "Connected"
      devices: Services.Bluetooth.connectedDevices
      visible: Services.Bluetooth.connectedDevices.length > 0
    }

    // Paired Devices
    DeviceSection {
      width: deviceList.width
      animated: root.revealed
      title: "Paired"
      devices: Services.Bluetooth.pairedDevices
      visible: Services.Bluetooth.pairedDevices.length > 0
    }

    // Available Devices
    DeviceSection {
      width: deviceList.width
      animated: root.revealed
      title: "Available"
      devices: Services.Bluetooth.availableDevices
      visible: Services.Bluetooth.availableDevices.length > 0
    }
  }

  // No devices yet
  Components.EmptyState {
    Layout.fillWidth: true
    Layout.topMargin: Core.Style.spaceL
    visible: Services.Bluetooth.enabled && root._totalDevices === 0
    icon: Services.Bluetooth.discovering ? "refresh" : "bluetooth"
    message: Services.Bluetooth.discovering ? "Scanning for devices..." : "No devices found"
    hint: Services.Bluetooth.discovering ? "Put your device in pairing mode" : "Make sure devices are in pairing mode"
  }

  // Bluetooth Disabled State
  Components.EmptyState {
    Layout.fillWidth: true
    Layout.topMargin: Core.Style.spaceXL
    visible: !Services.Bluetooth.enabled && Services.Bluetooth.available
    icon: "bluetooth-off"
    iconSize: Core.Style.emptyIconSizeLarge
    message: "Bluetooth is disabled"
    hint: "Enable Bluetooth to connect devices"
  }

  // No Adapter State
  Components.EmptyState {
    Layout.fillWidth: true
    Layout.topMargin: Core.Style.spaceXL
    visible: !Services.Bluetooth.available
    icon: "bluetooth-off"
    iconSize: Core.Style.emptyIconSizeLarge
    message: "No Bluetooth adapter"
    hint: "Check if your device has Bluetooth hardware"
  }

  // ==========================================================================
  // INLINE COMPONENTS
  // ==========================================================================

  // --- Device Section ---
  component DeviceSection: Components.AnimatedColumn {
    id: section

    property string title: ""
    property var devices: []

    spacing: Core.Style.spaceXS

    Components.Text {
      text: section.title
      size: Core.Style.fontS
      color: Core.Theme.textDim
      weight: Core.Style.weightMedium
    }

    Repeater {
      model: ScriptModel {
        values: section.devices
      }
      delegate: DeviceItem {
        required property var modelData

        width: section.width
        device: modelData
      }
    }
  }

  // --- Device Item ---
  component DeviceItem: Components.ListRow {
    id: devItem

    property var device: null

    readonly property bool isConnected: device?.connected ?? false
    readonly property bool isPaired: device?.paired || device?.trusted || false
    readonly property string statusText: Services.Bluetooth.getDeviceStatus(device)
    readonly property string batteryText: Services.Bluetooth.getDeviceBatteryText(device)
    readonly property bool isBusy: Services.Bluetooth.isDeviceBusy(device)

    interactive: !isBusy

    icon: Services.Bluetooth.getDeviceIcon(device)
    iconSize: Core.Style.fontL
    iconColor: isConnected ? Core.Theme.accentAlt : Core.Theme.text
    title: Services.Bluetooth.deviceLabel(device)
    titleColor: isConnected ? Core.Theme.accentAlt : Core.Theme.text
    titleWeight: isConnected ? Core.Style.weightBold : Core.Style.weightNormal
    subtitle: {
      const parts = [device?.address ?? ""];
      if (statusText !== "Connected" && statusText !== "Paired")
        parts.push(statusText);
      if (batteryText !== "")
        parts.push(`Battery ${batteryText}`);
      else if (isPaired && !isConnected && !isBusy)
        parts.push("Tap to connect");
      return parts.filter(part => part !== "").join(" · ");
    }

    // Pairs, connects or disconnects as appropriate. Tapping an unpaired device
    // used to connect and silently trust it.
    onClicked: Services.Bluetooth.activate(devItem.device)

    trailing: [
      Components.Spinner {
        visible: devItem.isBusy
        size: Core.Style.fontM
        color: Core.Theme.accentAlt
      },
      Components.Button {
        visible: devItem.isConnected && !devItem.isBusy
        icon: "close"
        iconSize: Core.Style.fontM
        tooltipText: "Disconnect"
        variant: "danger"
        onClicked: Services.Bluetooth.disconnectDevice(devItem.device)
      },
      Components.Button {
        visible: devItem.isPaired && !devItem.isBusy
        icon: "trash"
        iconSize: Core.Style.fontM
        tooltipText: "Forget device"
        variant: "danger"
        onClicked: Services.Bluetooth.forgetDevice(devItem.device)
      },
      Components.Icon {
        visible: !devItem.isConnected && !devItem.isPaired && !devItem.isBusy && devItem.hovered
        icon: "chevron-right"
        size: Core.Style.fontM
        color: Core.Theme.textDim
      }
    ]
  }
}
