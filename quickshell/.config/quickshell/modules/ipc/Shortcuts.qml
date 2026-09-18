import QtQuick
import Quickshell
import Quickshell.Hyprland

import "../../config" as Config
import "../../services" as Services

/**
* Shortcuts - compositor-level keybindings
*
* Registers actions with Hyprland's global-shortcuts protocol. Bind them in
* hypr/settings/keybinds.lua with the `global` dispatcher, e.g.
*
*   hl.bind(mod .. " + SHIFT + A", hl.dsp.global("quickshell:panelAudio"))
*
* Unlike exec binds these reach the running shell directly, so there is no
* process spawn and the shell can answer with its own state.
*/
Scope {
  id: root

  // --- Panels ---

  GlobalShortcut {
    appid: "quickshell"
    name: "panelAudio"
    description: "Toggle the sound panel"
    onPressed: Services.Panels.toggle("audio", Targets.focusedScreen)
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "panelNetwork"
    description: "Toggle the network panel"
    onPressed: Services.Panels.toggle("network", Targets.focusedScreen)
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "panelBluetooth"
    description: "Toggle the Bluetooth panel"
    onPressed: Services.Panels.toggle("bluetooth", Targets.focusedScreen)
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "panelSystemStats"
    description: "Toggle the system monitor panel"
    onPressed: Services.Panels.toggle("systemstats", Targets.focusedScreen)
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "panelNotifications"
    description: "Toggle the notification centre"
    onPressed: Services.Panels.toggle("notifications", Targets.focusedScreen)
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "panelClose"
    description: "Close any open panel"
    onPressed: Services.Panels.close()
  }

  // Bound to the mouse button itself, non-consuming, so the click that closes
  // a panel still lands on whatever is underneath.
  GlobalShortcut {
    appid: "quickshell"
    name: "panelDismiss"
    description: "Close an open panel when clicking away from it"
    onPressed: Services.Panels.dismiss()
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "panelQuickSettings"
    description: "Toggle quick settings"
    onPressed: Services.Panels.toggle("quicksettings", Targets.focusedScreen)
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "panelMedia"
    description: "Toggle the media panel"
    onPressed: Services.Panels.toggle("media", Targets.focusedScreen)
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "panelCalendar"
    description: "Toggle the calendar"
    onPressed: Services.Panels.toggle("calendar", Targets.focusedScreen)
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "panelPower"
    description: "Toggle the power menu"
    onPressed: Services.Panels.toggle("power", Targets.focusedScreen)
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "panelScreenshot"
    description: "Toggle the screenshot menu"
    onPressed: Services.Panels.toggle("screenshot", Targets.focusedScreen)
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "panelWallpaper"
    description: "Toggle the wallpaper picker"
    onPressed: Services.Panels.toggle("wallpaper", Targets.focusedScreen)
  }

  // --- Actions ---

  GlobalShortcut {
    appid: "quickshell"
    name: "mediaPlayPause"
    description: "Play/pause the active media player"
    onPressed: Services.Media.playPause()
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "toggleGameMode"
    description: "Toggle game mode by hand"
    onPressed: Services.GameMode.toggle()
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "toggleIdleInhibit"
    description: "Toggle the idle inhibitor"
    onPressed: Services.Idle.toggle()
  }

  // --- Notifications ---

  GlobalShortcut {
    appid: "quickshell"
    name: "toggleDnd"
    description: "Toggle do not disturb"
    onPressed: Config.Config.toggleDoNotDisturb()
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "toggleNightLight"
    description: "Toggle the night light"
    onPressed: Services.NightLight.toggle()
  }
}
