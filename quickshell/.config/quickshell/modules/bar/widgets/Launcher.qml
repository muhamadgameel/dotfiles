import QtQuick

import "../../../components" as Components
import "../../../core" as Core

/*
* Launcher - App launcher button
*/
Components.Button {
  id: root

  icon: "apps"
  tooltipText: "Applications"

  onClicked: {
    Core.Logger.d("Launcher", "Clicked - open app launcher");
    // TODO: Open launcher panel
  }
}
