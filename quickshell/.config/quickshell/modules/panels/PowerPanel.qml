pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import "../../components" as Components
import "../../core" as Core
import "../../services" as Services

/**
* PowerPanel - session actions
*
* Anything that ends the session needs a second, explicit click. A misclick in
* the bar should not log you out of a full desktop.
*/
Components.SlidingPanel {
  id: root

  panelId: "power"

  headerIcon: "power"
  headerIconColor: Core.Theme.error
  headerTitle: "Power"
  headerSubtitle: "Session and power actions"

  // id of the destructive action awaiting confirmation, "" when none.
  property string pendingAction: ""

  // Never reopen already armed.
  onOpened: root.pendingAction = ""
  onClosed: root.pendingAction = ""

  function trigger(action) {
    if (action.destructive && root.pendingAction !== action.id) {
      root.pendingAction = action.id;
      confirmTimeout.restart();
      return;
    }

    root.pendingAction = "";
    Services.Power.run(action.id);
    root.close();
  }

  // Disarm on its own, so a forgotten confirmation does not stay live.
  Timer {
    id: confirmTimeout
    interval: 5000
    repeat: false
    onTriggered: root.pendingAction = ""
  }

  Repeater {
    model: Services.Power.actions

    delegate: Components.Card {
      id: actionCard

      required property var modelData

      readonly property bool armed: root.pendingAction === modelData.id

      Layout.fillWidth: true
      implicitHeight: Core.Style.controlHeightL
      interactive: true

      backgroundColor: armed ? Core.Theme.alpha(Core.Theme.error, 0.2) : Core.Theme.transparent
      hoverColor: modelData.destructive ? Core.Theme.alpha(Core.Theme.error, 0.15) : Core.Theme.surfaceHover
      borderColor: armed ? Core.Theme.error : Core.Theme.transparent
      borderWidth: armed ? 1 : 0

      onClicked: root.trigger(actionCard.modelData)

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Core.Style.spaceL
        anchors.rightMargin: Core.Style.spaceL
        spacing: Core.Style.spaceM

        Components.Icon {
          icon: actionCard.modelData.icon
          size: Core.Style.fontXL
          color: actionCard.modelData.destructive ? Core.Theme.error : Core.Theme.text
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 0

          Components.Text {
            Layout.fillWidth: true
            text: actionCard.armed ? `Confirm ${actionCard.modelData.label.toLowerCase()}?` : actionCard.modelData.label
            weight: Core.Style.weightBold
            color: actionCard.armed ? Core.Theme.error : Core.Theme.text
          }

          Components.Text {
            Layout.fillWidth: true
            text: actionCard.armed ? "Click again to confirm" : actionCard.modelData.description
            size: Core.Style.fontXS
            color: Core.Theme.textMuted
          }
        }

        Components.Icon {
          visible: actionCard.armed
          icon: "warning"
          size: Core.Style.fontL
          color: Core.Theme.error
        }
      }
    }
  }
}
