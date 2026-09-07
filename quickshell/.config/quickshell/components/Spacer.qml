import QtQuick
import QtQuick.Layouts

/**
* Spacer - layout spacing utility
*
* Two modes:
* - Flexible (default): eats the leftover space along one axis, pushing
*   siblings apart.
* - Fixed: a gap of exactly `size`.
*
* Usage:
*   // Push items apart in a row
*   RowLayout { Button {}; Spacer {}; Button {} }
*
*   // Push items apart in a column
*   ColumnLayout { Text {}; Spacer { vertical: true }; Text {} }
*
*   // Fixed gap
*   ColumnLayout { Text {}; Spacer { size: 20 }; Text {} }
*/
Item {
  id: root

  // === Properties ===
  property real size: 0            // Fixed gap; 0 means flexible
  property bool vertical: false    // Which axis a flexible spacer expands along

  readonly property bool flexible: size <= 0

  // === Layout Properties ===
  // Only ever one axis, so a spacer never distorts its parent's other axis.
  Layout.fillWidth: flexible && !vertical
  Layout.fillHeight: flexible && vertical

  // A fixed spacer sets both, so the same declaration works in a row or a
  // column - the layout uses whichever axis it flows along.
  Layout.preferredWidth: size > 0 ? size : -1
  Layout.preferredHeight: size > 0 ? size : -1

  // For non-Layout parents
  implicitWidth: size > 0 ? size : 0
  implicitHeight: size > 0 ? size : 0
}
