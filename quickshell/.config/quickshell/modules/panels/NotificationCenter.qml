import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core
import "../../layouts" as Layouts
import "../../services" as Services

/**
* NotificationCenter - Panel showing notification history
*/
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
              icon: "bell"
              size: Core.Style.fontXXL
              color: Config.Theme.accent
            }

            Components.Text {
              text: "Notifications"
              size: Core.Style.fontL
              font.weight: Font.Bold
              color: Config.Theme.text
              Layout.fillWidth: true
            }

            // DND toggle
            Components.Button {
              icon: Services.Notification.doNotDisturb ? "bell-off" : "bell"
              iconColor: Services.Notification.doNotDisturb ? Config.Theme.warning : Config.Theme.text
              onClicked: Services.Notification.doNotDisturb = !Services.Notification.doNotDisturb
            }

            // Clear button
            Components.Button {
              icon: "trash"
              tooltipText: "Clear all"
              onClicked: Services.Notification.clearHistory()
            }

            // Close button
            Components.Button {
              icon: "close"
              variant: "danger"
              tooltipText: "Close"
              onClicked: centerWindow.visible = false
            }
          }

          // Empty state
          Layouts.EmptyState {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: Services.Notification.historyList.count === 0
            icon: "bell-off"
            iconSize: 64
            message: "No notifications"
            hint: "Your notifications will appear here"
          }

          // Notification list
          Components.ScrollArea {
            id: historyScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: Services.Notification.historyList.count > 0
            contentHeight: historyColumn.height
            boundsBehavior: Flickable.DragOverBounds
            rightMargin: 0
            leftMargin: 0

            Column {
              id: historyColumn
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
