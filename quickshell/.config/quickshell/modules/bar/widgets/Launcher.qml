import QtQuick
import Quickshell.Io

import "../../../components" as Components
import "../../../core" as Core

/**
* Launcher - opens the application launcher
*
* Spawns fuzzel, which is also on SUPER+D in keybinds.lua. A Process rather
* than execDetached so a launcher that fails to start says so in the log
* instead of silently doing nothing.
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
    fuzzelProcess.running = true;
  }
}
