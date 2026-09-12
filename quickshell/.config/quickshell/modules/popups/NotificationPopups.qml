pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../components" as Components
import "../../core" as Core
import "../../services" as Services

/**
* Notification Popup - Displays active notifications on screen
*/
Variants {
  model: Quickshell.screens

  delegate: Loader {
    id: root

    required property ShellScreen modelData

    sourceComponent: Components.PositionedPanelWindow {
      id: notifWindow

      // Hidden when there is nothing to show, so the window never blocks input
      // to what is behind it.
      //
      // Also hidden while the notification centre is open: both occupy the same
      // top-right corner, so popups drew straight over the panel's list.
      visible: Services.Notification.activeList.count > 0 && Services.Panels.openPanel !== "notifications"

      screen: root.modelData
      namespace: "quickshell-notifications"
      location: "top_right"

      margin: Core.Style.spaceL
      topExtra: Core.Style.barHeight

      // A fixed full-height column rather than one sized to the stack: that
      // resized the layer surface on every arrival and every dismissal, a
      // compositor round trip each time. Same approach as SlidingPanel.
      anchors.bottom: true
      margins.bottom: Core.Style.spaceL

      // Input only lands on the stack; the empty column below it passes clicks
      // through to whatever is underneath.
      mask: Region {
        item: notificationStack
      }

      readonly property int notifWidth: Math.round(400 * Core.Style.uiScale)

      readonly property int shadowRoom: Math.max(Core.Style.spaceXS, Core.Style.elevationRoom(2))

      implicitWidth: notifWidth + (shadowRoom - Core.Style.spaceXS) * 2

      Components.AnimatedColumn {
        id: notificationStack

        anchors {
          top: parent.top
          right: parent.right
        }

        fadeIn: false
        spacing: Core.Style.spaceS
        width: notifWindow.notifWidth + (notifWindow.shadowRoom - Core.Style.spaceXS) * 2

        Repeater {
          model: Services.Notification.activeList

          delegate: Item {
            id: card

            required property var model
            required property int index

            property string notificationId: model.id
            property var notificationData: model

            // Only the first maxVisible have room on screen; the rest are queued
            // and counted by the pill at the bottom of the stack. The column
            // skips invisible children entirely, so a queued card contributes no
            // height and no spacing.
            readonly property bool onScreen: card.index < Services.Notification.maxVisible

            visible: card.onScreen

            width: notificationStack.width
            height: cardContent.implicitHeight + notifWindow.shadowRoom * 2

            Connections {
              target: Services.Notification

              function onAnimateAndRemove(notificationId) {
                if (notificationId === card.notificationId)
                  slideAnimator.hide();
              }
            }

            // === Slide Animator ===
            Core.SlideAnimator {
              id: slideAnimator
              target: card

              // In from the right, and back out to the right. The window ends a
              // hair short of the screen edge, so the travel is clipped there -
              // which is the point: the card reads as arriving from off-screen
              // rather than sliding around inside the stack.
              slideFrom: "right"

              onHideFinished: Services.Notification.dismiss(card.notificationId)
            }

            // Entry is driven by having room, not just by being constructed: a
            // queued card has to animate in when one above it goes away. The
            // stagger applies only to a batch built in one go - a promoted card
            // slides straight in behind the one that just left.
            property bool _entered: false

            function _enter(delay) {
              if (!card.onScreen || card._entered)
                return;
              card._entered = true;
              slideAnimator.entryDelay = delay;
              slideAnimator.show();
            }

            onOnScreenChanged: {
              if (card.onScreen) {
                card._enter(0);
              } else {
                // Pushed back into the queue by newer arrivals. Park it in the
                // hidden state so a later promotion has something to animate from.
                card._entered = false;
                slideAnimator.setHidden();
              }
            }

            Component.onCompleted: card._enter(card.index * Core.Style.slideStagger)

            onNotificationIdChanged: {
              card._entered = false;
              card._enter(0);
            }

            // === Notification Card ===
            // Inside the animated card Item, so SlideAnimator carries it.
            Components.Elevation {
              surface: cardContent
              level: 2
              radius: cardContent.radius
            }

            Components.NotificationCard {
              id: cardContent
              anchors.fill: parent
              anchors.margins: notifWindow.shadowRoom

              notificationData: card.notificationData
              showProgress: true
              progressValue: card.model.progress

              onHoverChanged: {
                if (hovered) {
                  Services.Notification.pauseTimeout(card.notificationId);
                } else {
                  Services.Notification.resumeTimeout(card.notificationId);
                }
              }

              onClicked: button => {
                if (button === Qt.RightButton) {
                  slideAnimator.hide();
                }
              }

              onCloseClicked: {
                Services.Notification.removeFromHistory(card.notificationId);
                slideAnimator.hide();
              }

              onActionClicked: actionId => {
                Services.Notification.invokeAction(card.notificationId, actionId);
              }
            }
          }
        }

        // === Overflow counter ===
        // Without this the queued notifications just look like they never
        // arrived: the stack silently caps at five and the sixth appears to have
        // pushed the oldest into nothing.
        Components.Card {
          id: overflowPill

          readonly property int count: Services.Notification.hiddenCount
          readonly property bool shown: overflowPill.count > 0

          // The last non-zero count, so the text does not read "0 more" while
          // the pill is fading out.
          property int shownCount: 0
          onCountChanged: {
            if (overflowPill.count > 0)
              overflowPill.shownCount = overflowPill.count;
          }
          Component.onCompleted: overflowPill.shownCount = overflowPill.count

          // Kept visible until the fade-out has finished. Driving opacity off
          // `visible` itself meant the pill was already hidden by the time the
          // animation would have started, so neither direction ever played.
          visible: overflowPill.shown || overflowPill.opacity > 0
          enabled: overflowPill.shown

          x: (notificationStack.width - width) / 2
          width: overflowRow.implicitWidth + Core.Style.spaceL * 2
          height: Core.Style.controlHeightS

          radius: Core.Style.radiusFull
          interactive: true
          onClicked: Services.Panels.open("notifications", notifWindow.screen)

          // Grows from the middle as it appears, so it reads as part of the
          // stack settling rather than as a row that blinked into existence.
          opacity: overflowPill.shown ? 1 : 0
          scale: overflowPill.shown ? 1 : Core.Style.popHiddenScale

          Behavior on opacity {
            NumberAnimation {
              duration: Core.Style.duration(Core.Style.animNormal)
              easing.type: Core.Style.easeStandard
            }
          }

          Behavior on scale {
            NumberAnimation {
              duration: Core.Style.duration(Core.Style.animNormal)
              easing.type: Core.Style.easeEnter
              easing.overshoot: Core.Style.enterOvershoot
            }
          }

          RowLayout {
            id: overflowRow

            anchors.centerIn: parent
            spacing: Core.Style.spaceXS

            Components.Icon {
              icon: "bell"
              size: Core.Style.fontM
              color: Core.Theme.textDim
            }

            Components.Text {
              text: overflowPill.shownCount === 1 ? "1 more notification" : `${overflowPill.shownCount} more notifications`
              size: Core.Style.fontS
              color: Core.Theme.textDim
            }
          }
        }
      }
    }
  }
}
