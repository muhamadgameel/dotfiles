import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import "." as Components
import "../config" as Config
import "../core" as Core
import "../services" as Services

/**
* SlidingPanel - base for the right-hand sliding panels
*
* Provides:
* - A PanelWindow that slides in from the right edge
* - Optional header with icon, title, subtitle and close button
* - Optional scrollable content area
* - Escape to close, and click-outside to close via HyprlandFocusGrab
*
* Open/closed state lives in Services.Panels, not here, so only one panel is
* open at a time and IPC/shortcuts can drive them. Set `panelId` to one of
* Services.Panels.ids.
*
* Dismissal is a focus grab rather than a full-screen dimmed backdrop window.
* The backdrop doubled the window count (one extra PanelWindow per panel, per
* screen) and vanished instantly on close while the panel was still sliding out.
*
* Usage:
*   SlidingPanel {
*       panelId: "audio"
*       headerIcon: "settings"
*       headerTitle: "Settings"
*
*       FormRow { label: "Option 1"; hasToggle: true }
*   }
*/
Item {
  id: root

  // === Required Properties ===
  property var parentWindow: null

  // Panel identity in Services.Panels.
  property string panelId: ""

  // === Panel Configuration ===
  property string namespace: "quickshell-panel"

  // === Header Properties (shown when headerTitle is set) ===
  property string headerIcon: ""
  property string headerTitle: ""
  property string headerSubtitle: ""
  property color headerIconColor: Config.Theme.text

  // === Content Configuration ===
  property bool scrollable: true
  property int contentSpacing: Core.Style.spaceL

  // === Content ===
  default property alias content: contentColumn.data

  // === Signals ===
  signal opened
  signal closed

  // === State ===
  readonly property var screen: root.parentWindow?.screen ?? null
  readonly property bool isOpen: Services.Panels.isOpen(root.panelId, root.screen)

  // Drives the slide. Distinct from isOpen because the panel is constructed
  // already-open: binding the margin straight to isOpen initialised it at the
  // final value, so there was nothing for the Behavior to animate and the panel
  // simply appeared. Revealing one tick later gives it a transition to run.
  property bool revealed: false

  Component.onCompleted: {
    if (root.isOpen)
      Qt.callLater(root._reveal);
  }

  function _reveal() {
    // isOpen can have flipped back while we waited a tick.
    root.revealed = root.isOpen;
  }

  // === Computed Properties ===
  property int panelWidth: Core.Style.panelWidth
  readonly property int topOffset: Core.Style.barHeight + Core.Style.spaceM
  readonly property bool hasHeader: headerTitle !== ""

  // === Public API ===
  function open() {
    Services.Panels.open(root.panelId, root.screen);
  }

  function close() {
    Services.Panels.close();
  }

  function toggle() {
    Services.Panels.toggle(root.panelId, root.screen);
  }

  onIsOpenChanged: {
    if (isOpen) {
      Qt.callLater(root._reveal);
      Qt.callLater(() => contentRect.forceActiveFocus());
      root.opened();
    } else {
      root.revealed = false;
      root.closed();
    }
  }

  // === Main Panel Window ===
  PanelWindow {
    id: panelWindow

    screen: root.screen
    visible: root.isOpen || root.revealed || slideAnim.running
    color: Config.Theme.transparent
    implicitWidth: root.panelWidth

    anchors {
      top: true
      right: true
      bottom: true
    }

    margins {
      top: root.topOffset
      right: 0
      bottom: Core.Style.spaceM
    }

    WlrLayershell.namespace: root.namespace
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: root.isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Click anywhere outside the panel to dismiss it.
    HyprlandFocusGrab {
      active: root.isOpen
      windows: [panelWindow]
      onCleared: root.close()
    }

    // === Sliding Container ===
    Item {
      id: slider

      width: parent.width
      height: parent.height

      // Off to the right when hidden, flush when revealed.
      x: root.revealed ? 0 : root.panelWidth

      Behavior on x {
        NumberAnimation {
          id: slideAnim
          duration: Core.Style.duration(Core.Style.animNormal)
          easing.type: Core.Style.easeStandard
        }
      }

    // === Content Container ===
    Rectangle {
      id: contentRect

      anchors.fill: parent
      anchors.margins: Core.Style.spaceS
      radius: Core.Style.radiusL
      color: Config.Theme.alpha(Config.Theme.bg, 0.98)

      border {
        color: Config.Theme.surfaceHover
        width: 1
      }

      focus: root.isOpen

      Keys.onEscapePressed: root.close()

      MouseArea {
        anchors.fill: parent
        onClicked: contentRect.forceActiveFocus()
      }

      ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // === Optional Header ===
        PanelHeader {
          Layout.fillWidth: true
          visible: root.hasHeader
          icon: root.headerIcon
          iconColor: root.headerIconColor
          title: root.headerTitle
          subtitle: root.headerSubtitle
          onCloseClicked: root.close()
        }

        Components.Divider {
          visible: root.hasHeader
        }

        // === Content Area ===
        Flickable {
          id: scrollArea

          Layout.fillWidth: true
          Layout.fillHeight: true

          clip: true
          interactive: root.scrollable
          boundsBehavior: Flickable.StopAtBounds
          contentWidth: width
          contentHeight: root.scrollable ? contentColumn.implicitHeight + Core.Style.panelPadding * 2 : height

          ColumnLayout {
            id: contentColumn

            x: Core.Style.panelPadding
            y: Core.Style.panelPadding
            width: scrollArea.width - Core.Style.panelPadding * 2
            height: root.scrollable ? implicitHeight : scrollArea.height - Core.Style.panelPadding * 2
            spacing: root.contentSpacing
          }

          // Scrollbar
          Rectangle {
            visible: root.scrollable && scrollArea.contentHeight > scrollArea.height
            anchors.right: parent.right
            anchors.rightMargin: Core.Style.spaceXXS
            width: 3
            radius: 1.5
            color: Config.Theme.alpha(Config.Theme.accent, 0.8)

            readonly property real viewRatio: scrollArea.height / scrollArea.contentHeight

            height: Math.max(24, scrollArea.height * viewRatio)
            y: (scrollArea.height - height) * (scrollArea.contentHeight > scrollArea.height ? scrollArea.contentY / (scrollArea.contentHeight - scrollArea.height) : 0)
          }
        }
      }
    }
    }
  }
}
