pragma Singleton

import QtQuick
import Quickshell

/**
* Themes - colour palettes
*
* Palettes only. Theme.qml picks one and adds the derived helpers, so switching
* is a settings change rather than an edit.
*
* Every palette must define the same keys; Theme falls back to the default one
* per-key, so a partial palette degrades instead of rendering transparent.
*/
Singleton {
  id: root

  readonly property string defaultName: "tokyo-night"

  readonly property var palettes: ({
      "catppuccin-mocha": {
        dark: true,
        bg: "#1e1e2e",
        bgAlt: "#181825",
        bgDark: "#11111b",
        surface: "#313244",
        surfaceHover: "#45475a",
        surfaceActive: "#585b70",
        text: "#cdd6f4",
        textDim: "#bac2de",
        textMuted: "#7f849c",
        accent: "#cba6f7",
        accentAlt: "#89b4fa",
        accentPink: "#f5c2e7",
        success: "#a6e3a1",
        warning: "#f9e2af",
        error: "#f38ba8",
        overlay: "#6c7086",
        overlayLight: "#7f849c",
        overlayLighter: "#9399b2"
      },
      "catppuccin-macchiato": {
        dark: true,
        bg: "#24273a",
        bgAlt: "#1e2030",
        bgDark: "#181926",
        surface: "#363a4f",
        surfaceHover: "#494d64",
        surfaceActive: "#5b6078",
        text: "#cad3f5",
        textDim: "#b8c0e0",
        textMuted: "#8087a2",
        accent: "#c6a0f6",
        accentAlt: "#8aadf4",
        accentPink: "#f5bde6",
        success: "#a6da95",
        warning: "#eed49f",
        error: "#ed8796",
        overlay: "#6e738d",
        overlayLight: "#8087a2",
        overlayLighter: "#939ab7"
      },
      "catppuccin-latte": {
        dark: false,
        bg: "#eff1f5",
        bgAlt: "#e6e9ef",
        bgDark: "#dce0e8",
        surface: "#ccd0da",
        surfaceHover: "#bcc0cc",
        surfaceActive: "#acb0be",
        text: "#4c4f69",
        textDim: "#5c5f77",
        textMuted: "#8c8fa1",
        accent: "#8839ef",
        accentAlt: "#1e66f5",
        accentPink: "#ea76cb",
        success: "#40a02b",
        warning: "#df8e1d",
        error: "#d20f39",
        overlay: "#9ca0b0",
        overlayLight: "#8c8fa1",
        overlayLighter: "#7c7f93"
      },
      // Tokyo Night, from folke/tokyonight.nvim. `night` is the darker of the
      // two; `storm` lifts the background without changing the accents.
      "tokyo-night": {
        dark: true,
        bg: "#1a1b26",
        bgAlt: "#16161e",
        bgDark: "#101014",
        surface: "#292e42",
        surfaceHover: "#3b4261",
        surfaceActive: "#414868",
        text: "#c0caf5",
        textDim: "#a9b1d6",
        textMuted: "#565f89",
        accent: "#7aa2f7",
        accentAlt: "#bb9af7",
        accentPink: "#ff007c",
        success: "#9ece6a",
        warning: "#e0af68",
        error: "#f7768e",
        overlay: "#414868",
        overlayLight: "#565f89",
        overlayLighter: "#737aa2"
      },
      "tokyo-night-storm": {
        dark: true,
        bg: "#24283b",
        bgAlt: "#1f2335",
        bgDark: "#1a1b26",
        surface: "#292e42",
        surfaceHover: "#3b4261",
        surfaceActive: "#414868",
        text: "#c0caf5",
        textDim: "#a9b1d6",
        textMuted: "#565f89",
        accent: "#7aa2f7",
        accentAlt: "#bb9af7",
        accentPink: "#ff007c",
        success: "#9ece6a",
        warning: "#e0af68",
        error: "#f7768e",
        overlay: "#414868",
        overlayLight: "#565f89",
        overlayLighter: "#737aa2"
      }
    })

  readonly property var names: Object.keys(palettes)

  function get(name) {
    return palettes[name] ?? palettes[defaultName];
  }

  function has(name) {
    return palettes[name] !== undefined;
  }
}
