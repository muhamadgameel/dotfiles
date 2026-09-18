pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../config" as Config
import "../core" as Core

/**
* ThemeSync - carries the shell's theme to Hyprland and hyprlock
*
* The shell owns the palettes and which one is active. Hyprland's borders and
* the lock screen kept their own hardcoded copies, so switching theme recoloured
* the shell and nothing else. This writes the active colours where each can
* read them, into the shell's state directory:
*
*   hyprlock-colors.conf   sourced by hyprlock.conf, read at every lock
*   hyprland-colors.lua    merged by settings/theme.lua at startup
*
* Both only override: each config defines its own colours first, so a missing
* file - a fresh install, the shell not running - changes nothing. A switch
* also recolours Hyprland's borders straight away rather than waiting for its
* next start, through a partial hl.config that leaves every other option alone.
*/
Singleton {
  id: root

  readonly property string hyprlockPath: `${Config.Settings.directory}/hyprlock-colors.conf`
  readonly property string hyprlandPath: `${Config.Settings.directory}/hyprland-colors.lua`

  // "rrggbb", or "rrggbbaa" with an alpha. hyprlang and Hyprland's Lua config
  // both take rgb(...) / rgba(...) around these.
  function _hex(color, alpha) {
    const byte = v => Math.round(v * 255).toString(16).padStart(2, "0");
    return byte(color.r) + byte(color.g) + byte(color.b) + (alpha === undefined ? "" : byte(alpha));
  }

  readonly property string _hyprlockText: `# Written by quickshell (services/ThemeSync.qml) from the active theme.
$accent = rgb(${_hex(Core.Theme.accent)})
$accentAlpha = rgba(${_hex(Core.Theme.accent, 0.933)})
$surface = rgba(${_hex(Core.Theme.bg, 0.9)})
$text = rgb(${_hex(Core.Theme.text)})
$subtext = rgb(${_hex(Core.Theme.textDim)})
$error = rgb(${_hex(Core.Theme.error)})
$success = rgb(${_hex(Core.Theme.success)})
$warning = rgba(${_hex(Core.Theme.warning, 0.9)})
`

  readonly property var _borders: ({
      accent: `rgb(${_hex(Core.Theme.accent)})`,
      inactive: `rgb(${_hex(Core.Theme.overlayLight)})`
    })

  readonly property string _hyprlandText: `-- Written by quickshell (services/ThemeSync.qml) from the active theme.
return {
	accent = "${_borders.accent}",
	accentAlpha = "rgba(${_hex(Core.Theme.accent, 0.933)})",
	inactive = "${_borders.inactive}",
	surface = "rgb(${_hex(Core.Theme.bg)})",
	text = "rgb(${_hex(Core.Theme.text)})",
}
`

  // The state directory may not exist yet on a first run: Settings creates it
  // too, but asynchronously, so a write here could race it.
  function sync() {
    _ensureDirectory.running = true;
  }

  // Only writes what differs, so an ordinary shell start touches nothing.
  function _write() {
    if (hyprlockFile.text() !== root._hyprlockText)
      hyprlockFile.setText(root._hyprlockText);

    if (hyprlandFile.text() === root._hyprlandText)
      return;

    hyprlandFile.setText(root._hyprlandText);
    _applyBorders.command = ["hyprctl", "eval", `hl.config({ general = { col = { active_border = "${root._borders.accent}", inactive_border = "${root._borders.inactive}" } } })`];
    _applyBorders.running = true;
    Core.Logger.i("ThemeSync", `theme colours written for ${Config.Config.theme}`);
  }

  on_HyprlockTextChanged: Qt.callLater(root.sync)
  on_HyprlandTextChanged: Qt.callLater(root.sync)

  FileView {
    id: hyprlockFile
    path: root.hyprlockPath
    blockLoading: true
    printErrors: false
  }

  FileView {
    id: hyprlandFile
    path: root.hyprlandPath
    blockLoading: true
    printErrors: false
  }

  Process {
    id: _ensureDirectory
    command: ["mkdir", "-p", Config.Settings.directory]
    onRunningChanged: {
      if (!running)
        root._write();
    }
  }

  Process {
    id: _applyBorders

    stderr: StdioCollector {
      onStreamFinished: {
        const msg = text.trim();
        if (msg)
          Core.Logger.w("ThemeSync", `hyprctl: ${msg}`);
      }
    }
  }
}
