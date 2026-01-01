import QtQuick

import "../../../components" as Components
import "../../../config" as Config
import "../../../core" as Core

/**
* Test - Bar widget to open the component test panel
*/
Components.Button {
  id: root

  signal panelRequested

  icon: "settings"
  iconColor: Config.Theme.accent
  tooltipText: "Component Test Panel"

  onClicked: function (button) {
    if (button === Qt.LeftButton) {
      root.panelRequested();
    }
  }
}
