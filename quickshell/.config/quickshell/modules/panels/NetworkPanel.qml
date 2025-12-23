import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core
import "../../layouts" as Layouts
import "../../services" as Services

/**
* NetworkPanel - Sliding panel for WiFi and Ethernet management
*/
Layouts.SlidingPanel {
  id: root

  namespace: "quickshell-network-panel"

  onOpened: Services.Network.scan()

  // Header
  Layouts.PanelHeader {
    Layout.fillWidth: true
    icon: Services.Network.connectionIcon
    iconColor: Services.Network.isConnected ? Config.Theme.accent : Config.Theme.textMuted
    title: "Network"
    subtitle: Services.Network.connectionStatusText
    onCloseClicked: root.close()
  }

  Components.Divider {}

  // WiFi Toggle
  Layouts.FormRow {
    label: "Wi-Fi"
    hasToggle: true
    toggleChecked: Services.Network.wifiEnabled
    onToggled: checked => Services.Network.setWifiEnabled(checked)
  }

  // Error Message
  Layouts.ErrorBanner {
    Layout.fillWidth: true
    visible: Services.Network.lastError !== ""
    message: Services.Network.lastError
  }

  // Connection Info (collapsible)
  ConnectionInfoSection {
    Layout.fillWidth: true
    visible: Services.Network.isConnected
  }

  // WiFi Content (networks list or disabled state)
  Item {
    Layout.fillWidth: true
    Layout.fillHeight: true

    // Networks List (when WiFi enabled)
    ColumnLayout {
      anchors.fill: parent
      spacing: Core.Style.spaceS
      visible: Services.Network.wifiEnabled

      // Header with scan button
      RowLayout {
        Layout.fillWidth: true
        spacing: Core.Style.spaceS

        Components.Label {
          text: "Available Networks"
          font.weight: Core.Style.weightBold
          Layout.fillWidth: true
        }

        Components.Label {
          text: Services.Network.scanning ? "Scanning..." : `${Object.keys(Services.Network.networks).length} networks`
          color: Config.Theme.textDim
          size: Core.Style.fontS
        }

        ScanButton {}
      }

      // Network List
      Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: networkList.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
          id: networkList
          width: parent.width
          spacing: Core.Style.spaceXS

          Repeater {
            model: Services.Network.sortedNetworks
            delegate: NetworkItem {
              Layout.fillWidth: true
              network: modelData
              onConnectRequested: ssid => Services.Network.connect(ssid)
            }
          }

          // Empty state
          Layouts.EmptyState {
            Layout.fillWidth: true
            visible: Object.keys(Services.Network.networks).length === 0 && !Services.Network.scanning
            icon: "wifi-off"
            message: "No networks found"
          }
        }
      }
    }

    // WiFi Disabled State
    Layouts.EmptyState {
      anchors.centerIn: parent
      visible: !Services.Network.wifiEnabled
      icon: "wifi-off"
      iconSize: Core.Style.fontXXL * 2
      message: "Wi-Fi is disabled"
      hint: "Enable Wi-Fi to see available networks"
    }
  }

  // ==========================================================================
  // INLINE COMPONENTS
  // ==========================================================================

  // --- Connection Info Section ---
  component ConnectionInfoSection: Layouts.Collapsible {
    id: connInfoRoot
    title: "📊 Connection Info"
    expanded: false

    readonly property var infoRows: [
      {
        label: "Type",
        value: Services.Network.connectionTypeName
      },
      {
        label: "Interface",
        value: Services.Network.activeInterface || "--"
      },
      {
        label: "IP Address",
        value: Services.Network.activeIP ? Services.Network.activeIP.split("/")[0] : "--"
      },
      {
        label: "Gateway",
        value: Services.Network.activeGateway || "--"
      },
      {
        label: "DNS",
        value: Services.Network.activeDNS || "--"
      },
      {
        label: "Internet",
        value: Services.Network.connectivityStatusText
      },
    ]

    readonly property var wifiRows: [
      {
        label: "Signal",
        value: Services.Network.wifiSignal + "%"
      },
      {
        label: "Security",
        value: Services.Network.wifiSecurity || "--"
      },
    ]

    Repeater {
      model: connInfoRoot.infoRows
      Layouts.FormRow {
        required property var modelData
        label: modelData.label
        valueText: modelData.value
      }
    }

    Repeater {
      model: Services.Network.wifiConnected ? connInfoRoot.wifiRows : []
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
    iconSpinning: Services.Network.scanning
    enabled: !Services.Network.scanning
    opacity: Services.Network.scanning ? 0.5 : 1.0
    tooltipText: "Scan for networks"
    onClicked: Services.Network.scan()
  }

  // --- Network Item ---
  component NetworkItem: Rectangle {
    id: netItem

    property var network: ({})
    signal connectRequested(string ssid)

    // Destructure network properties
    readonly property string ssid: network.ssid ?? ""
    readonly property int signalStrength: network.signal ?? 0
    readonly property bool secured: network.secured ?? false
    readonly property bool connected: network.connected ?? false
    readonly property string security: network.security ?? ""

    // Busy states
    readonly property bool isConnecting: Services.Network.connectingTo === ssid
    readonly property bool isDisconnecting: Services.Network.disconnectingFrom === ssid
    readonly property bool isForgetting: Services.Network.forgettingNetwork === ssid
    readonly property bool isBusy: isConnecting || isDisconnecting || isForgetting

    height: Core.Style.widgetSize + Core.Style.spaceL + Core.Style.spaceS
    radius: Core.Style.radiusS
    color: hoverArea.containsMouse ? Config.Theme.surface : Config.Theme.transparent

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Core.Style.spaceM
      anchors.rightMargin: Core.Style.spaceS
      spacing: Core.Style.spaceM

      // Signal icon
      Components.Icon {
        name: Services.Network.getSignalIcon(netItem.signalStrength)
        size: Core.Style.fontL
        color: netItem.connected ? Config.Theme.accent : Config.Theme.text
      }

      // Network info
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        RowLayout {
          spacing: Core.Style.spaceXS

          Components.Label {
            text: netItem.ssid
            color: netItem.connected ? Config.Theme.accent : Config.Theme.text
            font.weight: netItem.connected ? Core.Style.weightBold : Core.Style.weightNormal
            Layout.fillWidth: true
          }

          // Connected badge
          Components.Badge {
            visible: netItem.connected
            text: "Connected"
          }
        }

        RowLayout {
          spacing: Core.Style.spaceXS

          Components.Label {
            text: netItem.signalStrength + "%"
            size: Core.Style.fontS
            color: Config.Theme.textDim
          }

          Components.Label {
            visible: netItem.secured
            text: "🔒"
            size: Core.Style.fontS
          }

          Components.Label {
            visible: netItem.security && netItem.security !== "--"
            text: netItem.security
            size: Core.Style.fontXS
            color: Config.Theme.textMuted
          }
        }
      }

      RowLayout {
        spacing: Core.Style.spaceXS
        visible: netItem.isBusy

        // Loading spinner
        Components.Icon {
          name: "loading"
          size: Core.Style.fontM
          color: Config.Theme.accent
          spinning: netItem.isBusy
        }
      }

      // Action buttons
      RowLayout {
        spacing: Core.Style.spaceXS
        visible: hoverArea.containsMouse || netItem.connected

        // Connect/Disconnect button
        Components.Button {
          visible: !netItem.isBusy
          icon: netItem.connected ? "close" : "chevron-right"
          iconSize: Core.Style.fontM
          tooltipText: netItem.connected ? "Disconnect" : "Connect"
          useActiveColorOnHover: netItem.connected
          onClicked: {
            if (netItem.connected) {
              Services.Network.disconnect(netItem.ssid);
            } else {
              netItem.connectRequested(netItem.ssid);
            }
          }
        }

        // Forget button
        Components.Button {
          visible: netItem.connected && !netItem.isBusy
          icon: "trash"
          iconSize: Core.Style.fontM
          tooltipText: "Forget network"
          useActiveColorOnHover: true
          onClicked: Services.Network.forget(netItem.ssid)
        }
      }
    }

    MouseArea {
      id: hoverArea
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton
      z: -1

      onClicked: {
        if (!netItem.connected && !netItem.isBusy) {
          netItem.connectRequested(netItem.ssid);
        }
      }
    }
  }
}
