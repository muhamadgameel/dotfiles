import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets

import "../../../components" as Components
import "../../../config" as Config
import "../../../core" as Core
import "../../../services" as Services

/**
* WindowTitle - the focused window's app icon and title
*/
Item {
  id: root

  readonly property var toplevel: Hyprland.activeToplevel

  readonly property string windowClass: toplevel?.lastIpcObject?.class ?? ""

  /**
  * Whether a window is really focused *here*.
  *
  * Hyprland.activeToplevel does not go null when you move to an empty workspace
  */
  readonly property bool hasWindow: {
    if (!root.toplevel)
      return false;
    const wsId = root.toplevel.workspace?.id ?? -1;
    const focused = Hyprland.focusedWorkspace?.id ?? -1;
    return wsId >= 0 && wsId === focused;
  }

  // Hyprland's toplevel carries a title but not an icon, so the desktop entry is
  // resolved by window class to get one.
  readonly property var entry: {
    const ready = DesktopEntries.applications.values.length;
    if (ready === 0 || root.windowClass === "")
      return null;
    return DesktopEntries.heuristicLookup(root.windowClass);
  }

  readonly property string appName: root.entry?.name ?? root.windowClass

  // Fall back through the class itself: plenty of apps name their icon after
  // their class even when no desktop entry matches.
  readonly property string iconPath: {
    const fromEntry = root.entry?.icon ? Quickshell.iconPath(root.entry.icon, true) : "";
    if (fromEntry !== "")
      return fromEntry;
    if (root.windowClass === "")
      return "";
    return Quickshell.iconPath(root.windowClass, true) || Quickshell.iconPath(root.windowClass.toLowerCase(), true) || "";
  }

  readonly property string rawTitle: root.toplevel?.title ?? ""

  readonly property string displayTitle: root._clean(root.rawTitle)

  /**
  * Drop the trailing "<separator><app name>" an app appends to its own title.
  */
  function _clean(title) {
    const trimmed = title.trim();
    if (trimmed === "")
      return "";

    const lower = trimmed.toLowerCase();
    const separators = [" - ", " — ", " – ", " · ", " | ", " :: "];

    // Longest first, so "Code - OSS" wins over a bare "code".
    const candidates = [];
    const entryName = root.entry?.name ?? "";
    if (entryName !== "")
      candidates.push(entryName);
    if (root.windowClass !== "")
      candidates.push(root.windowClass);
    if (candidates.length === 2 && candidates[1].length > candidates[0].length)
      candidates.reverse();

    for (const candidate of candidates) {
      const name = candidate.toLowerCase();

      // The title is just the app name - Alacritty does this. Nothing to strip,
      // and blanking it would leave the widget empty.
      if (lower === name)
        return trimmed;

      for (const separator of separators) {
        const suffix = separator + name;
        if (!lower.endsWith(suffix))
          continue;

        const stripped = trimmed.slice(0, lower.lastIndexOf(suffix)).trim();
        return stripped === "" ? trimmed : stripped;
      }
    }

    return trimmed;
  }

  // Bounded so a long title cannot push the rest of the bar around. Callers in
  // a layout should also set Layout.maximumWidth - see Bar.qml.
  readonly property int maxWidth: Core.Style.windowTitleMaxWidth

  readonly property bool hasContent: root.hasWindow && root.displayTitle !== ""

  implicitWidth: root.hasContent ? Math.min(row.implicitWidth, maxWidth) : 0
  implicitHeight: Core.Style.widgetSize

  Component.onDestruction: Services.Tooltip.forget(root)

  RowLayout {
    id: row

    visible: root.hasContent

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    spacing: Core.Style.spaceS

    // The slot keeps its width whether or not an icon resolved, so the title
    // does not shift sideways when one app has an icon and the next does not.
    Item {
      Layout.preferredWidth: Core.Style.iconSize
      Layout.preferredHeight: Core.Style.iconSize

      IconImage {
        anchors.fill: parent
        visible: root.iconPath !== ""
        source: root.iconPath
      }

      Components.Icon {
        anchors.centerIn: parent
        visible: root.iconPath === ""
        icon: "window"
        size: Core.Style.iconSize
        color: Config.Theme.textMuted
      }
    }

    Components.Text {
      Layout.fillWidth: true
      text: root.displayTitle
      size: Core.Style.fontS
      color: Config.Theme.textDim
      elide: Text.ElideRight
    }
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.hasContent
    hoverEnabled: root.hasContent

    onEntered: Services.Tooltip.show(root, root.appName === "" ? root.rawTitle : `${root.appName}\n${root.rawTitle}`, "bottom")
    onExited: Services.Tooltip.hide()
  }
}
