import QtQuick

import "../../../components" as Components
import "../../../config" as Config
import "../../../core" as Core
import "../../../services" as Services

/**
* Notification Bar Widget - Shows notification bell and opens notification center
*/
BarButton {
  id: root

  property int unreadCount: Services.Notification.unreadCount

  signal panelRequested

  icon: Services.Notification.doNotDisturb ? "bell-off" : "bell"
  iconColor: Services.Notification.doNotDisturb ? Core.Theme.warning : Core.Theme.text
  tooltipText: Services.Notification.doNotDisturb ? (Services.GameMode.active && !Config.Config.doNotDisturb ? "Do Not Disturb (game mode)" : "Do Not Disturb") : "Notifications" + (root.unreadCount > 0 ? " (" + root.unreadCount + " unread)" : "")

  acceptedButtons: Qt.LeftButton | Qt.RightButton
  onClicked: function (button) {
    if (button === Qt.RightButton) {
      Config.Config.toggleDoNotDisturb();
    } else if (button === Qt.LeftButton) {
      root.panelRequested();
    }
  }

  Components.Badge {
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.rightMargin: 1
    anchors.topMargin: 1
    variant: "count"
    count: root.unreadCount
    backgroundColor: Services.Notification.doNotDisturb ? Core.Theme.warning : Core.Theme.accent
  }
}
