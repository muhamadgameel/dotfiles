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
  namespace: "quickshell-notification-panel"
  panelWidth: Math.round(420 * Core.Style.uiScale)

  headerIcon: Services.Notification.doNotDisturb ? "bell-off" : "bell"
  headerIconColor: Services.Notification.doNotDisturb ? Config.Theme.warning : Config.Theme.accent
  headerTitle: "Notifications"
  headerSubtitle: {
    const n = Services.Notification.historyList.count;
    if (Services.Notification.doNotDisturb)
      return n === 0 ? "Do Not Disturb" : `Do Not Disturb · ${n}`;
    return n === 0 ? "Nothing yet" : (n === 1 ? "1 notification" : `${n} notifications`);
  }

  // Reading the list is what marks them read - the bar badge used to only clear
  // by deleting entries one at a time.
  onOpened: Services.Notification.markAllRead()

  // === Toolbar ===
  // Pinned, so DND and Clear stay in reach however far the list is scrolled.
  pinned: RowLayout {
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
  // A notification arriving while the centre is open slides in from the right,
  // the same way its popup does, so the two read as the same object in two
  // places rather than two unrelated lists. Newest is inserted at the top, so
  // the column carries everything else down to make room, and back up again
  // when one is dismissed.
  Components.AnimatedColumn {
    id: historyColumn

    Layout.fillWidth: true
    visible: Services.Notification.historyList.count > 0
    spacing: Core.Style.spaceS
    animated: root.revealed
    enterOffset: historyColumn.width

    Repeater {
      model: Services.Notification.historyList

      // The row is what the column positions and animates; the card inside it
      // runs its own exit. Kept apart so a card that is closing while the list
      // shifts is not pulled back into view by the column's move transition.
      delegate: Item {
        id: historyRow

        required property var model

        width: historyColumn.width
        height: historyCard.height

        Components.NotificationCard {
          id: historyCard

          width: parent.width
          compact: true
          showProgress: false
          notificationData: historyRow.model

          // A Repeater destroys its delegate the instant the model row goes,
          // so there is nothing left to animate afterwards. Slide it out first
          // and remove the row when that finishes - the same hide-then-dismiss
          // order the popup stack uses.
          onCloseClicked: exitAnim.start()
        }

        ParallelAnimation {
          id: exitAnim

          onFinished: Services.Notification.removeFromHistory(historyRow.model.id)

          NumberAnimation {
            target: historyCard
            property: "x"
            to: historyRow.width
            duration: Core.Style.duration(Core.Style.slideHideDuration)
            easing.type: Core.Style.easeExit
          }

          NumberAnimation {
            target: historyCard
            property: "opacity"
            to: 0
            duration: Core.Style.duration(Core.Style.slideHideDuration)
            easing.type: Core.Style.easeExit
          }
        }
      }
    }
  }
}
