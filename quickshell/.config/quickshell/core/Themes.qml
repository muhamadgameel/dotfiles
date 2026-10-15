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
      },
      // Gruvbox dark, from morhetz/gruvbox, yellow as the accent. bgDark is darker
      // than its palette goes.
      "gruvbox": {
        dark: true,
        bg: "#282828",
        bgAlt: "#1d2021",
        bgDark: "#141617",
        surface: "#3c3836",
        surfaceHover: "#504945",
        surfaceActive: "#665c54",
        text: "#ebdbb2",
        textDim: "#d5c4a1",
        textMuted: "#a89984",
        accent: "#fabd2f",
        accentAlt: "#83a598",
        success: "#b8bb26",
        warning: "#fe8019",
        error: "#fb4934",
        overlay: "#665c54",
        overlayLight: "#928374",
        selection: "#504945",
        term: ["#282828", "#cc241d", "#98971a", "#d79921", "#458588", "#b16286", "#689d6a", "#a89984", "#928374", "#fb4934", "#b8bb26", "#fabd2f", "#83a598", "#d3869b", "#8ec07c", "#ebdbb2"]
      },
      // Nord, from nordtheme.com. Its darkest is nord0, so bgAlt and bgDark go below
      // it, and textMuted is its comment grey lifted to 4.5:1.
      "nord": {
        dark: true,
        bg: "#2e3440",
        bgAlt: "#292e39",
        bgDark: "#242933",
        surface: "#3b4252",
        surfaceHover: "#434c5e",
        surfaceActive: "#4c566a",
        text: "#eceff4",
        textDim: "#d8dee9",
        textMuted: "#929cb0",
        accent: "#88c0d0",
        accentAlt: "#b48ead",
        success: "#a3be8c",
        warning: "#ebcb8b",
        error: "#bf616a",
        overlay: "#4c566a",
        overlayLight: "#616e88",
        selection: "#434c5e",
        term: ["#3b4252", "#bf616a", "#a3be8c", "#ebcb8b", "#81a1c1", "#b48ead", "#88c0d0", "#e5e9f0", "#4c566a", "#bf616a", "#a3be8c", "#ebcb8b", "#81a1c1", "#b48ead", "#8fbcbb", "#eceff4"]
      },
      // Everforest dark medium, from sainnhe/everforest. textDim sits between its
      // foreground and grey2, which it has nothing in between.
      "everforest": {
        dark: true,
        bg: "#2d353b",
        bgAlt: "#232a2e",
        bgDark: "#1e2326",
        surface: "#343f44",
        surfaceHover: "#3d484d",
        surfaceActive: "#475258",
        text: "#d3c6aa",
        textDim: "#b8b8a5",
        textMuted: "#9da9a0",
        accent: "#a7c080",
        accentAlt: "#7fbbb3",
        success: "#83c092",
        warning: "#dbbc7f",
        error: "#e67e80",
        overlay: "#475258",
        overlayLight: "#7a8478",
        selection: "#543a48",
        term: ["#475258", "#e67e80", "#a7c080", "#dbbc7f", "#7fbbb3", "#d699b6", "#83c092", "#d3c6aa", "#859289", "#e67e80", "#a7c080", "#dbbc7f", "#7fbbb3", "#d699b6", "#83c092", "#d3c6aa"]
      },
      // Rosé Pine, from rose-pine/neovim. surface is its overlay, since its surface
      // barely shows on the base; textDim sits between text and subtle, and bgDark
      // is darker than its palette goes.
      "rose-pine": {
        dark: true,
        bg: "#191724",
        bgAlt: "#16141f",
        bgDark: "#12101a",
        surface: "#26233a",
        surfaceHover: "#403d52",
        surfaceActive: "#524f67",
        text: "#e0def4",
        textDim: "#b8b5d0",
        textMuted: "#908caa",
        accent: "#c4a7e7",
        accentAlt: "#ebbcba",
        success: "#9ccfd8",
        warning: "#f6c177",
        error: "#eb6f92",
        overlay: "#403d52",
        overlayLight: "#6e6a86",
        selection: "#403d52",
        term: ["#26233a", "#eb6f92", "#31748f", "#f6c177", "#9ccfd8", "#c4a7e7", "#ebbcba", "#e0def4", "#6e6a86", "#eb6f92", "#31748f", "#f6c177", "#9ccfd8", "#c4a7e7", "#ebbcba", "#e0def4"]
      },
      // Kanagawa wave, as in Neovim, from rebelot/kanagawa.nvim and its Alacritty
      // colours.
      "kanagawa": {
        dark: true,
        bg: "#1f1f28",
        bgAlt: "#1a1a22",
        bgDark: "#16161d",
        surface: "#2a2a37",
        surfaceHover: "#363646",
        surfaceActive: "#54546d",
        text: "#dcd7ba",
        textDim: "#c8c093",
        textMuted: "#938aa9",
        accent: "#7e9cd8",
        accentAlt: "#957fb8",
        success: "#98bb6c",
        warning: "#e6c384",
        error: "#e46876",
        overlay: "#54546d",
        overlayLight: "#727169",
        selection: "#2d4f67",
        term: ["#090618", "#c34043", "#76946a", "#c0a36e", "#7e9cd8", "#957fb8", "#6a9589", "#c8c093", "#727169", "#e82424", "#98bb6c", "#e6c384", "#7fb4ca", "#938aa9", "#7aa89f", "#dcd7ba"]
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
