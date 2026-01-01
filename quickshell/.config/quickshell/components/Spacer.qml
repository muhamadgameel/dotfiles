import QtQuick
import QtQuick.Layouts

/**
* Spacer - Layout spacing utility
*
* A flexible spacer for use in Row/Column/RowLayout/ColumnLayout.
* Can be fixed size or fill available space.
*
* Usage:
*   // Fill remaining space (pushes items apart)
*   RowLayout {
*       Button { text: "Left" }
*       Spacer {}
*       Button { text: "Right" }
*   }
*
*   // Fixed size spacer
*   Column {
*       Text { text: "Above" }
*       Spacer { size: 20 }
*       Text { text: "Below" }
*   }
*
*   // Minimum size with fill
*   RowLayout {
*       Spacer { size: 10; fill: true }
*   }
*/
Item {
  id: root

  // === Properties ===
  property real size: 0  // Fixed size (0 = use fill behavior)
  property bool fill: size === 0  // Fill available space

  // === Layout Properties ===
  Layout.fillWidth: fill
  Layout.fillHeight: fill
  Layout.preferredWidth: size > 0 ? size : -1
  Layout.preferredHeight: size > 0 ? size : -1

  // For non-Layout parents
  implicitWidth: size > 0 ? size : 0
  implicitHeight: size > 0 ? size : 0
}
