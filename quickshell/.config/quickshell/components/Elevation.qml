pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects

import "../core" as Core

/**
* Elevation - drop shadow for a rounded surface
*
* Declare it as a sibling of the surface it lifts; it anchors itself to that
* surface and sits behind everything else in the parent.
*
*   Components.Elevation {
*     surface: card
*     level: 2
*     radius: card.radius
*   }
*   Rectangle { id: card; ... }
*
* Uses RectangularShadow, not MultiEffect. MultiEffect needs the source to be a
* texture provider (layer.enabled), which allocates an FBO the size of the
* surface and re-renders it plus a blur pass whenever *any* descendant changes -
* every hover, every stats tick, every slider drag. It also switches text to
* grayscale antialiasing, which shows at 12px. RectangularShadow is a single
* analytic quad: no source item, no texture, no layer, and its properties only
* change when geometry or the theme does.
*
* This Qt build's RectangularShadow has no `spread` or `cached` property - only
* offset, colour, blur and the corner radii - so there is no spread token.
*
* Two things to know:
*
* - The surface's window must leave Style.elevationRoom(level) px of transparent
*   space around it, or the shadow clips at the window edge.
* - It draws a *filled* rounded box, not a ring, so under a translucent surface
*   it tints through: the effective opacity is a + shadowAlpha * (1 - a). The
*   surface alphas are chosen with that already accounted for.
*/
Loader {
  id: root

  // The item to lift. Must share a parent with this Loader.
  required property Item surface

  // 0 disables. 1 tooltip, 2 bar and popups, 3 panels.
  property int level: 1

  property real radius: Core.Style.radiusL

  // Overridable so a bottom-anchored surface can throw its shadow upwards.
  property real offsetY: Core.Style.shadowOffsetY(root.level)

  property color shadowColor: Core.Theme.alpha(Core.Theme.shadow, Core.Style.shadowAlpha(root.level) * Core.Theme.shadowStrength)

  // A Loader rather than a plain item, so switching shadows off removes the
  // scene graph node entirely instead of drawing a transparent one.
  active: Core.Style.shadowsEnabled && root.level > 0

  anchors.fill: root.surface
  z: -1

  sourceComponent: RectangularShadow {
    blur: Core.Style.shadowBlur(root.level)
    offset: Qt.vector2d(0, root.offsetY)
    radius: root.radius
    color: root.shadowColor
  }
}
