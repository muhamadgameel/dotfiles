import QtQuick
import QtQuick.Layouts

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core
import "../../layouts" as Layouts
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
Layouts.SlidingPanel {
  id: root

  namespace: "quickshell-bluetooth-panel"
  scrollable: false

  headerIcon: Services.Bluetooth.statusIcon
  headerIconColor: Services.Bluetooth.enabled ? Config.Theme.accentAlt : Config.Theme.textMuted
  headerTitle: "Bluetooth"
  headerSubtitle: Services.Bluetooth.statusText

  onOpened: Services.Bluetooth.startDiscovery()
  onClosed: Services.Bluetooth.stopDiscovery()

  Item {
    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
      anchors.fill: parent
      spacing: Core.Style.spaceM

      // Bluetooth Toggle
      Layouts.FormRow {
        Layout.fillWidth: true
        label: "Bluetooth"
        hasToggle: true
        toggleChecked: Services.Bluetooth.enabled
        onToggled: checked => Services.Bluetooth.setEnabled(checked)
      }

      // Adapter Info (collapsible)
      AdapterInfoSection {
        Layout.fillWidth: true
        visible: Services.Bluetooth.available && Services.Bluetooth.enabled
      }

      // Main Content Area
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        // Devices List (when enabled)
        ColumnLayout {
          anchors.fill: parent
          spacing: Core.Style.spaceS
          visible: Services.Bluetooth.enabled

          // Header with scan button
          RowLayout {
            Layout.fillWidth: true
            spacing: Core.Style.spaceS

            Components.Text {
              text: "Devices"
              weight: Core.Style.weightBold
              Layout.fillWidth: true
            }

            Components.Text {
              visible: Services.Bluetooth.discovering
              text: "Scanning..."
              color: Config.Theme.textDim
              size: Core.Style.fontS
            }

            ScanButton {}
          }

          // Device List
          Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: deviceList.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
              id: deviceList
              width: parent.width
              spacing: Core.Style.spaceXS

              // Connected Devices
              DeviceSection {
                Layout.fillWidth: true
                title: "Connected"
                devices: Services.Bluetooth.connectedDevices
                visible: Services.Bluetooth.connectedDevices.length > 0
              }

              // Paired Devices
              DeviceSection {
                Layout.fillWidth: true
                title: "Paired"
                devices: Services.Bluetooth.pairedDevices
                visible: Services.Bluetooth.pairedDevices.length > 0
              }

              // Available Devices
              DeviceSection {
                Layout.fillWidth: true
                title: "Available"
                devices: Services.Bluetooth.availableDevices
                visible: Services.Bluetooth.availableDevices.length > 0
              }

              // Bottom spacer
              Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Core.Style.spaceXL
              }
            }
          }

          // Empty States (shown when no devices)
          Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: _totalDevices === 0
            visible: active

            readonly property int _totalDevices: Services.Bluetooth.connectedDevices.length + Services.Bluetooth.pairedDevices.length + Services.Bluetooth.availableDevices.length

            sourceComponent: Layouts.EmptyState {
              anchors.centerIn: parent
              icon: Services.Bluetooth.discovering ? "refresh" : "bluetooth"
              message: Services.Bluetooth.discovering ? "Scanning for devices..." : "No devices found"
              hint: Services.Bluetooth.discovering ? "Put your device in pairing mode" : "Make sure devices are in pairing mode"
            }
          }
        }

        // Bluetooth Disabled State
        Layouts.EmptyState {
          anchors.centerIn: parent
          visible: !Services.Bluetooth.enabled && Services.Bluetooth.available
          icon: "bluetooth-off"
          iconSize: Core.Style.fontXXL * 2
          message: "Bluetooth is disabled"
          hint: "Enable Bluetooth to connect devices"
        }

        // No Adapter State
        Layouts.EmptyState {
          anchors.centerIn: parent
          visible: !Services.Bluetooth.available
          icon: "bluetooth-off"
          iconSize: Core.Style.fontXXL * 2
          message: "No Bluetooth adapter"
          hint: "Check if your device has Bluetooth hardware"
        }
      }
    }
  }

  // ==========================================================================
  // INLINE COMPONENTS
  // ==========================================================================

  // --- Adapter Info Section ---
  component AdapterInfoSection: Layouts.Collapsible {
    id: adapterInfo
    title: "Adapter Info"
    icon: "info"
    expanded: false

    readonly property var infoRows: [
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

    Repeater {
      model: adapterInfo.infoRows
      Layouts.FormRow {
        required property var modelData
        label: modelData.label
        valueText: modelData.value
      }
    }
  }

  // --- Scan Button ---
  component ScanButton: Components.Button {
    icon: "refresh"
    iconSize: Core.Style.fontM
    iconSpinning: Services.Bluetooth.discovering
    enabled: Services.Bluetooth.enabled && !Services.Bluetooth.discovering
    opacity: Services.Bluetooth.discovering ? 0.5 : 1.0
    tooltipText: Services.Bluetooth.discovering ? "Scanning..." : "Scan for devices"
    onClicked: Services.Bluetooth.startDiscovery()
  }

  // --- Device Section ---
  component DeviceSection: ColumnLayout {
    id: section

    property string title: ""
    property var devices: []

    spacing: Core.Style.spaceXS

    Components.Text {
      text: section.title
      size: Core.Style.fontS
      color: Config.Theme.textDim
      weight: Core.Style.weightMedium
    }

    Repeater {
      model: section.devices
      delegate: DeviceItem {
        Layout.fillWidth: true
        device: modelData
      }
    }
  }

  // --- Device Item ---
  component DeviceItem: Components.Card {
    id: devItem

    property var device: null

    readonly property string deviceName: device?.name || device?.address || "Unknown"
    readonly property string deviceIcon: Services.Bluetooth.getDeviceIcon(device)
    readonly property bool isConnected: device?.connected ?? false
    readonly property bool isPaired: device?.paired ?? device?.trusted ?? false
    readonly property string statusText: Services.Bluetooth.getDeviceStatus(device)
    readonly property string batteryText: Services.Bluetooth.getDeviceBatteryText(device)
    readonly property bool isBusy: Services.Bluetooth.isDeviceBusy(device)

    // Show actions for connected/paired devices always, or on hover for available
    readonly property bool showActions: (isConnected || isPaired || hovered) && !isBusy

    implicitHeight: 52
    interactive: !isBusy

    onClicked: {
      if (!device)
        return;
      if (isConnected) {
        Services.Bluetooth.disconnectDevice(device);
      } else {
        Services.Bluetooth.connectDevice(device);
      }
    }

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
        color: devItem.isConnected ? Config.Theme.accentAlt : Config.Theme.text
      }

      // Device Info
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Components.Text {
          text: devItem.deviceName
          color: devItem.isConnected ? Config.Theme.accentAlt : Config.Theme.text
          weight: devItem.isConnected ? Core.Style.weightBold : Core.Style.weightNormal
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        RowLayout {
          spacing: Core.Style.spaceXS
          visible: devItem.statusText || devItem.batteryText || devItem.isPaired

          // Status text
          Components.Text {
            visible: devItem.statusText !== "" && devItem.statusText !== "Connected" && devItem.statusText !== "Paired"
            text: devItem.statusText
            size: Core.Style.fontS
            color: Config.Theme.textDim
          }

          // Battery info
          RowLayout {
            visible: devItem.batteryText !== ""
            spacing: Core.Style.spaceXS

            Components.Icon {
              icon: "battery"
              size: Core.Style.fontS
              color: Config.Theme.textDim
            }

            Components.Text {
              text: devItem.batteryText
              size: Core.Style.fontS
              color: Config.Theme.textDim
            }
          }

          // Tap to connect hint (for paired but not connected)
          Components.Text {
            visible: devItem.isPaired && !devItem.isConnected && !devItem.batteryText
            text: "Tap to connect"
            size: Core.Style.fontS
            color: Config.Theme.textMuted
          }
        }
      }

      // Loading Spinner
      Components.Spinner {
        visible: devItem.isBusy
        running: devItem.isBusy
        size: Core.Style.fontM
        color: Config.Theme.accentAlt
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
        color: Config.Theme.textDim
      }
    }
  }
}
