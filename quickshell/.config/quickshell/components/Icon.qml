import QtQuick

import "../config" as Config
import "../core" as Core

/**
* Icon - Renders a Nerd Font icon by name, direct glyph, or image file
*
* The `icon` property accepts:
* - Icon names from the Icons registry (e.g., "bell", "settings")
* - Direct Nerd Font glyphs (e.g., "󰂚")
* - File paths are detected and rendered as images
*
* Usage:
*   // By name (recommended)
*   Icon { icon: "bell" }
*
*   // Direct glyph (for custom/unlisted icons)
*   Icon { icon: "󰂚" }
*
*   // Image file path
*   Icon { icon: "/path/to/icon.png" }
*
*   // With background padding
*   Icon { icon: "bell"; padding: 8; backgroundColor: Theme.surface; radius: Style.radiusM }
*
*   // With spinning animation (for loading states)
*   Icon { icon: "refresh"; spinning: true }
*/
Item {
  id: root

  // === Icon Property (primary) ===
  // Accepts: icon name, direct glyph, or file path
  property string icon: ""

  // === Styling ===
  property real size: Core.Style.fontL
  property alias color: iconText.color
  property alias backgroundColor: background.color
  property real padding: 0
  property alias radius: background.radius

  // === Animation ===
  property bool spinning: false
  property int spinDuration: 1000

  // === Internal: Determine icon type ===
  readonly property bool _isFilePath: {
    const val = root.icon;
    return val.startsWith("/") || val.startsWith("file://") || val.startsWith("image://");
  }

  readonly property string _source: {
    // if it's a file path or a direct glyph (non-ASCII, likely a Nerd Font character) return the icon
    const firstChar = root.icon.charCodeAt(0);
    if (root._isFilePath || firstChar > 127) {
      return root.icon;
    }

    // Try to look up in Icons registry
    return Config.Icons.get(root.icon);
  }

  // === Dimensions ===
  implicitWidth: root._isFilePath ? (root.size + padding * 2) : (iconText.implicitWidth + padding * 2)
  implicitHeight: root._isFilePath ? (root.size + padding * 2) : (iconText.implicitHeight + padding * 2)

  // === Background ===
  Rectangle {
    id: background
    anchors.fill: parent
    color: Config.Theme.transparent
    radius: 0
  }

  // === Image Display ===
  Image {
    id: iconImage
    visible: root._isFilePath && root._source !== ""
    source: root._source
    width: root.size
    height: root.size
    sourceSize.width: root.size * 2
    sourceSize.height: root.size * 2
    fillMode: Image.PreserveAspectFit
    anchors.centerIn: parent
    smooth: true
    asynchronous: true
  }

  // === Text Display (Nerd Font icons) ===
  Text {
    id: iconText
    visible: !root._isFilePath && root._source !== ""
    text: root._source
    font.family: Config.Icons.fontFamily
    font.pixelSize: root.size
    color: Config.Theme.text
    anchors.centerIn: parent

    RotationAnimation on rotation {
      running: root.spinning
      from: 0
      to: 360
      duration: root.spinDuration
      loops: Animation.Infinite
    }
  }
}
