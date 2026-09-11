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

  // === Slot model ===
  // Syncing a ListModel in place keeps the untouched slots alive, so only the
  // workspace that genuinely appeared animates.
  ListModel {
    id: slotModel
  }

  // Removal is immediate, deliberately. Holding a departed slot back for a
  // fade-out animation meant it kept its full width - opacity and scale are
  // transforms, not layout - so switching quickly through empty workspaces piled
  // up invisible slots and shoved the rest of the bar sideways
  function _syncSlots() {
    const ids = root.visibleIds;

    for (let i = slotModel.count - 1; i >= 0; i--) {
      if (!ids.includes(slotModel.get(i).wsId))
        slotModel.remove(i);
    }

    // What is left is a subsequence of ids in the same ascending order, so one
    // forward pass drops the new ones into the right places.
    for (let k = 0; k < ids.length; k++) {
      if (k >= slotModel.count)
        slotModel.append({
          wsId: ids[k]
        });
      else if (slotModel.get(k).wsId !== ids[k])
        slotModel.insert(k, {
          wsId: ids[k]
        });
    }
  }

  onVisibleIdsChanged: root._syncSlots()
  Component.onCompleted: root._syncSlots()

  // Dispatch dialect (Lua vs classic string) is handled in Ipc.Targets, so the
  // bar and `qs ipc call workspace focus` go through exactly one code path.
  function _focusWorkspace(id) {
    Ipc.Targets.focusWorkspace(id);
  }

  function _moveToWorkspace(id) {
    Ipc.Targets.moveToWorkspace(id);
  }

  // The row's width changes when a slot appears or goes; without this every
  // widget to the right of it jumps sideways in one frame.
  Behavior on implicitWidth {
    NumberAnimation {
      duration: Core.Style.duration(Core.Style.animFast)
      easing.type: Core.Style.easeStandard
    }
  }

  Row {
    id: slots

    anchors.verticalCenter: parent.verticalCenter
    spacing: Core.Style.spaceS

    // Slots that shift because a neighbour arrived or left slide across instead
    // of teleporting to their new position.
    move: Transition {
      NumberAnimation {
        property: "x"
        duration: Core.Style.duration(Core.Style.animFast)
        easing.type: Core.Style.easeStandard
      }
    }

    Repeater {
      model: slotModel

      delegate: Components.Card {
        id: slot

        required property int wsId

        readonly property int workspaceId: wsId
        readonly property var workspace: root.localWorkspaces[workspaceId] ?? null
        readonly property bool occupied: (workspace?.toplevels?.values?.length ?? 0) > 0
        readonly property bool isFocused: root.focusedId === workspaceId
        readonly property bool isUrgent: workspace?.urgent ?? false

        width: Core.Style.widgetSize
        height: Core.Style.widgetSize

        interactive: true

        // Slots appear constantly - a workspace lives exactly as long as it has
        // windows or focus. Card already cross-fades its background; this is the
        // arrival.
        //
        // Set imperatively rather than bound, because a Repeater delegate is
        // created at its final size: there is nothing to animate from unless the
        // first frame is put there by hand.
        opacity: 0
        scale: Core.Style.popHiddenScale

        Component.onCompleted: {
          slot.opacity = 1;
          slot.scale = 1;
        }

        Behavior on opacity {
          NumberAnimation {
            duration: Core.Style.duration(Core.Style.animFast)
            easing.type: Core.Style.easeStandard
          }
        }

        Behavior on scale {
          NumberAnimation {
            duration: Core.Style.duration(Core.Style.animFast)
            easing.type: Core.Style.easeEnter
            easing.overshoot: Core.Style.enterOvershoot
          }
        }

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

          // The colour cross-fades via Text's own Behavior; the size shift is
          // what sells the focus change on a slot this small.
          scale: slot.isFocused ? 1.08 : 1.0

          Behavior on scale {
            NumberAnimation {
              duration: Core.Style.duration(Core.Style.animFast)
              easing.type: Core.Style.easeStandard
            }
          }
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
