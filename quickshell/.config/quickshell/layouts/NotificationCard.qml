import QtQuick
import QtQuick.Layouts

import "../components" as Components
import "../config" as Config
import "../core" as Core
import "../services" as Services

/**
* NotificationCard - Reusable notification card layout
*
* Displays notification content with:
* - App icon, name, timestamp
* - Summary and body text
* - Action buttons
* - Close button
* - Urgency indicator
*
* Usage:
*   NotificationCard {
*       notificationData: model
*       showProgress: true
*       onCloseClicked: dismiss()
*       onActionClicked: handleAction(actionId)
*   }
*/
Components.Card {
  id: root

  // === Properties ===
  property var notificationData: null
  property bool showProgress: true
  property bool showCloseButton: true
  property bool showUrgencyDot: true
  property bool compact: false

  // Progress value (0.0 to 1.0)
  property real progressValue: notificationData?.progress ?? 1.0

  // Extracted data (with fallbacks)
  readonly property string summary: notificationData?.summary ?? "No summary"
  readonly property string body: notificationData?.body ?? ""
  readonly property string appName: notificationData?.appName ?? "Unknown"
  readonly property int urgency: notificationData?.urgency ?? 1
  readonly property var timestamp: notificationData?.timestamp ?? null
  readonly property string image: notificationData?.image ?? ""
  readonly property var actions: Core.Utils.parseJson(notificationData?.actionsJson ?? "[]")

  // === Signals ===
  signal closeClicked
  signal actionClicked(string actionId)
  signal hoverChanged(bool isHovered)

  // Forward hover changes
  onHoveredChanged: hoverChanged(hovered)

  // === Card Configuration ===
  radius: Core.Style.radiusL
  borderColor: root.compact ? Config.Theme.alpha(Config.Theme.overlay, 0.5) : Config.Theme.overlay
  borderWidth: Core.Style.borderThin
  backgroundColor: root.compact ? Config.Theme.surface : Config.Theme.bg
  hoverColor: Config.Theme.surfaceHover

  implicitHeight: contentColumn.implicitHeight + Core.Style.spaceM * 2

  interactive: true

  // === Progress Bar ===
  Components.ProgressBar {
    visible: root.showProgress
    value: root.progressValue
    trackColor: Config.Theme.transparent
    progressColor: Config.Theme.urgencyColor(root.urgency)
    height: 2
    width: root.width - (2 * root.radius)
    anchors.horizontalCenter: parent.horizontalCenter
    reversed: true
  }

  // === Content ===
  ColumnLayout {
    id: contentColumn
    anchors.fill: parent
    anchors.margins: Core.Style.spaceS

    RowLayout {
      Layout.fillWidth: true
      spacing: Core.Style.spaceM
      Layout.leftMargin: Core.Style.spaceXS
      Layout.topMargin: root.compact ? Core.Style.spaceXXS : Core.Style.spaceXS
      Layout.bottomMargin: root.compact ? Core.Style.spaceXXS : Core.Style.spaceXS

      // App icon
      Components.Icon {
        Layout.alignment: Qt.AlignTop
        icon: root.image || "bell"
        size: root.compact ? 32 : 40
        padding: root.compact ? 4 : 8
        radius: Core.Style.radiusM
        backgroundColor: root.compact ? Config.Theme.bgAlt : Config.Theme.surface
        color: Config.Theme.text
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Core.Style.spaceXS

        // Header with app name and timestamp
        RowLayout {
          Layout.fillWidth: true
          spacing: Core.Style.spaceXS

          // Urgency dot
          Components.StatusDot {
            Layout.alignment: Qt.AlignVCenter
            visible: root.showUrgencyDot
            size: 6
            color: Config.Theme.urgencyColor(root.urgency)
          }

          Components.Text {
            text: root.appName
            size: root.compact ? Core.Style.fontXS : Core.Style.fontS
            font.weight: Font.Bold
            color: Config.Theme.accent
          }

          Components.Text {
            text: root.timestamp ? (" · " + Services.Time.formatRelativeTime(root.timestamp)) : ""
            size: Core.Style.fontXS
            color: Config.Theme.textMuted
            visible: text.length > 0
          }
        }

        // Summary
        Components.Text {
          text: root.summary
          size: root.compact ? Core.Style.fontM : Core.Style.fontL
          font.weight: Font.Medium
          color: Config.Theme.text
          wrapMode: Text.WrapAtWordBoundaryOrAnywhere
          maximumLineCount: root.compact ? 1 : 2
          visible: text.length > 0
          Layout.fillWidth: true
        }

        // Body
        Components.Text {
          text: root.body
          size: root.compact ? Core.Style.fontS : Core.Style.fontM
          color: Config.Theme.textDim
          wrapMode: Text.WrapAtWordBoundaryOrAnywhere
          maximumLineCount: root.compact ? 2 : 4
          visible: text.length > 0
          Layout.fillWidth: true
        }

        // Actions
        Flow {
          Layout.fillWidth: true
          spacing: Core.Style.spaceXS
          Layout.topMargin: Core.Style.spaceS
          visible: root.actions.length > 0 && !root.compact

          Repeater {
            model: root.actions

            delegate: Components.Button {
              property var actionData: modelData
              text: actionData.text
              variant: "secondary"
              implicitHeight: 26
              onClicked: root.actionClicked(actionData.identifier || "")
            }
          }
        }
      }

      // === Trash Button ===
      Components.Button {
        id: trashButton
        Layout.alignment: Qt.AlignCenter
        visible: root.showCloseButton && root.compact
        icon: "trash"
        variant: "danger"
        onClicked: root.closeClicked()
      }
    }
  }

  // === Close Button ===
  Components.Button {
    id: closeButton
    anchors.top: parent.top
    anchors.topMargin: Core.Style.spaceM
    anchors.right: parent.right
    anchors.rightMargin: Core.Style.spaceM
    visible: root.showCloseButton && !root.compact
    icon: "close"
    variant: "danger"
    onClicked: root.closeClicked()
  }
}
