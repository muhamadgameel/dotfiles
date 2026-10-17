import QtQuick

import "../../../core" as Core
import "../../../services" as Services

/**
* Network - Bar widget showing network connection status
*
* Displays the Wi-Fi or Ethernet connection state.
*
* - Left click:   open the network panel
* - Middle click: Wi-Fi on or off
* - Right click:  refresh the connection details
*/
BarButton {
  id: root

  signal panelRequested

  icon: Services.Network.connectionIcon
  iconColor: {
    if (!Services.Network.isConnected)
      return Core.Theme.textMuted;
    if (!Services.Network.hasInternet)
      return Core.Theme.warning;
    return Core.Theme.text;
  }

  text: {
    // Only show WiFi signal when WiFi is primary (Ethernet not connected)
    if (Services.Network.wifiConnected && !Services.Network.ethernetConnected && Services.Network.wifiSignal > 0) {
      return Services.Network.wifiSignal + "%";
    }
    return "";
  }
  textColor: iconColor
  dot: Services.Network.connecting || Services.Network.searching ? Core.Theme.accent : Core.Theme.transparent
  dotLoops: Animation.Infinite

  tooltipText: {
    if (!Services.Network.isConnected)
      return Services.Network.searching ? "Searching for networks..." : "No network connection";

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
  acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
  onClicked: function (button) {
    if (button === Qt.LeftButton) {
      root.panelRequested();
    } else if (button === Qt.MiddleButton) {
      Services.Network.setWifiEnabled(!Services.Network.wifiEnabled);
    } else if (button === Qt.RightButton) {
      Services.Network.refreshAll();
    }
  }
}
