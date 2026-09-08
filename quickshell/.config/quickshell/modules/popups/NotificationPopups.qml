pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../components" as Components
import "../../config" as Config
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

    sourceComponent: Core.PositionedPanelWindow {
      id: notifWindow

      // Hidden when there is nothing to show, so the window never blocks input
      // to what is behind it.
      //
      // Also hidden while the notification centre is open: both occupy the same
      // top-right corner, so popups drew straight over the panel's list.
      visible: Services.Notification.activeList.count > 0 && Services.Panels.openPanel !== "notifications"

      screen: modelData
      namespace: "quickshell-notifications"
      location: "top_right"

      margin: Core.Style.spaceL
      topExtra: Core.Style.barHeight

      readonly property int notifWidth: 400

      readonly property int shadowRoom: Math.max(Core.Style.spaceXS, Core.Style.elevationRoom(2))

      implicitWidth: notifWidth + (shadowRoom - Core.Style.spaceXS) * 2
      implicitHeight: notificationStack.implicitHeight + Core.Style.spaceL

      property var animateConnection: null

      Component.onCompleted: {
        animateConnection = function (notificationId) {
          var delegate = findDelegate(notificationId);
          if (delegate?.animator) {
            delegate.animator.hide();
          }
        };
        Services.Notification.animateAndRemove.connect(animateConnection);
      }

      Component.onDestruction: {
        if (animateConnection) {
          Services.Notification.animateAndRemove.disconnect(animateConnection);
          animateConnection = null;
        }
      }

      function findDelegate(notificationId) {
        if (!notificationRepeater)
          return null;
        for (var i = 0; i < notificationRepeater.count; i++) {
          var item = notificationRepeater.itemAt(i);
          if (item?.notificationId === notificationId) {
            return item;
          }
        }
        return null;
      }

      ColumnLayout {
        id: notificationStack

        anchors {
          top: parent.top
          right: parent.right
        }

        spacing: Core.Style.spaceS
        width: notifWindow.notifWidth + (notifWindow.shadowRoom - Core.Style.spaceXS) * 2

        Behavior on implicitHeight {
          SpringAnimation {
            spring: 2.0
            damping: 0.4
            epsilon: 0.01
            mass: 0.8
          }
        }

        Repeater {
          id: notificationRepeater
          model: Services.Notification.activeList

          delegate: Item {
            id: card

            required property var model
            required property int index

            property string notificationId: model.id
            property var notificationData: model
            property alias animator: slideAnimator

            readonly property int animationDelay: index * Core.Style.slideStagger

            Layout.preferredWidth: notifWindow.notifWidth + (notifWindow.shadowRoom - Core.Style.spaceXS) * 2
            Layout.preferredHeight: cardContent.implicitHeight + notifWindow.shadowRoom * 2
            Layout.maximumHeight: Layout.preferredHeight

            // === Slide Animator ===
            Core.SlideAnimator {
              id: slideAnimator
              target: card
              entryDelay: card.animationDelay
              slideFromTop: true
              onHideFinished: Services.Notification.dismiss(card.notificationId)
            }

            Component.onCompleted: slideAnimator.show()
            onNotificationIdChanged: slideAnimator.show()

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
              progressValue: model.progress

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
      }
    }
  }
}
