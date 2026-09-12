pragma Singleton

import QtQuick
import Quickshell

import "../config" as Config

/**
* Style - design tokens
*
* Every dimension, duration and easing the shell uses is named here, so a
* change lands everywhere at once and no component invents its own spacing.
*
* Sizes derive from `uiScale`, which is persisted; durations go through
* duration(), which collapses to 0 when animations are switched off.
*/
Singleton {
  id: root

  // UI scale, persisted via Settings. Every dimension below derives from it,
  // so changing it rescales the whole shell.
  readonly property real uiScale: Config.Config.uiScale

  /**
  * A raw pixel size, scaled with the UI. For the one-off dimensions too specific
  * to earn a named token below - a toggle knob, a status dot, a hairline. Never
  * below 1, so a hairline cannot scale away.
  */
  function px(n) {
    return Math.max(1, Math.round(n * root.uiScale));
  }

  // === Bar Dimensions ===
  readonly property int barHeight: Math.round(32 * uiScale)
  readonly property int barPadding: Math.round(8 * uiScale)

  // === Panel Dimensions ===
  readonly property int panelWidth: Math.round(360 * uiScale)
  // For panels whose rows carry long text, like the notification centre.
  readonly property int panelWidthWide: Math.round(420 * uiScale)
  readonly property int panelPadding: Math.round(16 * uiScale)

  // === Widget Dimensions ===
  readonly property int widgetSize: Math.round(28 * uiScale)
  readonly property int iconSize: Math.round(18 * uiScale)

  // Widest the focused-window title may get before it elides.
  readonly property int windowTitleMaxWidth: Math.round(320 * uiScale)

  // === Control Dimensions ===
  readonly property int controlHeightS: Math.round(32 * uiScale)
  readonly property int controlHeightM: Math.round(40 * uiScale)
  readonly property int controlHeightL: Math.round(52 * uiScale)

  // === Progress Bars ===
  // Thickness by importance: L for a headline figure (CPU, RAM, disk), M for a
  // supporting one and the default, S for a dense breakdown (per-core).
  readonly property int progressHeightS: px(4)
  readonly property int progressHeightM: px(6)
  readonly property int progressHeightL: px(8)

  // === Empty States ===
  // The icon over an empty list. Large is for when the whole panel has nothing
  // to show - a radio switched off, no notifications - small for one section.
  readonly property int emptyIconSize: Math.round(32 * uiScale)
  readonly property int emptyIconSizeLarge: Math.round(48 * uiScale)

  // === Typography ===
  readonly property string fontFamily: Config.Config.fontFamily
  readonly property string fontMono: "JetBrainsMono Nerd Font"

  readonly property real letterSpacingWide: 0.6

  // === Font Sizes ===
  readonly property real fontXS: 8 * uiScale
  readonly property real fontS: 10 * uiScale
  readonly property real fontM: 12 * uiScale
  readonly property real fontL: 14 * uiScale
  readonly property real fontXL: 18 * uiScale
  readonly property real fontXXL: 24 * uiScale
  readonly property real fontXXXL: 32 * uiScale

  // === Font Weights ===
  readonly property int weightNormal: Font.Normal
  readonly property int weightMedium: Font.Medium
  readonly property int weightBold: Font.Bold

  // === Spacing & Margins ===
  readonly property int spaceXXS: Math.round(2 * uiScale)
  readonly property int spaceXS: Math.round(4 * uiScale)
  readonly property int spaceS: Math.round(8 * uiScale)
  readonly property int spaceM: Math.round(12 * uiScale)
  readonly property int spaceL: Math.round(16 * uiScale)
  readonly property int spaceXL: Math.round(24 * uiScale)
  readonly property int spaceXXL: Math.round(32 * uiScale)

  // === Border Radii ===
  readonly property int radiusS: Math.round(6 * uiScale)
  readonly property int radiusM: Math.round(10 * uiScale)
  readonly property int radiusL: Math.round(14 * uiScale)
  readonly property int radiusFull: 9999

  // === Border Widths ===
  readonly property int borderThin: 1

  // === State Layers ===
  // How strongly an interaction state tints the surface underneath it. Used via
  // Theme.stateLayer(), so hover on an accent button and hover on a card are
  // the same strength rather than each call site inventing a number.
  readonly property real opacityHover: 0.08
  readonly property real opacityPressed: 0.14
  readonly property real opacityDisabled: 0.4

  // A colour washed over a surface: light for a selected row or a hovered
  // destructive action, strong where the colour itself has to read - a badge,
  // a status banner, an armed power action.
  readonly property real opacityTint: 0.15
  readonly property real opacityTintStrong: 0.2

  // === Focus ===
  readonly property int focusRingWidth: Math.max(2, Math.round(2 * uiScale))
  readonly property int focusRingOffset: Math.max(2, Math.round(2 * uiScale))

  // === Elevation ===
  // How far a surface floats above the desktop: 1 a tooltip, 2 the bar and the
  // notification popups, 3 the panels and the OSD. Indexed by level so a caller
  // passes one number instead of picking three tokens apart.
  //
  // Note there is no `spread` token: this Qt build's RectangularShadow exposes
  // only offset/color/blur/radius (checked against plugins.qmltypes), so a
  // spread token would be a value nothing could consume.
  readonly property bool shadowsEnabled: Config.Config.shadowsEnabled

  readonly property var _shadowBlur: [0, 10, 18, 28]
  readonly property var _shadowOffsetY: [0, 2, 3, 6]
  readonly property var _shadowAlpha: [0, 0.22, 0.28, 0.34]

  function shadowBlur(level) {
    return Math.round((root._shadowBlur[level] ?? 0) * uiScale);
  }

  function shadowOffsetY(level) {
    return Math.round((root._shadowOffsetY[level] ?? 0) * uiScale);
  }

  function shadowAlpha(level) {
    return root._shadowAlpha[level] ?? 0;
  }

  /**
  * Transparent space a surface needs around it for its shadow to land in, px.
  *
  * A shadow draws outside the surface, so the *window* has to be bigger than
  * the surface or it clips at the window edge. Windows size themselves through
  * this rather than through a constant, so switching shadows off shrinks every
  * window back to exactly its old geometry instead of leaving dead margins.
  *
  * blur/2 because Qt's blur straddles the edge rather than extending from it.
  */
  function elevationRoom(level) {
    if (!root.shadowsEnabled || level <= 0)
      return 0;
    return Math.ceil(root.shadowBlur(level) / 2) + root.shadowOffsetY(level) + root.spaceXXS;
  }

  // === Animation Durations (ms) ===
  readonly property int animFaster: 75
  readonly property int animFast: 150
  readonly property int animNormal: 250
  readonly property int animSlow: 400

  // === Motion ===
  readonly property bool motionEnabled: Config.Config.animationsEnabled

  /**
  * Length of an animation, honouring the animations-off setting.
  *
  * Returns 0 rather than skipping the animation, so completion signals still
  * fire and nothing that waits on onFinished stalls.
  */
  function duration(ms) {
    return root.motionEnabled ? Math.round(ms) : 0;
  }

  // === Easing ===
  // Panels and other large surfaces settle without overshoot; overshoot is
  // reserved for small elements popping in, where it reads as liveliness
  // rather than as the layout wobbling.
  readonly property int easeStandard: Easing.OutCubic
  readonly property int easeEnter: Easing.OutBack
  readonly property int easeExit: Easing.InCubic
  readonly property real enterOvershoot: 1.1
  // Symmetric, for something that breathes in and out: StatusDot, WarningOverlay.
  readonly property int easePulse: Easing.InOutQuad

  // === Pop (small things appearing in place: tooltips, OSD) ===
  readonly property int popShowDuration: animFast
  readonly property int popHideDuration: animFaster
  readonly property real popHiddenScale: 0.85

  // === Slide (cards entering from an edge: notification popups) ===
  readonly property int slideShowDuration: animSlow
  readonly property int slideHideDuration: animNormal
  readonly property real slideHiddenScale: 0.8
  readonly property int slideDistance: Math.round(300 * uiScale)

  // Gap between consecutive cards in a stack, so they arrive in sequence.
  readonly property int slideStagger: 80

  // One turn of a spinner. Icon.qml and Spinner.qml each had their own 1000.
  readonly property int spinDuration: 1000

  // Stacking order for things that float over panel content (scrollbars,
  // overlays). ScrollArea was hardcoding `z: 100` in two places.
  readonly property int zOverlay: 100

  // === OSD Dimensions ===
  readonly property int osdWidth: Math.round(280 * uiScale)
  readonly property int osdHeight: Math.round(56 * uiScale)
  readonly property int osdMargin: Math.round(24 * uiScale)
}
