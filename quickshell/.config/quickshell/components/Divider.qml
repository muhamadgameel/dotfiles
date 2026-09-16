import QtQuick
import QtQuick.Layouts

import "../core" as Core

/**
* Divider - one-pixel separator line
*
* Usage:
*   Divider {}                  // horizontal, fills the layout width
*   Divider { vertical: true }  // vertical, fills the layout height
*/
Rectangle {
  id: root

  property bool vertical: false

  // Ends a section for SectionHeader's rail, so it does not run past a rule
  // that already separates what follows.
  readonly property bool sectionBreak: true

  // Only the thickness is intrinsic. Taking the long axis from `parent` broke
  // inside layouts, where the parent sizes itself from its children - a
  // divider asking for its parent's width fed that width straight back in.
  implicitWidth: vertical ? Core.Style.borderThin : 0
  implicitHeight: vertical ? 0 : Core.Style.borderThin

  // Fill the axis the line runs along, so callers in a layout get a full-width
  // (or full-height) rule without repeating this every time. Still overridable,
  // and ignored outside a layout where anchors apply instead.
  Layout.fillWidth: !vertical
  Layout.fillHeight: vertical

  color: Core.Theme.surfaceHover
}
