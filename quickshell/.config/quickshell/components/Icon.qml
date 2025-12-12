import QtQuick

import "../config" as Config
import "../core" as Core

/**
* Icon - Renders a Nerd Font icon by name, direct glyph, or image file
*
* Usage:
*   // By name (recommended)
*   Icon { name: "bell" }
*
*   // Direct glyph (for custom/unlisted icons)
*   Icon { icon: "󰂚" }
*
*   // Image file path
*   Icon { source: "/path/to/icon.png" }
*
*   // With background padding
*   Icon { name: "bell"; padding: 8; backgroundColor: Theme.surface; radius: Style.radiusM }
*/
Item {
  id: root

  // Icon can be set directly (for Nerd Font glyphs) or by name
  property string icon: ""
  property string name: ""
  property string source: ""  // For image files (path or URL)
  property real size: Core.Style.fontL
  property alias color: iconText.color
  property alias backgroundColor: background.color
  property real padding: 0
  property alias radius: background.radius

  // Determine if we should show an image or text icon
  readonly property bool isImage: {
    if (root.source !== "")
      return true;
    // Check if name looks like a file path
    if (root.name.startsWith("/") || root.name.startsWith("file://") || root.name.startsWith("image://"))
      return true;
    return false;
  }

  readonly property string imagePath: {
    if (root.source !== "")
      return root.source;
    if (root.name.startsWith("/") || root.name.startsWith("file://") || root.name.startsWith("image://"))
      return root.name;
    return "";
  }

  implicitWidth: root.isImage ? (root.size + padding * 2) : (iconText.implicitWidth + padding * 2)
  implicitHeight: root.isImage ? (root.size + padding * 2) : (iconText.implicitHeight + padding * 2)

  Rectangle {
    id: background
    anchors.fill: parent
    color: Config.Theme.transparent
    radius: 0
  }

  // Image display for file-based icons
  Image {
    id: iconImage
    visible: root.isImage
    source: root.imagePath
    width: root.size
    height: root.size
    sourceSize.width: root.size * 2
    sourceSize.height: root.size * 2
    fillMode: Image.PreserveAspectFit
    anchors.centerIn: parent
    smooth: true
    asynchronous: true
  }

  // Text display for Nerd Font icons
  Text {
    id: iconText
    visible: !root.isImage

    text: {
      // First try direct icon property
      if (root.icon !== "")
        return root.icon;
      // Then try name mapping from Icons registry
      if (root.name !== "")
        return Config.Icons.get(root.name);
      return "";
    }

    font.family: Config.Icons.fontFamily
    font.pixelSize: root.size
    color: Config.Theme.text
    anchors.centerIn: parent
  }
}
