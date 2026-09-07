import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets

import "../../../components" as Components
import "../../../config" as Config
import "../../../core" as Core

/**
* WindowTitle - the focused window's app icon and title
*/
Item {
  id: root

  readonly property var toplevel: Hyprland.activeToplevel
  readonly property string title: toplevel?.title ?? ""

  // Hyprland's toplevel carries a title but not an icon, so resolve the desktop
  // entry by the window class to get one.
  readonly property var entry: {
    const cls = toplevel?.lastIpcObject?.class ?? "";
    return cls === "" ? null : DesktopEntries.heuristicLookup(cls);
  }

  // Bounded so a long title cannot push the rest of the bar around. Callers in
  // a layout should also set Layout.maximumWidth - see Bar.qml.
  readonly property int maxWidth: Core.Style.windowTitleMaxWidth

  visible: title !== ""
  implicitWidth: visible ? Math.min(row.implicitWidth, maxWidth) : 0
  implicitHeight: Core.Style.widgetSize

  RowLayout {
    id: row

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    spacing: Core.Style.spaceS

    IconImage {
      visible: root.entry?.icon ?? false
      implicitSize: Core.Style.iconSize
      source: root.entry?.icon ? Quickshell.iconPath(root.entry.icon, true) : ""
    }

    Components.Text {
      Layout.fillWidth: true
      text: root.title
      size: Core.Style.fontS
      color: Config.Theme.textDim
      elide: Text.ElideRight
    }
  }
}
