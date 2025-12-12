import QtQuick
import Quickshell

import "core" as Core
import "modules/bar" as Bar
import "modules/notification" as Notification
import "modules/osd" as OSD

/*
* shell.qml - Main entry point
*/
ShellRoot {
  id: shell

  Component.onCompleted: {
    Core.Logger.i("Shell", "━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    Core.Logger.i("Shell", "MyShell started!");
    Core.Logger.i("Shell", "━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  }

  // === Bar (one per screen) ===
  Bar.BarWindow {}

  // === OSD (one per screen) ===
  OSD.OSD {}

  // === Notification Popup (one per screen) ===
  Notification.Notification {}
}
