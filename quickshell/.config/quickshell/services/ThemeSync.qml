pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../config" as Config
import "../core" as Core

/**
* ThemeSync - carries the shell's theme to Hyprland, hyprlock, Alacritty and fuzzel
*
* The shell owns the palettes and which one is active. Hyprland's borders and
* the lock screen kept their own hardcoded copies, so switching theme recoloured
* the shell and nothing else. This writes the active colours where each can
* read them, into the shell's state directory:
*
*   hyprlock-colors.conf    sourced by hyprlock.conf, read at every lock
*   hyprland-colors.lua     merged by settings/theme.lua at startup
*   alacritty-colors.toml   for alacritty.toml to import; Alacritty reloads it live
*   fuzzel-colors.ini       for fuzzel.ini to include; read at every launch
*
* All only override: each config defines its own colours first, so a missing
* file - a fresh install, the shell not running - changes nothing. A switch
* also recolours Hyprland's borders straight away rather than waiting for its
* next start, through a partial hl.config that leaves every other option alone.
*
* GTK apps, browsers and other toolkits only need to know dark or light. That
* goes into GTK's own settings, which they read live.
*/
Singleton {
  id: root

  readonly property string hyprlockPath: `${Config.Settings.directory}/hyprlock-colors.conf`
  readonly property string hyprlandPath: `${Config.Settings.directory}/hyprland-colors.lua`
  readonly property string alacrittyPath: `${Config.Settings.directory}/alacritty-colors.toml`
  readonly property string fuzzelPath: `${Config.Settings.directory}/fuzzel-colors.ini`

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
      accentAlt: `rgb(${_hex(Core.Theme.accentAlt)})`,
      inactive: `rgb(${_hex(Core.Theme.overlayLight)})`
    })

  readonly property string _hyprlandText: `-- Written by quickshell (services/ThemeSync.qml) from the active theme.
return {
	accent = "${_borders.accent}",
	accentAlt = "${_borders.accentAlt}",
	accentAlpha = "rgba(${_hex(Core.Theme.accent, 0.933)})",
	inactive = "${_borders.inactive}",
	surface = "rgb(${_hex(Core.Theme.bg)})",
	text = "rgb(${_hex(Core.Theme.text)})",
}
`

  // Eight "name = colour" lines of the terminal palette, from index `from`.
  function _ansi(from) {
    const names = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"];
    return names.map((name, i) => `${name} = "${Core.Theme.term[from + i]}"`).join("\n");
  }

  readonly property string _alacrittyText: `# Written by quickshell (services/ThemeSync.qml) from the active theme.
[colors.primary]
background = "#${_hex(Core.Theme.bg)}"
foreground = "#${_hex(Core.Theme.text)}"

[colors.cursor]
text = "#${_hex(Core.Theme.bg)}"
cursor = "#${_hex(Core.Theme.text)}"

[colors.vi_mode_cursor]
text = "#${_hex(Core.Theme.bg)}"
cursor = "#${_hex(Core.Theme.accentAlt)}"

[colors.selection]
text = "CellForeground"
background = "#${_hex(Core.Theme.selection)}"

[colors.normal]
${_ansi(0)}

[colors.bright]
${_ansi(8)}

[bell]
color = "#${_hex(Core.Theme.accent)}"
`

  readonly property string _fuzzelText: `# Written by quickshell (services/ThemeSync.qml) from the active theme.
[colors]
background=${_hex(Core.Theme.bg, 0.8)}
text=${_hex(Core.Theme.text, 1)}
input=${_hex(Core.Theme.text, 1)}
prompt=${_hex(Core.Theme.accent, 1)}
placeholder=${_hex(Core.Theme.overlayLight, 1)}
counter=${_hex(Core.Theme.overlayLight, 1)}
selection=${_hex(Core.Theme.selection, 1)}
selection-text=${_hex(Core.Theme.accent, 1)}
selection-match=${_hex(Core.Theme.accentAlt, 1)}
match=${_hex(Core.Theme.accentAlt, 1)}
border=${_hex(Core.Theme.overlayLight, 1)}
`

  // Dark or light for everything outside the shell: GTK 4 and browsers read the
  // colour scheme, GTK 3 goes by the theme's name, and Papirus has a set for each.
  readonly property var _gtk: Core.Theme.isDark ? ["prefer-dark", "Adwaita-dark", "Papirus-Dark"] : ["prefer-light", "Adwaita", "Papirus-Light"]

  function _syncGtk() {
    _applyGtk.running = true;
  }

  // The state directory does not exist on a first run. Settings creates it and
  // says when; until then there is nowhere to write.
  function sync() {
    if (Config.Settings.directoryReady)
      _write();
  }

  // Only writes what differs, so an ordinary shell start touches nothing.
  function _write() {
    if (hyprlockFile.text() !== root._hyprlockText)
      hyprlockFile.setText(root._hyprlockText);

    if (alacrittyFile.text() !== root._alacrittyText)
      alacrittyFile.setText(root._alacrittyText);

    if (fuzzelFile.text() !== root._fuzzelText)
      fuzzelFile.setText(root._fuzzelText);

    if (hyprlandFile.text() === root._hyprlandText)
      return;

    hyprlandFile.setText(root._hyprlandText);
    _applyBorders.command = ["hyprctl", "eval", `hl.config({ general = { col = { active_border = { colors = { "${root._borders.accent}", "${root._borders.accentAlt}" }, angle = 45 }, inactive_border = "${root._borders.inactive}" } } })`];
    _applyBorders.running = true;
    Core.Logger.i("ThemeSync", `theme colours written for ${Config.Config.theme}`);
  }

  on_HyprlockTextChanged: Qt.callLater(root.sync)
  on_HyprlandTextChanged: Qt.callLater(root.sync)
  on_AlacrittyTextChanged: Qt.callLater(root.sync)
  on_FuzzelTextChanged: Qt.callLater(root.sync)
  on_GtkChanged: Qt.callLater(root._syncGtk)

  Connections {
    target: Config.Settings

    function onDirectoryReadyChanged() {
      root.sync();
    }
  }

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

  FileView {
    id: alacrittyFile
    path: root.alacrittyPath
    blockLoading: true
    printErrors: false
  }

  FileView {
    id: fuzzelFile
    path: root.fuzzelPath
    blockLoading: true
    printErrors: false
  }

  Core.Command {
    id: _applyGtk
    tag: "ThemeSync"
    label: "gsettings"
    command: ["sh", "-c", "s=org.gnome.desktop.interface; gsettings set $s color-scheme \"$1\" && gsettings set $s gtk-theme \"$2\" && gsettings set $s icon-theme \"$3\"", "sh"].concat(root._gtk)
  }

  Core.Command {
    id: _applyBorders
    tag: "ThemeSync"
    label: "hyprctl"
  }
}
