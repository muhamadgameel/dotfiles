pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

import "../../../components" as Components
import "../../../core" as Core
import "../../../services" as Services

/**
* Tray - StatusNotifierItem host
*
* - Left click:   activate (usually show/hide the window)
* - Middle click: secondary activate
* - Right click:  the item's own menu
* - Scroll:       forwarded to the item
*/
RowLayout {
  id: root

  spacing: Core.Style.spaceXS

  // Passive items are ones the app has explicitly said need no attention.
  readonly property var shownItems: SystemTray.items.values.filter(i => i && i.status !== Status.Passive)

  visible: shownItems.length > 0

  Repeater {
    model: root.shownItems

    delegate: Item {
      id: entry

      required property var modelData

      readonly property var item: modelData

      implicitWidth: Core.Style.widgetSize
      implicitHeight: Core.Style.widgetSize

      Rectangle {
        anchors.fill: parent
        radius: Core.Style.radiusS
        // Fades from surfaceHover at zero alpha, not from transparent black,
        // which darkened mid-fade. See Theme.transparentOf.
        color: mouse.containsMouse ? Core.Theme.surfaceHover : Core.Theme.transparentOf(Core.Theme.surfaceHover)

        Behavior on color {
          ColorAnimation {
            duration: Core.Style.duration(Core.Style.animFast)
          }
        }
      }

      IconImage {
        anchors.centerIn: parent
        implicitSize: Core.Style.iconSize
        source: entry.item?.icon ?? ""
        // Attention state is the app asking to be noticed.
        opacity: entry.item?.status === Status.NeedsAttention ? 1.0 : 0.9
      }

      // Pulses while the item is asking for attention.
      Components.StatusDot {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: Core.Style.spaceXXS
        size: Core.Style.px(4)
        visible: entry.item?.status === Status.NeedsAttention
        pulse: true
        color: Core.Theme.warning
      }

      MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        onEntered: {
          const tip = entry.item?.tooltipTitle || entry.item?.title || "";
          const body = entry.item?.tooltipDescription ?? "";
          const text = body !== "" ? `${tip}\n${body}` : tip;
          if (text !== "")
            Services.Tooltip.show(entry, text, "bottom");
        }

        onExited: Services.Tooltip.hide()

        onClicked: mouseEvent => {
          if (!entry.item)
            return;

          // Some items only offer a menu; for those a left click should open it
          // rather than do nothing.
          if (mouseEvent.button === Qt.RightButton || entry.item.onlyMenu) {
            // open(), not `visible = true` - visible is read-only.
            if (entry.item.hasMenu)
              menuAnchor.open();
            return;
          }

          if (mouseEvent.button === Qt.MiddleButton)
            entry.item.secondaryActivate();
          else
            entry.item.activate();
        }

        onWheel: wheelEvent => {
          if (!entry.item)
            return;
          const dy = wheelEvent.angleDelta.y;
          const dx = wheelEvent.angleDelta.x;
          if (dy !== 0)
            entry.item.scroll(dy, false);
          if (dx !== 0)
            entry.item.scroll(dx, true);
        }
      }

      QsMenuAnchor {
        id: menuAnchor

        menu: entry.item?.menu ?? null
        anchor.item: entry
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.adjustment: PopupAdjustment.All
      }

      Component.onDestruction: Services.Tooltip.forget(entry)
    }
  }
}
