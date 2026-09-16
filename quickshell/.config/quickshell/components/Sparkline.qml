import QtQuick
import QtQuick.Shapes

import "../core" as Core

/**
* Sparkline - recent history as one small line
*
* values are 0..1, oldest first, and are spread evenly across the width. A
* series shorter than the one beside it is drawn at the same scale by padding
* it: pass the same `count` to every sparkline that shares a time span.
*
* Usage:
*   Sparkline {
*       Layout.fillWidth: true
*       values: Services.SystemStats.cpuHistory
*       count: Services.SystemStats.historyLength
*   }
*/
Item {
  id: root

  property var values: []
  // Points the width is divided into, so a half-filled buffer draws from the
  // left rather than stretching a few readings across the whole panel.
  property int count: root.values.length
  property color color: Core.Theme.accent
  property real strokeWidth: Core.Style.px(1.5)
  property real fillOpacity: 0.18

  implicitHeight: Core.Style.sparklineHeight

  readonly property var _points: {
    const total = Math.max(root.count, root.values.length);
    if (root.values.length < 2 || root.width <= 0 || total < 2)
      return [];

    // Inset by the stroke so the line is not clipped at 0% or 100%.
    const top = root.strokeWidth / 2;
    const span = Math.max(0, root.height - root.strokeWidth);
    const step = root.width / (total - 1);

    return root.values.map((value, i) => Qt.point(i * step, top + (1 - Math.max(0, Math.min(1, value))) * span));
  }

  readonly property var _filled: {
    if (root._points.length < 2)
      return [];
    const last = root._points[root._points.length - 1];
    const first = root._points[0];
    return root._points.concat([Qt.point(last.x, root.height), Qt.point(first.x, root.height), first]);
  }

  // A floor for the line to sit on: without it a trace near zero reads as a
  // stray stroke rather than a graph.
  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: Core.Style.borderThin
    color: Core.Theme.alpha(root.color, 0.25)
  }

  Shape {
    anchors.fill: parent

    ShapePath {
      strokeColor: Core.Theme.transparent
      fillColor: Core.Theme.alpha(root.color, root.fillOpacity)

      PathPolyline {
        path: root._filled
      }
    }

    ShapePath {
      strokeColor: root.color
      strokeWidth: root.strokeWidth
      fillColor: Core.Theme.transparent
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin

      PathPolyline {
        path: root._points
      }
    }
  }
}
