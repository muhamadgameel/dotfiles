import QtQuick

import "../../../components" as Components
import "../../../config" as Config
import "../../../services" as Services

/**
* Network - Bar widget showing network connection status
*
* Displays WiFi/Ethernet connection state with click to open network panel
*/
Components.Button {
  id: root

  signal panelRequested

  icon: Services.Network.connectionIcon
  iconColor: {
    if (!Services.Network.isConnected)
      return Config.Theme.textMuted;
    if (!Services.Network.hasInternet)
      return Config.Theme.warning;
    return Config.Theme.text;
  }

  text: {
    // Only show WiFi signal when WiFi is primary (Ethernet not connected)
    if (Services.Network.wifiConnected && !Services.Network.ethernetConnected && Services.Network.wifiSignal > 0) {
      return Services.Network.wifiSignal + "%";
    }
    return "";
  }
  textColor: iconColor

  tooltipText: {
    if (!Services.Network.isConnected)
      return "No network connection";

    let tip = Services.Network.connectionStatusText;
    if (Services.Network.activeIP) {
      tip += "\n" + Services.Network.activeIP.split("/")[0];
    }
    if (!Services.Network.hasInternet) {
      tip += "\n⚠ No internet";
    }
    return tip;
  }

  // Click to toggle network panel
  onClicked: function (button) {
    if (button === Qt.LeftButton) {
      root.panelRequested();
    } else if (button === Qt.MiddleButton) {
      Services.Network.setWifiEnabled(!Services.Network.wifiEnabled);
    } else if (button === Qt.RightButton) {
      Services.Network.refreshAll();
    }
  }

  // Visual indicator for connecting state
  Components.StatusDot {
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottomMargin: 2
    visible: Services.Network.connecting || Services.Network.scanning
    pulse: true
    color: Config.Theme.accent
  }
}
