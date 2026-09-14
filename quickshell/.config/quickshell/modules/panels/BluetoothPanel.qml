pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

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

  // The service gates discovery on this. Uses the opened/closed signals rather
  // than onIsOpenChanged, which SlidingPanel already declares - a second
  // declaration on the same object would override the base one.
  onOpened: Services.Bluetooth.panelOpen = true
  onClosed: Services.Bluetooth.panelOpen = false

  // === Pinned: the toggle, adapter details and the list's heading ===
  // The device list below scrolls under these with the panel's own scrollbar.
  pinned: [
    // Bluetooth Toggle
    Components.FormRow {
      Layout.fillWidth: true
      label: "Bluetooth"
      hasToggle: true
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

    // Rows are keyed by address rather than driven straight off `devices`.
    // The service rebuilds these filtered arrays on every discovery update, and
    // a Repeater on a plain array rebuilds every delegate when it does - ~32
    // full rebuilds a second while scanning
    readonly property var addresses: (section.devices ?? []).map(d => d?.address ?? "").filter(a => a !== "")

    ListModel {
      id: deviceRows
    }

    onAddressesChanged: Core.Utils.syncKeyedModel(deviceRows, section.addresses, "devAddress")
    Component.onCompleted: Core.Utils.syncKeyedModel(deviceRows, section.addresses, "devAddress")

    spacing: Core.Style.spaceXS

    Components.Text {
      text: section.title
      size: Core.Style.fontS
      color: Core.Theme.textDim
      weight: Core.Style.weightMedium
    }

    Repeater {
      model: deviceRows
      delegate: DeviceItem {
        required property string devAddress

        width: section.width
        device: Services.Bluetooth.deviceByAddress(devAddress)
      }
    }
  }

  // --- Device Item ---
  component DeviceItem: Components.Card {
    id: devItem

    property var device: null

    readonly property string deviceName: Services.Bluetooth.deviceLabel(device)
    readonly property string deviceIcon: Services.Bluetooth.getDeviceIcon(device)
    readonly property bool isConnected: device?.connected ?? false
    readonly property bool isPaired: device?.paired ?? device?.trusted ?? false
    readonly property string statusText: Services.Bluetooth.getDeviceStatus(device)
    readonly property string batteryText: Services.Bluetooth.getDeviceBatteryText(device)
    readonly property bool isBusy: Services.Bluetooth.isDeviceBusy(device)

    // Show actions for connected/paired devices always, or on hover for available
    readonly property bool showActions: (isConnected || isPaired || hovered) && !isBusy

    implicitHeight: Core.Style.controlHeightL
    interactive: !isBusy

    // Pairs, connects or disconnects as appropriate. Tapping an unpaired device
    // used to connect and silently trust it.
    onClicked: Services.Bluetooth.activate(devItem.device)

    RowLayout {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Core.Style.spaceM
      anchors.rightMargin: Core.Style.spaceS
      spacing: Core.Style.spaceM

      // Device Icon
      Components.Icon {
        icon: devItem.deviceIcon
        size: Core.Style.fontL
        color: devItem.isConnected ? Core.Theme.accentAlt : Core.Theme.text
      }

      // Device Info
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Components.Text {
          text: devItem.deviceName
          color: devItem.isConnected ? Core.Theme.accentAlt : Core.Theme.text
          weight: devItem.isConnected ? Core.Style.weightBold : Core.Style.weightNormal
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        RowLayout {
          spacing: Core.Style.spaceXS

          Components.Text {
            text: devItem.device?.address ?? ""
            size: Core.Style.fontXS
            color: Core.Theme.textMuted
            font.family: Core.Style.fontMono
          }

          // Status text
          Components.Text {
            visible: devItem.statusText !== "" && devItem.statusText !== "Connected" && devItem.statusText !== "Paired"
            text: devItem.statusText
            size: Core.Style.fontS
            color: Core.Theme.textDim
          }

          // Battery info
          RowLayout {
            visible: devItem.batteryText !== ""
            spacing: Core.Style.spaceXS

            Components.Icon {
              icon: "battery"
              size: Core.Style.fontS
              color: Core.Theme.textDim
            }

            Components.Text {
              text: devItem.batteryText
              size: Core.Style.fontS
              color: Core.Theme.textDim
            }
          }

          // Tap to connect hint (for paired but not connected)
          Components.Text {
            visible: devItem.isPaired && !devItem.isConnected && !devItem.batteryText && !devItem.isBusy
            text: "Tap to connect"
            size: Core.Style.fontS
            color: Core.Theme.textMuted
          }
        }
      }

      // Loading Spinner
      Components.Icon {
        visible: devItem.isBusy
        icon: "loading"
        spinning: true
        size: Core.Style.fontM
        color: Core.Theme.accentAlt
      }

      // Action Buttons
      RowLayout {
        spacing: Core.Style.spaceXS
        visible: devItem.showActions

        // Disconnect button (for connected devices)
        Components.Button {
          visible: devItem.isConnected
          icon: "close"
          iconSize: Core.Style.fontM
          tooltipText: "Disconnect"
          variant: "danger"
          onClicked: Services.Bluetooth.disconnectDevice(devItem.device)
        }

        // Forget button (for paired devices)
        Components.Button {
          visible: devItem.isPaired
          icon: "trash"
          iconSize: Core.Style.fontM
          tooltipText: "Forget device"
          variant: "danger"
          onClicked: Services.Bluetooth.forgetDevice(devItem.device)
        }
      }

      // Arrow indicator (shows on hover for available devices)
      Components.Icon {
        visible: !devItem.isConnected && !devItem.isPaired && !devItem.isBusy && devItem.hovered
        icon: "chevron-right"
        size: Core.Style.fontM
        color: Core.Theme.textDim
      }
    }
  }
}
