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

      // A notification arriving while the centre is open enters the same way as
      // its popup does - in from the right - so the two read as the same object
      // in two places rather than two unrelated lists.
      //
      // Newest is inserted at the top, so `move` is what carries everything else
      // down to make room, and back up again when one is dismissed. Without it
      // the rest of the list jumps.
      add: Transition {
        NumberAnimation {
          property: "x"
          from: historyColumn.width
          duration: Core.Style.duration(Core.Style.slideShowDuration)
          easing.type: Core.Style.easeStandard
        }

        NumberAnimation {
          property: "opacity"
          from: 0
          to: 1
          duration: Core.Style.duration(Core.Style.slideShowDuration)
          easing.type: Core.Style.easeStandard
        }
      }

      move: Transition {
        NumberAnimation {
          property: "y"
          duration: Core.Style.duration(Core.Style.animNormal)
          easing.type: Core.Style.easeStandard
        }
      }

      Repeater {
        model: Services.Notification.historyList

        delegate: Components.NotificationCard {
          id: historyCard

          required property var model

          width: historyColumn.width
          compact: true
          showProgress: false
          notificationData: model

          // A Repeater destroys its delegate the instant the model row goes, so
          // there is nothing left to animate afterwards. Slide it out first and
          // remove the row when that finishes - the same hide-then-dismiss order
          // the popup stack uses.
          onCloseClicked: exitAnim.start()

          ParallelAnimation {
            id: exitAnim

            onFinished: Services.Notification.removeFromHistory(historyCard.model.id)

            NumberAnimation {
              target: historyCard
              property: "x"
              to: historyColumn.width
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
}
