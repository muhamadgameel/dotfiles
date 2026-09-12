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
RowLayout {
  id: root

  property string title: ""
  property string icon: ""
  property color iconColor: Core.Theme.accent

  // Trailing content, right-aligned on the same line as the title.
  default property alias trailing: trailingRow.data

  Layout.fillWidth: true
  Layout.topMargin: Core.Style.spaceXS
  spacing: Core.Style.spaceS

  Components.Icon {
    visible: root.icon !== ""
    icon: root.icon
    size: Core.Style.fontL
    color: root.iconColor
  }

  Components.Text {
    text: root.title
    size: Core.Style.fontM
    weight: Core.Style.weightBold
    color: Core.Theme.textDim

    // Slight tracking: the heading is set smaller and dimmer than the rows it
    // labels, so it needs the extra separation to still read as a heading
    // rather than as quiet body text.
    font.letterSpacing: Core.Style.letterSpacingWide
  }

  Components.Spacer {}

  RowLayout {
    id: trailingRow
    spacing: Core.Style.spaceS
  }
}
