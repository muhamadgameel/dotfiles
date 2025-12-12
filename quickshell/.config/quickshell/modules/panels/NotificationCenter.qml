import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core
import "../../layouts" as Layouts
import "../../services" as Services

Loader {
  id: root
  active: true

  required property ShellScreen screen

  function toggle() {
    if (root.item) {
      root.item.visible = !root.item.visible;
    }
  }

  sourceComponent: Component {
    Core.PositionedPanelWindow {
      id: centerWindow
      visible: false

      screen: root.screen
      location: "top_right"
      namespace: "quickshell-notification-center"

      width: 400
      height: Math.min(800, screen?.height * 0.7 || 800)
      topExtra: Core.Style.barHeight

      // Panel content
      Rectangle {
        anchors.fill: parent
        radius: Core.Style.radiusL
        color: Config.Theme.bg
        border.color: Config.Theme.overlay
        border.width: Core.Style.borderThin

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Core.Style.spaceM
          spacing: Core.Style.spaceM

          // Header
          RowLayout {
            Layout.fillWidth: true
            spacing: Core.Style.spaceS

            Components.Icon {
              name: "bell"
              size: Core.Style.fontXXL
              color: Config.Theme.accent
            }

            Components.Label {
              text: "Notifications"
              font.pixelSize: Core.Style.fontL
              font.weight: Font.Bold
              color: Config.Theme.text
              Layout.fillWidth: true
            }

            // DND toggle
            Components.Button {
              padding: Core.Style.spaceXXS
              icon: Services.Notification.doNotDisturb ? "bell-off" : "bell"
              iconSize: Core.Style.fontXL
              backgroundColor: Config.Theme.surface
              iconColor: Services.Notification.doNotDisturb ? Config.Theme.warning : Config.Theme.text
              onClicked: Services.Notification.doNotDisturb = !Services.Notification.doNotDisturb
            }

            // Clear button
            Components.Button {
              padding: Core.Style.spaceXXS
              icon: "trash"
              iconSize: Core.Style.fontXL
              backgroundColor: Config.Theme.surface
              iconColor: Config.Theme.text
              onClicked: Services.Notification.clearHistory()
            }

            // Close button
            Components.Button {
              padding: Core.Style.spaceXXS
              icon: "close"
              iconSize: Core.Style.fontXL
              backgroundColor: Config.Theme.surface
              iconColor: Config.Theme.text
              useActiveColorOnHover: true
              onClicked: centerWindow.visible = false
            }
          }

          // Empty state
          ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter
            visible: Services.Notification.historyList.count === 0
            spacing: Core.Style.spaceL

            Item {
              Layout.fillHeight: true
            }

            Components.Icon {
              name: "bell-off"
              size: 64
              color: Config.Theme.textMuted
              Layout.alignment: Qt.AlignHCenter
            }

            Components.Label {
              text: "No notifications"
              font.pixelSize: Core.Style.fontL
              color: Config.Theme.textMuted
              Layout.alignment: Qt.AlignHCenter
            }

            Components.Label {
              text: "Your notifications will appear here"
              font.pixelSize: Core.Style.fontS
              color: Config.Theme.textMuted
              Layout.alignment: Qt.AlignHCenter
            }

            Item {
              Layout.fillHeight: true
            }
          }

          // Notification list
          ScrollView {
            id: historyScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            clip: true
            visible: Services.Notification.historyList.count > 0

            Column {
              width: historyScrollView.width
              spacing: Core.Style.spaceS

              Repeater {
                model: Services.Notification.historyList

                delegate: Layouts.NotificationCard {
                  id: historyItem
                  width: parent.width
                  compact: true
                  showProgress: false
                  notificationData: model
                  onCloseClicked: Services.Notification.removeFromHistory(model.id)
                }
              }
            }
          }
        }
      }
    }
  }
}
