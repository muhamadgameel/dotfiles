pragma ComponentBehavior: Bound

import QtQuick

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

    delegate: Components.ListRow {
      id: actionCard

      required property var modelData

      readonly property bool armed: root.pendingAction === modelData.id

      interactive: true

      backgroundColor: armed ? Core.Theme.alpha(Core.Theme.error, Core.Style.opacityTintStrong) : Core.Theme.transparent
      hoverColor: modelData.destructive ? Core.Theme.alpha(Core.Theme.error, Core.Style.opacityTint) : Core.Theme.surfaceHover
      borderColor: armed ? Core.Theme.error : Core.Theme.transparent
      borderWidth: armed ? Core.Style.borderThin : 0

      icon: modelData.icon
      iconColor: modelData.destructive ? Core.Theme.error : Core.Theme.text
      title: armed ? `Confirm ${modelData.label.toLowerCase()}?` : modelData.label
      titleColor: armed ? Core.Theme.error : Core.Theme.text
      subtitle: armed ? "Click again to confirm" : modelData.description
      trailingIcon: armed ? "warning" : ""
      trailingSize: Core.Style.fontL
      trailingColor: Core.Theme.error

      onClicked: root.trigger(actionCard.modelData)
    }
  }
}
