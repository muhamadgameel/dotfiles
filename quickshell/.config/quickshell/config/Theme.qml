pragma Singleton

import QtQuick
import Quickshell
import "../types" as Types

Singleton {
  id: root

  // Theme identifier
  readonly property string name: "catppuccin-mocha"

  // === Base Colors ===
  readonly property color bg: "#1e1e2e"
  readonly property color bgAlt: "#181825"
  readonly property color bgDark: "#11111b"
  readonly property color surface: "#313244"
  readonly property color surfaceHover: "#45475a"
  readonly property color surfaceActive: "#585b70"

  // === Text Colors ===
  readonly property color text: "#cdd6f4"
  readonly property color textDim: "#bac2de"
  readonly property color textMuted: "#7f849c"

  // === Accent Colors ===
  readonly property color accent: "#cba6f7"
  readonly property color accentAlt: "#89b4fa"
  readonly property color accentPink: "#f5c2e7"

  // === Semantic Colors ===
  readonly property color success: "#a6e3a1"
  readonly property color warning: "#f9e2af"
  readonly property color error: "#f38ba8"

  // === Overlay Colors ===
  readonly property color overlay: "#6c7086"
  readonly property color overlayLight: "#7f849c"
  readonly property color overlayLighter: "#9399b2"

  // === Absolute Colors ===
  readonly property color transparent: "transparent"
  readonly property color black: "#000000"
  readonly property color white: "#ffffff"

  // === Helper Functions ===

  // Create a color with alpha transparency
  function alpha(baseColor, a) {
    return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, a);
  }

  // Lighten a color
  function lighten(baseColor, amount) {
    return Qt.lighter(baseColor, 1 + amount);
  }

  // Darken a color
  function darken(baseColor, amount) {
    return Qt.darker(baseColor, 1 + amount);
  }

  /**
  * Get color based on notification urgency level
  * @param urgency - Urgency level (0=low, 1=normal, 2=critical)
  * @returns Color for the urgency level
  */
  function urgencyColor(urgency) {
    if (urgency === Types.Enums.Urgency.Critical)
      return error;
    if (urgency === Types.Enums.Urgency.Normal)
      return accent;
    if (urgency === Types.Enums.Urgency.Low)
      return textMuted;

    return transparent;
  }
}
