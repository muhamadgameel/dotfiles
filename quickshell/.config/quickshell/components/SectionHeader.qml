import QtQuick
import QtQuick.Layouts
import "../core" as Core

import "." as Components

/**
* SectionHeader - the heading above a group of rows in a panel
*
* Panels used to disagree with each other: the system monitor drew an icon and a
* large bold title, the sound panel drew bare bold text, and nothing else drew a
* heading at all. Same job, three looks.
*
* Set smaller than the rows it labels but in caps at full contrast, so it cannot
* be read as one more line of body text, with a leader rule carrying the eye out
* to the trailing figures.
*
* A section is a run of siblings in the panel's column, not a container, so the
* heading measures that run itself and brackets it with a rail in the panel's
* gutter. Spacing can say where a section begins; only the rail says where one
* ends, which is what a stack of cards needs. Both are drawn outside the layout,
* so the grouping costs no height.
*
* Optional trailing content goes in the default slot and is right-aligned, for
* the "3 active" / "Scanning..." style counters panels put beside a heading.
*
* Usage:
*   SectionHeader { title: "Output"; icon: "volume-high" }
*
*   SectionHeader {
*     title: "Applications"
*     Text { text: `${count} active`; color: Core.Theme.textDim }
*   }
*/
Item {
  id: root

  property string title: ""
  property string icon: ""
  property color iconColor: Core.Theme.accent

  // Trailing content, right-aligned on the same line as the title.
  default property alias trailing: trailingRow.data

  // Read off siblings by _extent below, which cannot import this type.
  readonly property bool isSectionHeader: true

  // Untyped on purpose: the parent is a ColumnLayout, which QQuickItem's own
  // type does not promise.
  readonly property var _column: root.parent
  readonly property real _columnSpacing: root._column?.spacing ?? 0

  // How far this section reaches: every sibling after it, up to the next
  // heading or a Divider.
  //
  // Math.max rather than taking the last child: a Repeater is appended after
  // the rows it created, at y 0 with no height, and would collapse the run to
  // nothing. The parent.height read is what keeps this live - children is a
  // list property and does not notify on its own.
  readonly property real _extent: {
    const siblings = root.parent?.children ?? [];
    const _ = root.parent?.height ?? 0;

    let end = root.y + root.height;
    let passedSelf = false;

    for (let i = 0; i < siblings.length; i++) {
      const sibling = siblings[i];
      if (sibling === root) {
        passedSelf = true;
        continue;
      }
      if (!passedSelf || !sibling.visible)
        continue;
      if (sibling.isSectionHeader === true || sibling.sectionBreak === true)
        break;

      end = Math.max(end, sibling.y + sibling.height);
    }

    return end - root.y;
  }

  Layout.fillWidth: true

  // The column's own spacing is subtracted out, so these are the gaps that
  // actually land - the one below is deliberately negative.
  Layout.topMargin: Core.Style.sectionGap - root._columnSpacing
  Layout.bottomMargin: Core.Style.sectionLabelGap - root._columnSpacing

  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight

  // Dimmed accent rather than a neutral hairline: the rail is the only thing
  // marking where a section ends, so it has to register as deliberate.
  readonly property color _railColor: Core.Theme.alpha(Core.Theme.accent, 0.35)

  // In the panel's gutter, outside this item's own bounds, so it adds no height.
  Item {
    x: -Core.Style.sectionRail
    width: Core.Style.borderThin
    height: root._extent

    // A rail around the heading alone is noise: the pinned headings in the
    // network and bluetooth panels label a list that lives in another column.
    visible: root._extent > root.height + Core.Style.spaceS

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      height: Math.max(0, parent.height - tail.height)
      color: root._railColor
    }

    // Fixed-length fade, rather than a gradient stop derived from the run: that
    // would rebuild the gradient on every frame of a collapsible's reveal.
    Rectangle {
      id: tail

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: Math.min(Core.Style.spaceXL, parent.height)

      gradient: Gradient {
        GradientStop {
          position: 0
          color: root._railColor
        }
        GradientStop {
          position: 1
          color: Core.Theme.transparentOf(root._railColor)
        }
      }
    }
  }

  RowLayout {
    id: row

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    spacing: Core.Style.spaceXS

    Components.Icon {
      visible: root.icon !== ""
      icon: root.icon
      size: Core.Style.fontM
      color: root.iconColor
    }

    Components.Text {
      text: root.title
      size: Core.Style.fontS
      weight: Core.Style.weightBold
      color: Core.Theme.text
      font.capitalization: Font.AllUppercase
      font.letterSpacing: Core.Style.letterSpacingWider
    }

    // Was a Spacer: same job, and it lands the trailing figures at the end of a
    // line instead of leaving them floating in the gap.
    Rectangle {
      Layout.fillWidth: true
      Layout.leftMargin: Core.Style.spaceXXS
      Layout.alignment: Qt.AlignVCenter
      Layout.preferredHeight: Core.Style.borderThin
      color: Core.Theme.surfaceHover
    }

    // Nested layouts fill by default, which would let an empty trailing slot
    // take half the slack and stop the leader rule halfway.
    RowLayout {
      id: trailingRow

      Layout.fillWidth: false
      spacing: Core.Style.spaceS
    }
  }
}
