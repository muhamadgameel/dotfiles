pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

/**
* Targets - resolves "where should this go" for compositor-driven commands
*
* IPC calls and global shortcuts have no pointer position to work from, so they
* need the focused output. Kept out of Services.Panels so the registry itself
* stays compositor-agnostic.
*/
Singleton {
  id: root

  /**
  * The ShellScreen for the monitor Hyprland currently has focused.
  *
  * HyprlandMonitor exposes a name rather than a ShellScreen, so match on that.
  * Falls back to the first screen, which is also the single-monitor answer.
  */
  readonly property var focusedScreen: {
    const name = Hyprland.focusedMonitor?.name ?? "";
    if (name !== "") {
      for (const screen of Quickshell.screens) {
        if (screen.name === name)
          return screen;
      }
    }
    return Quickshell.screens[0] ?? null;
  }

  // The Lua config evaluates a dispatch as Lua.
  function focusWorkspace(id) {
    Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
  }

  function moveToWorkspace(id) {
    Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${id}, follow = false })`);
  }
}
