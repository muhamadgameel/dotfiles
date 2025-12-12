import QtQuick
import QtQuick.Layouts

import "../components" as Components
import "../config" as Config
import "../core" as Core

/*
* FormRow - Row with label and optional control (toggle/value)
*/
Rectangle {
  id: root

  property string label: "Label"
  property bool hasToggle: false
  property bool toggleChecked: false
  property string valueText: ""

  signal toggled(bool checked)

  Layout.fillWidth: true
  implicitHeight: 40
  radius: Core.Style.radiusS
  color: rowMouse.containsMouse ? Config.Theme.surface : Config.Theme.transparent

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: Core.Style.spaceM
    anchors.rightMargin: Core.Style.spaceM

    Components.Label {
      text: root.label
      Layout.fillWidth: true
    }

    Components.Label {
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

  MouseArea {
    id: rowMouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
  }
}
