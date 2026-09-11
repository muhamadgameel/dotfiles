import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../config" as Config
import "../core" as Core
import "../services" as Services

import "." as Components

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
  // Layer-shell namespace, derived from the id rather than written per panel.
  // Hyprland's no-animation rule matches "^quickshell-.*panel$"; two panels once
  // spelled theirs differently and got the compositor fade on top of the slide.
  readonly property string namespace: "quickshell-" + root.panelId + "-panel"

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

  // Content that stays put above the scrolling body - a toggle, a toolbar, a
  // list's own heading. Assign as a list:
  //
  //   pinned: [
  //     Components.FormRow { ... },
  //     RowLayout { ... }
  //   ]
  //
  // With it, a panel whose list should scroll under a fixed top no longer needs
  // `scrollable: false` and a ScrollArea of its own: the body scrolls, with the
  // panel's scrollbar, and a hairline shows under the pinned part while it does.
  property alias pinned: pinnedColumn.data
  readonly property bool hasPinned: pinnedColumn.children.length > 0

  // Gap above the body: the usual padding, or - under a pinned area - half the
  // content spacing, with the other half above the scroll hairline. Together
  // they make the same gap as between any two rows.
  readonly property int _pinnedGap: Math.round(root.contentSpacing / 2)
  readonly property int _bodyTopPadding: root.hasPinned ? root._pinnedGap : Core.Style.panelPadding

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
  property int elevation: 2

  // The window is a fixed full-height column and never resizes; only the visible
  // surface inside it changes height. Sizing the window to the content resized
  // the layer surface on every content change - a compositor round trip that
  // flashed for a frame, and ran every frame while a Collapsible animated.
  readonly property int minSurfaceHeight: Core.Style.controlHeightL

  // The window's real height once configured; the screen estimate covers the
  // frames before that.
  readonly property int availableHeight: (panelWindow.height > 0 ? panelWindow.height : (root.screen?.height ?? 0) - root.topOffset - Core.Style.spaceM) - root.surfaceInset * 2
  readonly property int maxSurfaceHeight: Math.max(root.minSurfaceHeight, root.availableHeight)

  property int frameHeight: 0

  readonly property int surfaceHeight: root.fillHeight ? root.maxSurfaceHeight : Core.Utils.clamp(root.frameHeight, root.minSurfaceHeight, root.maxSurfaceHeight)

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

    // Hidden means the slide-out is over, so the loader may tear this down.
    // Deferred a tick: releasing destroys this object, which must not happen
    // from inside its own signal handler.
    onVisibleChanged: {
      if (!visible) {
        const id = root.panelId;
        Qt.callLater(() => Services.Panels.release(id));
      }
    }

    implicitWidth: root.panelWidth + (root.surfaceInset - Core.Style.spaceS) * 2

    // Top and bottom both anchored: the compositor sets the height once.
    anchors {
      top: true
      right: true
      bottom: true
    }

    margins {
      top: root.topOffset
      bottom: Core.Style.spaceM
      right: 0
    }

    // Input only lands on the visible surface; the transparent rest of the
    // column passes clicks through to whatever is underneath, which also clears
    // the focus grab and closes the panel.
    mask: Region {
      item: hitArea
    }

    // Outside the slider on purpose, so the mask never has to follow the slide.
    Item {
      id: hitArea

      x: root.surfaceInset
      y: root.surfaceInset
      width: contentRect.width
      height: contentRect.height
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
      Components.Elevation {
        surface: contentRect
        level: root.elevation
        radius: contentRect.radius
      }

      Rectangle {
        id: contentRect

        // Top-anchored with an explicit height rather than anchors.fill: the
        // window is a fixed column, and this is the part of it that is drawn.
        anchors {
          left: parent.left
          right: parent.right
          top: parent.top
          margins: root.surfaceInset
        }
        height: root.surfaceHeight

        // The edge glides to the new height while the content underneath is
        // already laid out at it. Off until the slide-in has finished, so the
        // panel arrives at its size instead of growing on the way in.
        Behavior on height {
          enabled: root.revealed && !slideAnim.running

          NumberAnimation {
            duration: Core.Style.duration(Core.Style.animNormal)
            easing.type: Core.Style.easeStandard
          }
        }

        // The content is laid out at the target height, so while the edge is
        // still catching up it has to be cut off here.
        clip: true

        radius: Core.Style.radiusL
        color: Config.Theme.panelBg

        border {
          color: Config.Theme.surfaceHover
          width: Core.Style.borderThin
        }

        focus: root.isOpen

        Keys.onEscapePressed: root.close()

        MouseArea {
          anchors.fill: parent
          onClicked: contentRect.forceActiveFocus()
        }

        ColumnLayout {
          id: frameColumn

          // Laid out at the target height, not the animated one, so an animating
          // edge does not re-run the layout on every frame.
          anchors {
            left: parent.left
            right: parent.right
            top: parent.top
          }
          height: root.surfaceHeight
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

          // === Optional Pinned Area ===
          ColumnLayout {
            id: pinnedColumn

            Layout.fillWidth: true
            Layout.leftMargin: Core.Style.panelPadding
            Layout.rightMargin: Core.Style.panelPadding
            Layout.topMargin: Core.Style.panelPadding
            visible: root.hasPinned
            spacing: root.contentSpacing
          }

          // Only while the body is scrolled beneath the pinned area, so it reads as
          // "more above" rather than as a divider that is always there.
          Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: root._pinnedGap
            Layout.preferredHeight: Core.Style.borderThin
            visible: root.hasPinned
            color: Config.Theme.surfaceHover
            opacity: scrollArea.contentY > 0 ? 1 : 0

            Behavior on opacity {
              NumberAnimation {
                duration: Core.Style.duration(Core.Style.animFast)
                easing.type: Core.Style.easeStandard
              }
            }
          }

          // === Content Area ===
          Components.ScrollArea {
            id: scrollArea

            Layout.fillWidth: true
            Layout.fillHeight: true

            // What the content would like to be. -1 falls back to implicitHeight
            // (0), which is what a fill-height panel wants; otherwise this is the
            // number that ends up driving the whole window's height.
            Layout.preferredHeight: root.fillHeight ? -1 : contentColumn.implicitHeight + root._bodyTopPadding + Core.Style.panelPadding

            // So it can still be squeezed once the content exceeds the cap.
            Layout.minimumHeight: 0

            // The column places itself inside the padding, so no Flickable margins.
            leftMargin: 0
            rightMargin: 0

            interactive: root.scrollable
            showScrollbar: root.scrollable
            contentWidth: width
            contentHeight: root.scrollable ? contentColumn.implicitHeight + root._bodyTopPadding + Core.Style.panelPadding : height

            ColumnLayout {
              id: contentColumn

              x: Core.Style.panelPadding
              y: root._bodyTopPadding
              width: scrollArea.width - Core.Style.panelPadding * 2
              height: root.scrollable ? implicitHeight : scrollArea.height - root._bodyTopPadding - Core.Style.panelPadding
              spacing: root.contentSpacing
            }
          }
        }
      }
    }
  }
}
