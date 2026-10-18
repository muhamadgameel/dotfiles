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

  function togglePanel(id) {
    Services.Panels.toggle(id, Targets.focusedScreen);
  }

  // name: [description, action]
  readonly property var shortcuts: ({
      panelAudio: ["Toggle the sound panel", () => root.togglePanel("audio")],
      panelNetwork: ["Toggle the network panel", () => root.togglePanel("network")],
      panelBluetooth: ["Toggle the Bluetooth panel", () => root.togglePanel("bluetooth")],
      panelSystemStats: ["Toggle the system monitor panel", () => root.togglePanel("systemstats")],
      panelNotifications: ["Toggle the notification centre", () => root.togglePanel("notifications")],
      panelQuickSettings: ["Toggle quick settings", () => root.togglePanel("quicksettings")],
      panelMedia: ["Toggle the media panel", () => root.togglePanel("media")],
      panelCalendar: ["Toggle the calendar", () => root.togglePanel("calendar")],
      panelPower: ["Toggle the power menu", () => root.togglePanel("power")],
      panelPowerOpen: ["Open the power menu", () => Services.Panels.open("power", Targets.focusedScreen)],
      panelScreenshot: ["Toggle the screenshot menu", () => root.togglePanel("screenshot")],
      panelWallpaper: ["Toggle the wallpaper picker", () => root.togglePanel("wallpaper")],
      panelSettings: ["Toggle the settings panel", () => root.togglePanel("settings")],
      panelClose: ["Close any open panel", () => Services.Panels.close()],
      panelDismiss: ["Close an open panel when clicking away from it", () => Services.Panels.dismiss()],
      mediaPlayPause: ["Play/pause the active media player", () => Services.Media.playPause()],
      toggleGameMode: ["Toggle game mode by hand", () => Services.GameMode.toggle()],
      toggleIdleInhibit: ["Toggle the idle inhibitor", () => Services.Idle.toggle()],
      toggleDnd: ["Toggle do not disturb", () => Config.Config.toggleDoNotDisturb()],
      toggleNightLight: ["Toggle the night light", () => Services.NightLight.toggle()]
    })

  Variants {
    model: Object.keys(root.shortcuts)

    GlobalShortcut {
      property string modelData

      appid: "quickshell"
      name: modelData
      description: root.shortcuts[modelData][0]
      onPressed: root.shortcuts[modelData][1]()
    }
  }
}
