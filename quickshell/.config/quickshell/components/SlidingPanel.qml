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

  // === Sizing ===
  property bool fillHeight: !root.scrollable

  // Transparent room around the surface, for a drop shadow to land in later.
  // Sized through elevationRoom() so switching shadows off returns the window
  // to exactly its old geometry rather than leaving a dead margin.
  readonly property int surfaceInset: Math.max(Core.Style.spaceS, Core.Style.elevationRoom(root.elevation))
  property int elevation: 0

  // A layer surface committed at height 0 before the layouts have polished is a
  // protocol hazard, so the height has a floor.
  readonly property int minWindowHeight: Core.Style.barHeight * 2
  readonly property int maxWindowHeight: Math.max(root.minWindowHeight, (root.screen?.height ?? 0) - root.topOffset - Core.Style.spaceM)

  property int frameHeight: 0

  readonly property int naturalWindowHeight: root.frameHeight + root.surfaceInset * 2

  readonly property int surfaceHeight: root.fillHeight ? root.maxWindowHeight : Core.Utils.clamp(root.naturalWindowHeight, root.minWindowHeight, root.maxWindowHeight)

  // Content that reports no height is almost always a Layout.fillHeight child
  // inside a content-sized panel. It fails silently - the panel just collapses -
  // so say so rather than leaving it to be discovered visually.
  //
  // Checked on a timer rather than on change: frameHeight is legitimately 0 for
  // the frame or two between construction and the first layout pass, and warning
  // there would cry wolf on every panel that opens.
  Timer {
    id: heightCheck
    interval: Core.Style.animNormal * 2
    repeat: false
    onTriggered: {
      if (!root.fillHeight && root.frameHeight <= 0)
        Core.Logger.w("SlidingPanel", `${root.panelId}: content reports no height - a Layout.fillHeight child?`);
    }
  }


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
      heightCheck.restart();
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

    implicitWidth: root.panelWidth + (root.surfaceInset - Core.Style.spaceS) * 2
    implicitHeight: root.surfaceHeight

    anchors {
      top: true
      right: true
    }

    margins {
      top: root.topOffset
      right: 0
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

      // Off to the right when hidden, flush when revealed. Measured from the
      // slider's own width rather than panelWidth
      x: root.revealed ? 0 : slider.width

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

      // Top-anchored with an explicit height rather than anchors.fill, so the
      // visible surface and the window can be sized separately - the window
      // carries extra transparent room for the shadow.
      anchors {
        left: parent.left
        right: parent.right
        top: parent.top
        margins: root.surfaceInset
      }
      height: root.surfaceHeight - root.surfaceInset * 2

      radius: Core.Style.radiusL
      color: Config.Theme.panelBg

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
        id: frameColumn

        anchors.fill: parent
        spacing: 0

        onImplicitHeightChanged: root.frameHeight = implicitHeight
        Component.onCompleted: root.frameHeight = implicitHeight

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

          // What the content would like to be. -1 falls back to implicitHeight
          // (0), which is what a fill-height panel wants; otherwise this is the
          // number that ends up driving the whole window's height.
          Layout.preferredHeight: root.fillHeight ? -1 : contentColumn.implicitHeight + Core.Style.panelPadding * 2

          // So it can still be squeezed once the content exceeds the cap.
          Layout.minimumHeight: 0

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
