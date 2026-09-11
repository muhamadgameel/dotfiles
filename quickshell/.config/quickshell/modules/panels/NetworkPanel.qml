pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core
import "../../services" as Services

/**
* NetworkPanel - Sliding panel for WiFi and Ethernet management
*/
Components.SlidingPanel {
  id: root

  panelId: "network"
  namespace: "quickshell-network-panel"
  scrollable: false
  fillHeight: false
  contentSpacing: Core.Style.spaceM

  // Header configuration
  headerIcon: Services.Network.connectionIcon
  headerIconColor: Services.Network.isConnected ? Config.Theme.accent : Config.Theme.textMuted
  headerTitle: "Network"
  headerSubtitle: Services.Network.connectionStatusText

  // panelOpen gates active rescans in the service; see Network.scan().
  onOpened: {
    Services.Network.panelOpen = true;
    Services.Network.scan(true);
  }
  onClosed: Services.Network.panelOpen = false

  // WiFi Toggle
  Components.FormRow {
    Layout.fillWidth: true
    label: "Wi-Fi"
    hasToggle: true
    toggleChecked: Services.Network.wifiEnabled
    onToggled: checked => Services.Network.setWifiEnabled(checked)
  }

  // Error Message
  Components.StatusBanner {
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
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Core.Style.spaceS
    visible: Services.Network.wifiEnabled

    // Header with scan button
    RowLayout {
      Layout.fillWidth: true
      spacing: Core.Style.spaceS

      Components.Text {
        text: "Available Networks"
        weight: Core.Style.weightBold
        Layout.fillWidth: true
      }

      Components.Text {
        text: Services.Network.scanning ? "Scanning..." : `${Object.keys(Services.Network.networks).length} networks`
        color: Config.Theme.textDim
        size: Core.Style.fontS
      }

      ScanButton {}
    }

    // Network List
    Components.ScrollArea {
      id: networkScroll

      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.preferredHeight: networkList.implicitHeight
      Layout.minimumHeight: 0

      contentWidth: width
      contentHeight: networkList.implicitHeight
      leftMargin: 0
      rightMargin: 0

      ColumnLayout {
        id: networkList
        width: networkScroll.width
        spacing: Core.Style.spaceXS

        Repeater {
          model: networkRows
          delegate: NetworkItem {
            required property string netSsid

            Layout.fillWidth: true
            network: Services.Network.networks[netSsid] ?? ({})
            onConnectRequested: ssid => Services.Network.connect(ssid)
          }
        }

        Components.Spacer {
          size: 32
        }

        // Empty state
        Components.EmptyState {
          Layout.fillWidth: true
          visible: Object.keys(Services.Network.networks).length === 0 && !Services.Network.scanning
          icon: "wifi-off"
          message: "No networks found"
        }
      }
    }
  }

  Components.EmptyState {
    Layout.fillWidth: true
    Layout.topMargin: Core.Style.spaceXL
    visible: !Services.Network.wifiEnabled
    icon: "wifi-off"
    iconSize: Core.Style.fontXXL * 2
    message: "Wi-Fi is disabled"
    hint: "Enable Wi-Fi to see available networks"
  }

  // Rows are keyed by SSID rather than driven straight off sortedNetworks, which
  // is a fresh array of fresh objects on every nmcli poll. A Repeater on that
  // rebuilt every delegate each poll; keyed, a row only comes or goes with its
  // network, and a re-sort moves rows instead of recreating them.
  readonly property var networkKeys: Services.Network.sortedNetworks.map(n => n?.ssid ?? "").filter(s => s !== "")

  ListModel {
    id: networkRows
  }

  onNetworkKeysChanged: Core.Utils.syncKeyedModel(networkRows, root.networkKeys, "netSsid")
  Component.onCompleted: Core.Utils.syncKeyedModel(networkRows, root.networkKeys, "netSsid")

  // ==========================================================================
  // INLINE COMPONENTS
  // ==========================================================================

  // --- Connection Info Section ---
  component ConnectionInfoSection: Components.Collapsible {
    id: connInfoRoot
    title: "Connection Info"
    icon: "chart"
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
      Components.FormRow {
        required property var modelData
        label: modelData.label
        valueText: modelData.value
      }
    }

    Repeater {
      model: Services.Network.wifiConnected ? connInfoRoot.wifiRows : []
      Components.FormRow {
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
  component NetworkItem: Components.Card {
    id: netItem

    property var network: ({})
    signal connectRequested(string ssid)

    // Destructure network properties
    readonly property string ssid: network?.ssid ?? ""
    readonly property int signalStrength: network?.signal ?? 0
    readonly property bool secured: network?.secured ?? false
    readonly property bool connected: network?.connected ?? false
    readonly property string security: network?.security ?? ""

    // Busy states
    readonly property bool isConnecting: Services.Network.connectingTo === ssid
    readonly property bool isDisconnecting: Services.Network.disconnectingFrom === ssid
    readonly property bool isForgetting: Services.Network.forgettingNetwork === ssid
    readonly property bool isBusy: isConnecting || isDisconnecting || isForgetting

    // This is the network NetworkManager asked for a key for.
    readonly property bool needsPassword: ssid !== "" && Services.Network.passwordRequiredFor === ssid

    readonly property int rowHeight: Core.Style.widgetSize + Core.Style.spaceL + Core.Style.spaceS

    implicitHeight: itemColumn.implicitHeight
    interactive: !needsPassword

    onClicked: {
      if (!connected && !isBusy) {
        connectRequested(ssid);
      }
    }

    ColumnLayout {
      id: itemColumn

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      spacing: 0

      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: netItem.rowHeight
        Layout.leftMargin: Core.Style.spaceM
        Layout.rightMargin: Core.Style.spaceS
        spacing: Core.Style.spaceM

        // Signal icon
        Components.Icon {
          icon: Services.Network.getSignalIcon(netItem.signalStrength)
          size: Core.Style.fontL
          color: netItem.connected ? Config.Theme.accent : Config.Theme.text
        }

        // Network info
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 0

          RowLayout {
            Layout.fillWidth: true
            spacing: Core.Style.spaceXS

            Components.Text {
              text: netItem.ssid
              color: netItem.connected ? Config.Theme.accent : Config.Theme.text
              weight: netItem.connected ? Core.Style.weightBold : Core.Style.weightNormal
              Layout.fillWidth: true
            }

            // Connected badge
            Components.Badge {
              visible: netItem.connected
              text: "Connected"
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Core.Style.spaceXS

            Components.Text {
              text: netItem.signalStrength + "%"
              size: Core.Style.fontS
              color: Config.Theme.textDim
            }

            Components.Icon {
              visible: netItem.secured
              icon: "lock"
              size: Core.Style.fontS
              color: Config.Theme.textDim
            }

            Components.Text {
              Layout.fillWidth: true
              visible: netItem.security && netItem.security !== "--"
              text: netItem.security
              size: Core.Style.fontXS
              color: Config.Theme.textMuted
            }
          }
        }

        // Loading spinner
        Components.Spinner {
          running: netItem.isBusy
          size: Core.Style.fontM
          color: Config.Theme.accent
        }

        // Action buttons
        RowLayout {
          spacing: Core.Style.spaceXS
          visible: !netItem.isBusy && (netItem.connected || netItem.hovered)

          // Disconnect button
          Components.Button {
            visible: netItem.connected
            icon: "close"
            iconSize: Core.Style.fontM
            variant: "danger"
            tooltipText: "Disconnect"
            onClicked: Services.Network.disconnect(netItem.ssid)
          }

          // Forget button. Offered on hover for any network, not only the
          // connected one - it sat inside a row that was itself visible only
          // when connected, so a saved network could never be removed.
          Components.Button {
            icon: "trash"
            iconSize: Core.Style.fontM
            variant: "danger"
            tooltipText: "Forget network"
            onClicked: Services.Network.forget(netItem.ssid)
          }
        }

        // Arrow indicator (shows on hover for available networks)
        Components.Icon {
          visible: netItem.hovered && !netItem.connected && !netItem.isBusy
          icon: "chevron-right"
          size: Core.Style.fontM
          color: Config.Theme.textDim
        }
      }

      // Inline password prompt.
      //
      // Only appears once NetworkManager has said it has no key for this
      // network, so open and already-saved networks still join on one click.
      // Previously that failure surfaced as a raw "Secrets were required"
      // string with no way to supply one.
      ColumnLayout {
        id: passwordPrompt

        Layout.fillWidth: true
        Layout.leftMargin: Core.Style.spaceM
        Layout.rightMargin: Core.Style.spaceM
        Layout.bottomMargin: Core.Style.spaceM
        spacing: Core.Style.spaceXS

        visible: netItem.needsPassword

        function submit() {
          if (passwordField.text.length === 0)
            return;
          Services.Network.connect(netItem.ssid, passwordField.text);
          passwordField.clear();
        }

        onVisibleChanged: {
          passwordField.clear();
          showPassword.revealed = false;
          if (visible)
            passwordField.forceActiveFocus();
        }

        Components.Text {
          Layout.fillWidth: true
          text: Services.Network.lastError !== "" ? Services.Network.lastError : `Password for "${netItem.ssid}"`
          size: Core.Style.fontS
          color: Services.Network.lastError !== "" ? Config.Theme.error : Config.Theme.textDim
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Core.Style.spaceXS

          Components.TextField {
            id: passwordField

            Layout.fillWidth: true
            placeholder: "Network password"
            echoMode: showPassword.revealed ? TextInput.Normal : TextInput.Password
            onAccepted: passwordPrompt.submit()
            onCancelled: Services.Network.cancelPasswordPrompt()
          }

          Components.Button {
            id: showPassword

            property bool revealed: false

            icon: revealed ? "eye-off" : "eye"
            iconSize: Core.Style.fontM
            tooltipText: revealed ? "Hide password" : "Show password"
            onClicked: revealed = !revealed
          }

          Components.Button {
            icon: "check"
            iconSize: Core.Style.fontM
            variant: "primary"
            tooltipText: "Connect"
            enabled: passwordField.text.length > 0
            onClicked: passwordPrompt.submit()
          }

          Components.Button {
            icon: "close"
            iconSize: Core.Style.fontM
            variant: "danger"
            tooltipText: "Cancel"
            onClicked: Services.Network.cancelPasswordPrompt()
          }
        }
      }
    }
  }
}
