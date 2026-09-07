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

  // === Bar Dimensions ===
  readonly property int barHeight: Math.round(32 * uiScale)
  readonly property int barPadding: Math.round(8 * uiScale)

  // === Panel Dimensions ===
  readonly property int panelWidth: Math.round(360 * uiScale)
  readonly property int panelPadding: Math.round(16 * uiScale)

  // === Widget Dimensions ===
  readonly property int widgetSize: Math.round(28 * uiScale)
  readonly property int iconSize: Math.round(18 * uiScale)

  // Widest the focused-window title may get before it elides.
  readonly property int windowTitleMaxWidth: Math.round(320 * uiScale)

  // === Font Sizes ===
  readonly property real fontXXS: 6 * uiScale
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

  // === Border Widths ===
  readonly property int borderThin: 1
  readonly property int borderMedium: 2

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

  // === OSD Dimensions ===
  readonly property int osdWidth: Math.round(280 * uiScale)
  readonly property int osdHeight: Math.round(56 * uiScale)
  readonly property int osdMargin: Math.round(24 * uiScale)
}
