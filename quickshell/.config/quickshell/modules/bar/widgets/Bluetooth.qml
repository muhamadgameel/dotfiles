import QtQuick

import "../../../components" as Components
import "../../../config" as Config
import "../../../core" as Core
import "../../../services" as Services

/**
* Bluetooth - Bar widget showing Bluetooth status
*
* - Left click: Open panel
* - Middle click: Toggle Bluetooth
* - Right click: Toggle discovery
*/
Components.Button {
  id: root

  signal panelRequested

  icon: Services.Bluetooth.statusIcon
  iconSize: Core.Style.fontL
  iconColor: _iconColor

  text: _displayText
  textColor: _iconColor

  tooltipText: _tooltip

  readonly property color _iconColor: {
    if (!Services.Bluetooth.available || Services.Bluetooth.blocked || !Services.Bluetooth.enabled)
      return Config.Theme.textMuted;
    if (Services.Bluetooth.hasConnectedDevices)
      return Config.Theme.accentAlt;
    return Config.Theme.text;
  }

  readonly property string _displayText: {
    if (!Services.Bluetooth.enabled)
      return "";
    if (Services.Bluetooth.connectedCount === 1)
      return Services.Bluetooth.firstConnectedName;
    if (Services.Bluetooth.connectedCount > 1)
      return Services.Bluetooth.connectedCount.toString();
    return "";
  }

  readonly property string _tooltip: {
    if (!Services.Bluetooth.available)
      return "Bluetooth unavailable";
    if (Services.Bluetooth.blocked)
      return "Bluetooth blocked";
    if (!Services.Bluetooth.enabled)
      return "Bluetooth disabled\nMiddle-click to enable";

    let tip = Services.Bluetooth.hasConnectedDevices ? Services.Bluetooth.statusText : "Bluetooth";

    // Battery info
    if (Services.Bluetooth.devicesWithBattery.length > 0) {
      const battery = Services.Bluetooth.getDeviceBatteryText(Services.Bluetooth.devicesWithBattery[0]);
      if (battery)
        tip += "\n🔋 " + battery;
    }

    if (Services.Bluetooth.discovering)
      tip += "\n🔍 Scanning...";
    tip += "\nMiddle-click to toggle";

    return tip;
  }

  onClicked: function (button) {
    if (button === Qt.LeftButton) {
      root.panelRequested();
    } else if (button === Qt.MiddleButton) {
      Services.Bluetooth.toggle();
    } else if (button === Qt.RightButton && Services.Bluetooth.enabled) {
      if (Services.Bluetooth.discovering)
        Services.Bluetooth.stopDiscovery();
      else
        Services.Bluetooth.startDiscovery();
    }
  }

  // Scanning indicator
  Components.StatusDot {
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottomMargin: 2
    visible: Services.Bluetooth.discovering
    pulse: true
    color: Config.Theme.accentAlt
  }
}
