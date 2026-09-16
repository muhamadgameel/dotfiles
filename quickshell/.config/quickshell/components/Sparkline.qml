import QtQuick
import QtQuick.Shapes

import "../core" as Core

import "." as Components

/**
* Sparkline - recent history as one small line
*
* values are in their own units, oldest first, spread evenly across the width.
*
* The axis runs from 0 to the tallest reading, so height keeps meaning
* something, and minimumSpan stops a quiet window from being magnified into
* mountains. zoomToRange lifts the floor to the window's own low, for a
* reading that never approaches zero - memory sits at 40% of RAM all day, and
* against a 0-100% axis its changes are invisible.
*
* Usage:
*   Sparkline {
*       values: Services.SystemStats.cpuHistory
*       count: Services.SystemStats.historyLength
*       minimumSpan: 20               // percent, so idle stays flat
*       label: `peak ${Math.round(peak)}%`
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

  // === Scale ===
  property real scaleMax: 0        // 0 picks the window's own peak
  property bool zoomToRange: false
  property real minimumSpan: 0
  property string label: ""

  readonly property real peak: root.values.length > 0 ? Math.max(...root.values) : 0
  readonly property real low: root.values.length > 0 ? Math.min(...root.values) : 0

  readonly property real axisMin: {
    if (!root.zoomToRange)
      return 0;
    if (root.peak - root.low >= root.minimumSpan)
      return root.low;
    return Math.max(0, (root.peak + root.low - root.minimumSpan) / 2);
  }

  readonly property real axisMax: {
    if (root.scaleMax > 0)
      return root.scaleMax;
    return Math.max(root.peak, root.axisMin + root.minimumSpan);
  }

  implicitHeight: Core.Style.sparklineHeight

  readonly property var _points: {
    const total = Math.max(root.count, root.values.length);
    if (root.values.length < 2 || root.width <= 0 || total < 2)
      return [];

    // Inset by the stroke so the line is not clipped at either end of the axis.
    const top = root.strokeWidth / 2;
    const span = Math.max(0, root.height - root.strokeWidth);
    const step = root.width / (total - 1);
    const range = Math.max(root.axisMax - root.axisMin, 1e-9);

    return root.values.map((value, i) => {
      const scaled = Math.max(0, Math.min(1, (value - root.axisMin) / range));
      return Qt.point(i * step, top + (1 - scaled) * span);
    });
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

  // What the top of the axis means, since it moves with the readings.
  Components.Text {
    anchors.right: parent.right
    anchors.top: parent.top
    visible: root.label !== ""
    text: root.label
    size: Core.Style.fontXS
    color: Core.Theme.textMuted
  }
}
