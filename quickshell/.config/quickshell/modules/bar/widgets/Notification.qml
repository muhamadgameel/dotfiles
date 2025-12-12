import QtQuick

import "../../../components" as Components
import "../../../config" as Config
import "../../../services" as Services

/*
* Notification Bar Widget - Shows notification bell and opens notification center
*/
Item {
  id: root

  implicitWidth: notificationButton.implicitWidth
  implicitHeight: notificationButton.implicitHeight

  // Badge for unread count (bind directly to service property)
  property int unreadCount: Services.Notification.unreadCount

  signal clickedMainEvent

  Components.Button {
    id: notificationButton
    icon: Services.Notification.doNotDisturb ? "bell-off" : "bell"
    iconColor: Services.Notification.doNotDisturb ? Config.Theme.warning : Config.Theme.text
    tooltipText: Services.Notification.doNotDisturb ? "Do Not Disturb" : "Notifications" + (root.unreadCount > 0 ? " (" + root.unreadCount + " unread)" : "")

    onClicked: function (button) {
      if (button === Qt.RightButton) {
        Services.Notification.doNotDisturb = !Services.Notification.doNotDisturb;
      } else if (button === Qt.LeftButton) {
        root.clickedMainEvent();
      }
    }
  }

  // Unread badge
  Components.Badge {
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.rightMargin: 1
    anchors.topMargin: 1
    count: root.unreadCount
    badgeColor: Services.Notification.doNotDisturb ? Config.Theme.warning : Config.Theme.error
  }
}
