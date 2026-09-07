pragma Singleton

import QtQuick
import Quickshell

/**
* Theme - the active colour palette, plus derived helpers
*
* Colours come from Themes.palettes, selected by Config.theme, so switching is
* `qs ipc call theme set catppuccin-latte` rather than editing this file.
*
* Every colour resolves through _pick(), which falls back to the default
* palette key by key - a palette missing a colour degrades to the default's
* rather than rendering transparent.
*/
Singleton {
  id: root

  // Active theme identifier
  readonly property string name: Themes.has(Config.theme) ? Config.theme : Themes.defaultName

  readonly property var palette: Themes.get(name)
  readonly property var fallback: Themes.get(Themes.defaultName)

  // Whether the active palette is a dark one, for anything that needs to know.
  readonly property bool isDark: palette.dark ?? true

  function _pick(key) {
    return palette[key] ?? fallback[key];
  }

  // === Base Colors ===
  readonly property color bg: _pick("bg")
  readonly property color bgAlt: _pick("bgAlt")
  readonly property color bgDark: _pick("bgDark")
  readonly property color surface: _pick("surface")
  readonly property color surfaceHover: _pick("surfaceHover")
  readonly property color surfaceActive: _pick("surfaceActive")

  // === Text Colors ===
  readonly property color text: _pick("text")
  readonly property color textDim: _pick("textDim")
  readonly property color textMuted: _pick("textMuted")

  // === Accent Colors ===
  readonly property color accent: _pick("accent")
  readonly property color accentAlt: _pick("accentAlt")
  readonly property color accentPink: _pick("accentPink")

  // === Semantic Colors ===
  readonly property color success: _pick("success")
  readonly property color warning: _pick("warning")
  readonly property color error: _pick("error")

  // === Overlay Colors ===
  readonly property color overlay: _pick("overlay")
  readonly property color overlayLight: _pick("overlayLight")
  readonly property color overlayLighter: _pick("overlayLighter")

  // === Absolute Colors ===
  readonly property color transparent: "transparent"
  readonly property color black: "#000000"
  readonly property color white: "#ffffff"

  // === Elevation ===
  // Shadow colour for raised surfaces. Derived from the palette so it reads
  // correctly on a light theme, where pure black is far too heavy.
  readonly property color shadow: isDark ? Qt.rgba(0, 0, 0, 0.45) : Qt.rgba(0, 0, 0, 0.15)

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
    if (urgency === Enums.Urgency.Critical)
      return error;
    if (urgency === Enums.Urgency.Normal)
      return accent;
    if (urgency === Enums.Urgency.Low)
      return textMuted;

    return transparent;
  }

  /**
  * Color for a "normal"/"warning"/"critical" status string.
  * @param normalColor - what "normal" should be; defaults to the accent.
  */
  function statusColor(status, normalColor) {
    if (status === "critical")
      return error;
    if (status === "warning")
      return warning;
    return normalColor !== undefined ? normalColor : accent;
  }
}
