pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower

import "../core" as Core

/**
* GameMode - keeps the shell out of the way while a game runs
*
* Active while any of these hold:
*
* - gamemode reports a game. Its [custom] hooks in gamemode.ini call
*   `qs ipc call gamemode enter` / `exit` (the `gamemode` stow package). This is
*   the reliable signal: the game asks for it, through `gamemoderun %command%`
*   in its Steam launch options.
* - A game window is focused and fullscreen - the fallback for anything not
*   started through gamemoderun. Matched by window class, so fullscreen video
*   does not count.
* - It was switched on by hand (quick settings, or `qs ipc call gamemode toggle`).
*
* While active:
*
* - Notification popups are held back; notifications still reach the history.
*   Popups sit on the Overlay layer, which Hyprland draws over a fullscreen game,
*   so they are the one thing this shell would put in front of one.
* - The power profile goes to Performance, and comes back on exit - unless it was
*   changed by hand in between, in which case the hand-picked one stays.
*
* Deliberately left alone:
*
* - The bar. Tested: with a window fullscreen and the bar mapped, Hyprland's
*   solitary check was blocked by the window itself ("OPAQUE") and never by the
*   bar - a fullscreen window already covers the Top layer. Hiding the bar would
*   only reflow windowed apps, for nothing.
* - Idle inhibition. gamemode's inhibit_screensaver and Hyprland's idle_inhibit
*   window rule already cover it, through interfaces hypridle honours.
* - Polling. The idle shell costs ~0.3% CPU; pausing SystemStats would save a
*   sliver of that and leave the bar showing frozen numbers after alt-tab.
*/
Singleton {
  id: root

  // === State ===

  // Set through IPC by gamemode's start/end hooks.
  property bool gamemodeActive: false

  // Switched on by hand. Only adds to the other two: while gamemode reports a
  // game, turning this off does not end game mode.
  property bool manual: false

  // A focused, fullscreen window whose class is a game.
  readonly property bool fullscreenGame: {
    const toplevel = Hyprland.activeToplevel;
    const window = toplevel?.wayland;
    if (!window?.fullscreen)
      return false;
    // activeToplevel is left pointing at the last window when focus moves to an
    // empty workspace, so the window must also be on the focused one.
    if (toplevel.workspace !== Hyprland.focusedWorkspace)
      return false;
    return root._gameClass.test(window.appId ?? "");
  }

  readonly property bool active: gamemodeActive || manual || fullscreenGame

  // Why it is on, for display.
  readonly property string reason: {
    if (gamemodeActive)
      return "Game running";
    if (fullscreenGame)
      return "Fullscreen game";
    if (manual)
      return "On";
    return "Off";
  }

  // Proton titles are steam_app_<id>; gamescope nests anything. Keep in step
  // with the `games` list in hypr/settings/rules.lua.
  readonly property var _gameClass: /^(steam_app_[0-9]+|gamescope)$/

  // === Public API ===

  function enter() {
    gamemodeActive = true;
  }

  function exit() {
    gamemodeActive = false;
  }

  function toggle() {
    manual = !manual;
    return active;
  }

  // === Power Profile ===

  // The profile to return to on exit, or -1 when there is nothing to restore.
  property int _profileBefore: -1

  onActiveChanged: {
    Core.Logger.i("GameMode", active ? `on (${reason})` : "off");

    if (active) {
      if (!PowerProfiles.hasPerformanceProfile)
        return;
      _profileBefore = PowerProfiles.profile;
      PowerProfiles.profile = PowerProfile.Performance;
    } else {
      // Only undo what we did. A profile picked by hand mid-game stays.
      if (_profileBefore >= 0 && PowerProfiles.profile === PowerProfile.Performance)
        PowerProfiles.profile = _profileBefore;
      _profileBefore = -1;
    }
  }

  // === Startup ===

  // A shell restarted mid-game would otherwise stay off until the game quit.
  // Asks only when gamemoded is already running: a status query goes over
  // D-Bus, which would start the daemon just to hear "inactive".
  Process {
    running: true
    command: ["sh", "-c", "systemctl --user -q is-active gamemoded && gamemoded -s"]

    stdout: StdioCollector {
      onStreamFinished: {
        if (text.includes("gamemode is active"))
          root.gamemodeActive = true;
      }
    }
  }
}
