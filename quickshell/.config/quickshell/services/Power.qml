pragma Singleton

import QtQuick
import Quickshell

import "../core" as Core

/**
* Power - session and power actions
*
* Commands mirror the ones already bound in hypr/settings/keybinds.lua, so the
* menu and the keybinds do the same thing: hyprlock to lock, `uwsm stop` to log
* out (the session is uwsm-managed), systemctl for the rest.
*
* Actions run detached - the shell is about to go away in most of these cases,
* so nothing should be waiting on a child process.
*/
Singleton {
  id: root

  readonly property var actions: [
    {
      id: "lock",
      label: "Lock",
      icon: "lock",
      description: "Lock the screen",
      destructive: false,
      command: ["hyprlock"]
    },
    {
      id: "logout",
      label: "Log out",
      icon: "logout",
      description: "End the session",
      destructive: true,
      command: ["uwsm", "stop"]
    },
    {
      id: "suspend",
      label: "Suspend",
      icon: "moon",
      description: "Sleep, keeping session state",
      destructive: false,
      command: ["systemctl", "suspend"]
    },
    {
      id: "reboot",
      label: "Restart",
      icon: "refresh",
      description: "Reboot the machine",
      destructive: true,
      command: ["systemctl", "reboot"]
    },
    {
      id: "poweroff",
      label: "Shut down",
      icon: "power",
      description: "Power off the machine",
      destructive: true,
      command: ["systemctl", "poweroff"]
    }
  ]

  function find(id) {
    return actions.find(a => a.id === id) ?? null;
  }

  /**
  * Run a power action by id.
  *
  * Callers are responsible for confirming destructive actions first - see
  * PowerPanel, which requires a second click for anything that ends the
  * session.
  */
  function run(id) {
    const action = find(id);
    if (!action) {
      Core.Logger.w("Power", `Unknown action: ${id}`);
      return false;
    }

    Core.Logger.i("Power", `Running: ${action.label}`);
    Quickshell.execDetached(action.command);
    return true;
  }
}
