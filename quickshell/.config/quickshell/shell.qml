//@ pragma UseQApplication
// Required by the system tray: QsMenuAnchor.open() renders a platform menu,
// which needs QApplication rather than the default QGuiApplication. Without
// this the right-click menu silently refuses to open and only says so in the
// log

import QtQuick
import Quickshell

import "config" as Config
import "core" as Core
import "modules/bar" as Bar
import "modules/ipc" as Ipc
import "modules/popups" as Popups
import "services" as Services

/**
* shell.qml - entry point
*
* Builds the four things that exist for the whole session: the bar (one window
* per screen, which owns the panels), the OSD, the notification popups, and the
* external-control surfaces. Everything else is a service singleton pulled in on
* first use, or a panel built lazily by BarWindow.
*
* This is also where Logger's level is set. Logger cannot read Config itself -
* Config reads Settings, and Settings logs - so the dependency is pushed from
* here, where nothing else depends on the result.
*/
ShellRoot {
  id: shell

  // Config.debugMode is persisted, so this follows a `qs ipc call` change to it
  // without a restart.
  Binding {
    target: Core.Logger
    property: "level"
    value: Config.Config.debugMode ? Core.Logger.levelDebug : Core.Logger.levelInfo
  }

  Component.onCompleted: {
    Core.Logger.i("Shell", `started, log level '${Core.Logger.levelName}'`);
    // Nothing else reads it, and a singleton only exists once something does.
    Services.ThemeSync.sync();
  }

  // === Bar (one per screen), which owns the sliding panels ===
  Bar.BarWindow {}

  // === On-screen display for volume, brightness and friends ===
  Popups.OSD {}

  // === Transient notification popups ===
  Popups.NotificationPopups {}

  // === The shared tooltip ===
  // Built here and handed to Services.Tooltip, so that service never has to
  // import the view layer to create it.
  Popups.TooltipWindow {
    id: tooltipWindow
  }

  Binding {
    target: Services.Tooltip
    property: "window"
    value: tooltipWindow
  }

  // === External control: `qs ipc call ...` and Hyprland global shortcuts ===
  Ipc.Ipc {}

  Ipc.Shortcuts {}
}
