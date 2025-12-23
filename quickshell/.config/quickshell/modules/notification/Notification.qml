import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../config" as Config
import "../../core" as Core
import "../../layouts" as Layouts
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

      // Hide window when no notifications - prevents blocking input to windows behind
      visible: Services.Notification.activeList.count > 0

      screen: modelData
      namespace: "quickshell-notifications"
      location: "top_right"

      margin: Core.Style.spaceL
      topExtra: Core.Style.barHeight

      readonly property int notifWidth: 400

      implicitWidth: notifWidth
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
        width: notifWidth

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

            property string notificationId: model.id
            property var notificationData: model
            property alias animator: slideAnimator

            readonly property int animationDelay: index * 80
            readonly property int slideDistance: 300

            Layout.preferredWidth: notifWidth
            Layout.preferredHeight: cardContent.implicitHeight + Core.Style.spaceL * 2
            Layout.maximumHeight: Layout.preferredHeight

            // === Slide Animator ===
            Core.SlideAnimator {
              id: slideAnimator
              target: card
              slideDistance: card.slideDistance
              entryDelay: card.animationDelay
              slideFromTop: true
              onHideFinished: Services.Notification.dismiss(card.notificationId)
            }

            Component.onCompleted: slideAnimator.show()
            onNotificationIdChanged: slideAnimator.show()

            // === Notification Card ===
            Layouts.NotificationCard {
              id: cardContent
              anchors.fill: parent
              anchors.margins: Core.Style.spaceXS

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
