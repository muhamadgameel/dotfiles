import QtQuick
import Quickshell.Io

import "../../../components" as Components
import "../../../core" as Core

/*
* Launcher - App launcher button (opens fuzzel)
*/
Components.Button {
  id: root

  icon: "apps"
  tooltipText: "Applications"

  // Process to launch fuzzel
  Process {
    id: fuzzelProcess
    command: ["fuzzel"]
    onExited: (exitCode, exitStatus) => {
      Core.Logger.d("Launcher", `Fuzzel exited with code ${exitCode}`);
    }
  }

  onClicked: {
    Core.Logger.d("Launcher", "Opening fuzzel app launcher");
    fuzzelProcess.running = true;
  }
}
