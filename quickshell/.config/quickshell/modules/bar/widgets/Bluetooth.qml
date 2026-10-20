import QtQuick

import "../../../core" as Core
import "../../../services" as Services

/**
* Bluetooth - Bar widget showing Bluetooth status
*
* Just the icon, in the accent colour while a device is connected; the device
* name is in the tooltip.
*
* - Left click: Open panel
* - Middle click: Toggle Bluetooth
* - Right click: Toggle discovery
*/
BarButton {
  id: root

  signal panelRequested

  icon: Services.Bluetooth.statusIcon
  iconColor: root.statusColor
  dot: Services.Bluetooth.discovering ? Core.Theme.accentAlt : Core.Theme.transparent

  tooltipText: _tooltip

  readonly property color statusColor: {
    if (!Services.Bluetooth.available || Services.Bluetooth.blocked || !Services.Bluetooth.enabled)
      return Core.Theme.textMuted;
    if (Services.Bluetooth.hasConnectedDevices)
      return Core.Theme.accentAlt;
    return Core.Theme.text;
  }

  readonly property string _tooltip: {
    if (!Services.Bluetooth.available)
      return "Bluetooth unavailable";
    if (Services.Bluetooth.blocked)
      return "Bluetooth blocked";
    if (!Services.Bluetooth.enabled)
      return "Bluetooth disabled";

    let tip = Services.Bluetooth.hasConnectedDevices ? Services.Bluetooth.statusText : "Bluetooth";

    const battery = Services.Bluetooth.connectedDevices.map(d => Services.Bluetooth.getDeviceBatteryText(d)).find(text => text);
    if (battery)
      tip += "\n🔋 " + battery;

    if (Services.Bluetooth.discovering)
      tip += "\n🔍 Scanning...";

    return tip;
  }

  acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
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
}
