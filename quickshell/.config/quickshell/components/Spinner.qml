import QtQuick
import QtQuick.Shapes
import "../core" as Core

/**
* Spinner - something is in progress
*
* A short arc turning over a faint track, drawn rather than taken from the icon
* font. The font's loading glyph turned about its em box instead of its visual
* centre, so it wobbled, and at the 12-14px these sit at it was barely a shape.
*
* The turn runs on the render thread and only while the spinner is visible:
* any running animation keeps the window rendering at the refresh rate. With
* animations off the arc stays still, which still reads as busy.
*
* Usage:
*   Spinner { visible: busy; color: Core.Theme.accent }
*/
Item {
  id: root

  property real size: Core.Style.fontM
  property color color: Core.Theme.accent

  implicitWidth: root.size
  implicitHeight: root.size

  // Thick enough to read at 12px, thin enough to stay a ring at 24.
  readonly property real _stroke: Math.max(Core.Style.px(1.5), root.size / 7)
  readonly property real _radius: (root.size - root._stroke) / 2

  Shape {
    id: ring

    anchors.fill: parent
    // Analytic antialiasing: the default renderer left a stepped edge on a
    // circle this small.
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeColor: Core.Theme.alpha(root.color, 0.2)
      strokeWidth: root._stroke
      fillColor: Core.Theme.transparent

      PathAngleArc {
        centerX: root.size / 2
        centerY: root.size / 2
        radiusX: root._radius
        radiusY: root._radius
        startAngle: 0
        sweepAngle: 360
      }
    }

    ShapePath {
      strokeColor: root.color
      strokeWidth: root._stroke
      fillColor: Core.Theme.transparent
      capStyle: ShapePath.RoundCap

      PathAngleArc {
        centerX: root.size / 2
        centerY: root.size / 2
        radiusX: root._radius
        radiusY: root._radius
        startAngle: -90
        sweepAngle: 100
      }
    }

    RotationAnimator on rotation {
      running: root.visible && Core.Style.motionEnabled
      from: 0
      to: 360
      duration: Core.Style.spinDuration
      loops: Animation.Infinite
    }
  }
}
