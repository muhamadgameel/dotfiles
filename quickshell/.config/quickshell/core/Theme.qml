pragma Singleton

import QtQuick
import Quickshell

import "../config" as Config

/**
* Theme - the active colour palette, plus derived helpers
*
* Colours come from Themes.palettes, selected by Config.Config.theme, so switching is
* `qs ipc call theme set catppuccin-latte` rather than editing this file.
*
* Every colour resolves through _pick(), which falls back to the default
* palette key by key - a palette missing a colour degrades to the default's
* rather than rendering transparent.
*/
Singleton {
  id: root

  // Active theme identifier
  readonly property string name: Themes.has(Config.Config.theme) ? Config.Config.theme : Themes.defaultName

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
  // Shadows are black; *how much* of it lands is Style.shadowAlpha(level).
  // Splitting it that way means one strength curve serves every palette, scaled
  // by this so a light theme does not get a bruise under every panel.
  readonly property color shadow: root.black
  readonly property real shadowStrength: isDark ? 1.0 : 0.45

  // === Surfaces ===
  // Opacity follows what sits behind a surface, not a fixed offset between them:
  //
  // - panelBg is over windows (panels, the OSD), so it carries text across busy
  //   content and needs to be nearly opaque. Config.Config.surfaceOpacity, 0.96.
  // - barBg is only ever over the wallpaper, so it can be more see-through.
  //   Config.Config.barOpacity, 0.85.
  //
  // Do not count on the compositor's blur for legibility. Measured over a tiled
  // window, text behind a panel came through exactly as sharp as the original,
  // only dimmed - so at the old 0.90 it was plainly readable. At 0.96 the
  // background stops being legible whether or not blur is applied.
  //
  // Used to be three values derived by +/-0.05 from one setting, one of which
  // (popupBg) nothing read.
  readonly property color panelBg: alpha(bg, Config.Config.surfaceOpacity)
  readonly property color barBg: alpha(bg, Config.Config.barOpacity)

  // === Focus ===
  readonly property color focusRing: accent

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
  * Tint a surface to show an interaction state.
  *
  * @param baseColor - the surface being tinted
  * @param strength - 0..1, from the Style opacity tokens
  * @param tint - what to tint with; defaults to the palette's foreground
  */
  function stateLayer(baseColor, strength, tint) {
    if (!(strength > 0))
      return baseColor;

    const over = tint !== undefined ? tint : (isDark ? white : black);
    return Qt.rgba(baseColor.r + (over.r - baseColor.r) * strength, baseColor.g + (over.g - baseColor.g) * strength, baseColor.b + (over.b - baseColor.b) * strength, baseColor.a);
  }

  /**
  * The same colour at zero alpha.
  *
  * Animating a colour to or from `transparent` runs the RGB channels down to
  * black on the way, which shows as a dark flash mid-fade. Fading to the same
  * hue at alpha 0 keeps the channels put. Card and Button each carried their
  * own copy of this workaround.
  */
  function transparentOf(baseColor) {
    return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, 0);
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
