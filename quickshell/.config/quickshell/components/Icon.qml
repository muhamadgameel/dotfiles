import QtQuick

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
  property int spinDuration: Core.Style.spinDuration

  // === Internal: Determine icon type ===
  readonly property bool _isFilePath: {
    const val = root.icon;
    return val.startsWith("/") || val.startsWith("file://") || val.startsWith("image://");
  }

  readonly property string _source: {
    // charCodeAt on "" is NaN, and NaN > 127 is false, so an empty icon used to
    // fall through to the registry and render its "?" placeholder.
    if (root.icon === "")
      return "";

    // A file path, or a direct glyph (non-ASCII, so a Nerd Font character)
    const firstChar = root.icon.charCodeAt(0);
    if (root._isFilePath || firstChar > 127) {
      return root.icon;
    }

    // Try to look up in Icons registry
    return Core.Icons.get(root.icon);
  }

  // === Dimensions ===
  implicitWidth: root._isFilePath ? (root.size + padding * 2) : (iconText.implicitWidth + padding * 2)
  implicitHeight: root._isFilePath ? (root.size + padding * 2) : (iconText.implicitHeight + padding * 2)

  // === Background ===
  Rectangle {
    id: background
    anchors.fill: parent
    color: Core.Theme.transparent
    radius: 0
    Behavior on color {
      ColorAnimation {
        duration: Core.Style.duration(Core.Style.animFast)
        easing.type: Core.Style.easeStandard
      }
    }
  }

  // === Image Display ===
  Image {
    id: iconImage
    visible: root._isFilePath && root._source !== ""
    source: root._isFilePath ? root._source : ""
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
    font.family: Core.Icons.fontFamily
    font.pixelSize: root.size
    color: Core.Theme.text
    anchors.centerIn: parent

    // Gated on visibility like the other looping animations: a running
    // animation keeps its window rendering at the refresh rate even when the
    // thing it moves is hidden.
    RotationAnimation on rotation {
      running: root.spinning && iconText.visible && Core.Style.motionEnabled
      from: 0
      to: 360
      duration: root.spinDuration
      loops: Animation.Infinite
    }

    Behavior on color {
      ColorAnimation {
        duration: Core.Style.duration(Core.Style.animFast)
        easing.type: Core.Style.easeStandard
      }
    }
  }
}
