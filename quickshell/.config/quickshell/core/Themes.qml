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
*
* `term` is the terminal's 16 ANSI colours: black, red, green, yellow, blue,
* magenta, cyan and white, then the bright eight in the same order.
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
        textMuted: "#9399b2",
        accent: "#cba6f7",
        accentAlt: "#89b4fa",
        success: "#a6e3a1",
        warning: "#f9e2af",
        error: "#f38ba8",
        overlay: "#6c7086",
        overlayLight: "#7f849c",
        selection: "#585b70",
        term: ["#45475a", "#f38ba8", "#a6e3a1", "#f9e2af", "#89b4fa", "#f5c2e7", "#94e2d5", "#bac2de", "#585b70", "#f38ba8", "#a6e3a1", "#f9e2af", "#89b4fa", "#f5c2e7", "#94e2d5", "#a6adc8"]
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
        textMuted: "#939ab7",
        accent: "#c6a0f6",
        accentAlt: "#8aadf4",
        success: "#a6da95",
        warning: "#eed49f",
        error: "#ed8796",
        overlay: "#6e738d",
        overlayLight: "#8087a2",
        selection: "#5b6078",
        term: ["#494d64", "#ed8796", "#a6da95", "#eed49f", "#8aadf4", "#f5bde6", "#8bd5ca", "#b8c0e0", "#5b6078", "#ed8796", "#a6da95", "#eed49f", "#8aadf4", "#f5bde6", "#8bd5ca", "#a5adcb"]
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
        textMuted: "#696c82",
        accent: "#8839ef",
        accentAlt: "#1e66f5",
        success: "#40a02b",
        warning: "#df8e1d",
        error: "#d20f39",
        overlay: "#9ca0b0",
        overlayLight: "#8c8fa1",
        selection: "#acb0be",
        term: ["#bcc0cc", "#d20f39", "#40a02b", "#df8e1d", "#1e66f5", "#ea76cb", "#179299", "#5c5f77", "#acb0be", "#d20f39", "#40a02b", "#df8e1d", "#1e66f5", "#ea76cb", "#179299", "#6c6f85"]
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
        textMuted: "#838ab2",
        accent: "#7aa2f7",
        accentAlt: "#bb9af7",
        success: "#9ece6a",
        warning: "#e0af68",
        error: "#f7768e",
        overlay: "#414868",
        overlayLight: "#565f89",
        selection: "#283457",
        term: ["#15161e", "#f7768e", "#9ece6a", "#e0af68", "#7aa2f7", "#bb9af7", "#7dcfff", "#a9b1d6", "#414868", "#ff899d", "#9fe044", "#faba4a", "#8db0ff", "#c7a9ff", "#a4daff", "#c0caf5"]
      },
      "tokyo-night-storm": {
        dark: true,
        bg: "#24283b",
        bgAlt: "#1f2335",
        bgDark: "#1a1b26",
        surface: "#343a55",
        surfaceHover: "#414868",
        surfaceActive: "#4d5578",
        text: "#c0caf5",
        textDim: "#a9b1d6",
        textMuted: "#8990b7",
        accent: "#7aa2f7",
        accentAlt: "#bb9af7",
        success: "#9ece6a",
        warning: "#e0af68",
        error: "#f7768e",
        overlay: "#414868",
        overlayLight: "#565f89",
        selection: "#2e3c64",
        term: ["#1d202f", "#f7768e", "#9ece6a", "#e0af68", "#7aa2f7", "#bb9af7", "#7dcfff", "#a9b1d6", "#414868", "#ff899d", "#9fe044", "#faba4a", "#8db0ff", "#c7a9ff", "#a4daff", "#c0caf5"]
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
