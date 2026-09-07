pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

import "../../../components" as Components
import "../../../config" as Config
import "../../../core" as Core
import "../../ipc" as Ipc

/**
* Workspaces - Hyprland workspace switcher
*
* Shows only the workspaces that exist on this monitor, plus the focused one -
* Hyprland keeps a workspace alive exactly while it has windows or focus, so
* this is "the workspaces you are actually using".
*
* Set `workspaceShowEmpty` to render a fixed row of `workspaceCount` slots
* instead, which never reflows and lets you click through to an empty
* workspace, at the cost of permanent clutter.
*
* Filtered to this bar's own monitor either way. Previously every bar showed
* every monitor's workspaces, so an external display's workspaces appeared on
* the laptop bar too.
*
* - Click:        switch to the workspace
* - Middle click: move the focused window there
*/
Item {
  id: root

  // The screen this bar belongs to; set by Bar.qml.
  property var screen: null

  implicitWidth: slots.implicitWidth
  implicitHeight: Core.Style.widgetSize

  readonly property string monitorName: screen?.name ?? ""

  readonly property bool showEmpty: Config.Config.workspaceShowEmpty

  // Workspaces that live on this monitor, by id.
  readonly property var localWorkspaces: {
    const map = ({});
    for (const ws of Hyprland.workspaces.values) {
      if (!ws || ws.id <= 0)
        continue;  // special/scratchpad workspaces have negative ids
      if (root.monitorName !== "" && ws.monitor?.name !== root.monitorName)
        continue;
      map[ws.id] = ws;
    }
    return map;
  }

  readonly property int focusedId: Hyprland.focusedWorkspace?.id ?? -1

  /**
  * The ids to render, in ascending order.
  */
  readonly property var visibleIds: {
    const ids = [];

    if (root.showEmpty) {
      let highest = Config.Config.workspaceCount;
      for (const key in root.localWorkspaces)
        highest = Math.max(highest, parseInt(key, 10));
      for (let id = 1; id <= highest; id++)
        ids.push(id);
      return ids;
    }

    for (const key in root.localWorkspaces)
      ids.push(parseInt(key, 10));

    if (root.focusedId > 0 && !ids.includes(root.focusedId))
      ids.push(root.focusedId);

    ids.sort((a, b) => a - b);
    return ids;
  }

  // Dispatch dialect (Lua vs classic string) is handled in Ipc.Targets, so the
  // bar and `qs ipc call workspace focus` go through exactly one code path.
  function _focusWorkspace(id) {
    Ipc.Targets.focusWorkspace(id);
  }

  function _moveToWorkspace(id) {
    Ipc.Targets.moveToWorkspace(id);
  }

  Row {
    id: slots

    anchors.verticalCenter: parent.verticalCenter
    spacing: Core.Style.spaceS

    Repeater {
      model: root.visibleIds

      delegate: Components.Card {
        id: slot

        required property int modelData

        readonly property int workspaceId: modelData
        readonly property var workspace: root.localWorkspaces[workspaceId] ?? null
        readonly property bool occupied: (workspace?.toplevels?.values?.length ?? 0) > 0
        readonly property bool isFocused: root.focusedId === workspaceId
        readonly property bool isUrgent: workspace?.urgent ?? false

        width: Core.Style.widgetSize
        height: Core.Style.widgetSize

        interactive: true

        backgroundColor: {
          if (isFocused)
            return Config.Theme.accent;
          if (isUrgent)
            return Config.Theme.error;
          // Occupied but unfocused reads as "there is something here".
          return occupied ? Config.Theme.surface : Config.Theme.transparent;
        }

        hoverColor: isFocused ? Config.Theme.accent : (isUrgent ? Config.Theme.error : Config.Theme.surfaceHover)

        onClicked: button => {
          if (button === Qt.MiddleButton)
            root._moveToWorkspace(slot.workspaceId);
          else
            root._focusWorkspace(slot.workspaceId);
        }

        Components.Text {
          anchors.centerIn: parent
          text: slot.workspaceId
          color: {
            if (slot.isFocused)
              return Config.Theme.bg;
            // Empty slots are dimmed so the occupied ones stand out.
            return slot.occupied ? Config.Theme.text : Config.Theme.textMuted;
          }
          weight: slot.isFocused ? Core.Style.weightBold : Core.Style.weightMedium
        }

        // Window-count dot: one per window, capped so it stays legible.
        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 2
          spacing: 2
          visible: slot.occupied && !slot.isFocused

          Repeater {
            model: Math.min(3, slot.workspace?.toplevels?.values?.length ?? 0)

            delegate: Rectangle {
              width: 3
              height: 3
              radius: 1.5
              color: Config.Theme.textMuted
            }
          }
        }
      }
    }
  }
}
