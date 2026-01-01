import QtQuick
import QtQuick.Layouts

import "../components" as Components
import "../config" as Config
import "../core" as Core

/**
* FormRow - Row with label and optional control (toggle/value)
*
* Usage:
*   FormRow {
*       label: "Enable notifications"
*       hasToggle: true
*       toggleChecked: settings.notifications
*       onToggled: settings.notifications = checked
*   }
*
*   FormRow {
*       label: "Version"
*       valueText: "1.0.0"
*   }
*/
Components.Card {
  id: root

  property string label: "Label"
  property bool hasToggle: false
  property bool toggleChecked: false
  property string valueText: ""

  signal toggled(bool checked)

  Layout.fillWidth: true
  implicitHeight: 40

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: Core.Style.spaceM
    anchors.rightMargin: Core.Style.spaceM

    Components.Text {
      text: root.label
      Layout.fillWidth: true
    }

    Components.Text {
      visible: root.valueText !== ""
      text: root.valueText
      color: Config.Theme.textDim
    }

    Components.Toggle {
      visible: root.hasToggle
      checked: root.toggleChecked
      onToggled: checked => {
        root.toggleChecked = checked;
        root.toggled(checked);
      }
    }
  }
}
