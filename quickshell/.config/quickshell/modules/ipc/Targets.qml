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

  // Hyprland's Lua config mode evaluates a dispatch as Lua, so the plain
  // "workspace 3" form is a syntax error there and the classic form is wrong in
  // the other direction. Hyprland tells us which dialect it wants.
  readonly property bool usingLua: Hyprland.usingLua

  function focusWorkspace(id) {
    Hyprland.dispatch(usingLua ? `hl.dsp.focus({ workspace = ${id} })` : `workspace ${id}`);
  }

  function moveToWorkspace(id) {
    Hyprland.dispatch(usingLua ? `hl.dsp.window.move({ workspace = ${id}, follow = false })` : `movetoworkspacesilent ${id}`);
  }
}
