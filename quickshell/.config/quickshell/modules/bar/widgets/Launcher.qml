import QtQuick

import "../../../components" as Components
import "../../../core" as Core

/**
* Launcher - opens the application launcher
*
* Toggles fuzzel, as SUPER+D in keybinds.lua does. A Process rather than
* execDetached so a launcher that fails to start says so in the log instead of
* silently doing nothing.
*/
Components.Button {
  id: root

  icon: "apps"
  tooltipText: "Applications"

  // Closes a launcher that is open, wherever it was started; otherwise becomes it.
  Core.Command {
    id: fuzzelProcess
    command: ["sh", "-c", "pkill -x fuzzel || exec fuzzel"]
    onDone: exitCode => {
      Core.Logger.d("Launcher", `Fuzzel exited with code ${exitCode}`);
    }
  }

  // One started here is this Process, and stopping that closes it.
  onClicked: fuzzelProcess.running = !fuzzelProcess.running
}
