pragma Singleton

import QtQuick
import Quickshell

Singleton {
  id: root

  // UI Scale (can be made configurable later)
  readonly property real uiScale: 1.0

  // === Bar Dimensions ===
  readonly property int barHeight: Math.round(32 * uiScale)
  readonly property int barPadding: Math.round(8 * uiScale)

  // === Panel Dimensions ===
  readonly property int panelWidth: Math.round(360 * uiScale)
  readonly property int panelPadding: Math.round(16 * uiScale)

  // === Widget Dimensions ===
  readonly property int widgetSize: Math.round(28 * uiScale)
  readonly property int iconSize: Math.round(18 * uiScale)

  // === Font Sizes ===
  readonly property real fontXXS: 6 * uiScale
  readonly property real fontXS: 8 * uiScale
  readonly property real fontS: 10 * uiScale
  readonly property real fontM: 12 * uiScale
  readonly property real fontL: 14 * uiScale
  readonly property real fontXL: 18 * uiScale
  readonly property real fontXXL: 24 * uiScale

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

  // === OSD Dimensions ===
  readonly property int osdWidth: Math.round(280 * uiScale)
  readonly property int osdHeight: Math.round(56 * uiScale)
  readonly property int osdMargin: Math.round(24 * uiScale)
}
