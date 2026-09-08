pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core
import "../../services" as Services

/**
* NotificationCenter - notification history
*
*/
Components.SlidingPanel {
  id: root

  panelId: "notifications"
  namespace: "quickshell-notification-center"
  panelWidth: 420

  headerIcon: Services.Notification.doNotDisturb ? "bell-off" : "bell"
  headerIconColor: Services.Notification.doNotDisturb ? Config.Theme.warning : Config.Theme.accent
  headerTitle: "Notifications"
  headerSubtitle: {
    const n = Services.Notification.historyList.count;
    if (Services.Notification.doNotDisturb)
      return n === 0 ? "Do Not Disturb" : `Do Not Disturb · ${n}`;
    return n === 0 ? "Nothing yet" : (n === 1 ? "1 notification" : `${n} notifications`);
  }

  // The list manages its own scrolling.
  scrollable: false
  fillHeight: false

  // Reading the list is what marks them read - the bar badge used to only clear
  // by deleting entries one at a time.
  onOpened: Services.Notification.markAllRead()

  // === Toolbar ===
  RowLayout {
    Layout.fillWidth: true
    spacing: Core.Style.spaceS

    Components.Button {
      variant: "secondary"
      icon: Services.Notification.doNotDisturb ? "bell-off" : "bell"
      text: Services.Notification.doNotDisturb ? "DND on" : "DND off"
      textSize: Core.Style.fontS
      iconColor: Services.Notification.doNotDisturb ? Config.Theme.warning : Config.Theme.text
      tooltipText: "Suppress notification popups"
      onClicked: Config.Config.toggleDoNotDisturb()
    }

    Components.Spacer {}

    Components.Button {
      variant: "danger"
      icon: "trash"
      text: "Clear"
      textSize: Core.Style.fontS
      enabled: Services.Notification.historyList.count > 0
      tooltipText: "Clear all notifications"
      onClicked: Services.Notification.clearHistory()
    }
  }

  // === Empty state ===
  Components.EmptyState {
    Layout.fillWidth: true
    Layout.preferredHeight: Core.Style.controlHeightL * 4
    visible: Services.Notification.historyList.count === 0
    icon: "bell-off"
    iconSize: 64
    message: "No notifications"
    hint: "Your notifications will appear here"
  }

  // === History list ===
  Components.ScrollArea {
    id: historyScroll

    Layout.fillWidth: true

    // fillHeight *and* preferredHeight, deliberately. preferredHeight is what
    // the panel measures to size itself; fillHeight is what lets the layout take
    // that height back once the panel hits the screen cap. Without it the layout
    // hands over the full preferred height, the outer Flickable clips the
    // overflow, and this ends up exactly as tall as its own content - which
    // means there is nothing left to scroll.
    Layout.fillHeight: true
    Layout.preferredHeight: historyColumn.implicitHeight
    Layout.minimumHeight: 0
    visible: Services.Notification.historyList.count > 0

    contentHeight: historyColumn.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    leftMargin: 0
    rightMargin: 0

    Column {
      id: historyColumn

      width: historyScroll.width
      spacing: Core.Style.spaceS

      Repeater {
        model: Services.Notification.historyList

        delegate: Components.NotificationCard {
          required property var model

          width: historyColumn.width
          compact: true
          showProgress: false
          notificationData: model
          onCloseClicked: Services.Notification.removeFromHistory(model.id)
        }
      }
    }
  }
}
