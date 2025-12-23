import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "../components" as Components
import "../config" as Config
import "../core" as Core
import "../services" as Services

/**
* SlidingPanel - Base component for sliding panels with common infrastructure
*
* Provides:
* - PanelWindow setup with WlrLayershell configuration
* - Slide animation (margins.right behavior)
* - Content rectangle with border, radius, background
* - Escape key handling and focus management
* - open(), close(), toggle() API
*/
Item {
  id: root

  // === Required Properties ===
  property var parentWindow: null

  // === Configuration ===
  property string namespace: "quickshell-panel"
  property bool hasBackdrop: false
  property real backdropOpacity: Config.Config.panelBackdropOpacity

  // === State ===
  property bool isOpen: false

  // === Content ===
  default property alias content: contentColumn.data

  // === Signals ===
  signal opened
  signal closed

  // === Computed Properties ===
  readonly property int panelWidth: Core.Style.panelWidth
  readonly property int topOffset: Core.Style.barHeight + Core.Style.spaceM

  // === Public API ===
  function toggle() {
    isOpen = !isOpen;
  }

  function open() {
    isOpen = true;
  }

  function close() {
    isOpen = false;
  }

  // Handle open/close side effects
  onIsOpenChanged: {
    if (isOpen) {
      Qt.callLater(() => panelWindow.requestActiveFocus());
      root.opened();
    } else {
      root.closed();
    }
  }

  // === Backdrop Window (optional) ===
  PanelWindow {
    id: backdropWindow
    screen: root.parentWindow?.screen ?? null
    visible: root.isOpen && root.hasBackdrop
    color: Config.Theme.transparent

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    WlrLayershell.namespace: root.namespace + "-backdrop"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
      anchors.fill: parent
      color: Config.Theme.alpha(Config.Theme.bgDark, root.backdropOpacity)

      opacity: root.isOpen ? 1.0 : 0.0
      Behavior on opacity {
        NumberAnimation {
          duration: Core.Style.animNormal
          easing.type: Easing.OutQuad
        }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: root.close()
      }
    }
  }

  // === Main Panel Window ===
  PanelWindow {
    id: panelWindow
    screen: root.parentWindow?.screen ?? null
    visible: root.isOpen || slideAnim.running
    color: Config.Theme.transparent
    implicitWidth: root.panelWidth

    function requestActiveFocus() {
      contentRect.forceActiveFocus();
    }

    anchors {
      top: true
      right: true
      bottom: true
    }

    margins {
      top: root.topOffset
      right: root.isOpen ? 0 : -root.panelWidth
      bottom: Core.Style.spaceM
    }

    WlrLayershell.namespace: root.namespace
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: root.isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Behavior on margins.right {
      NumberAnimation {
        id: slideAnim
        duration: Core.Style.animNormal
        easing.type: Easing.OutCubic
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
        id: contentColumn
        anchors.fill: parent
        anchors.margins: Core.Style.panelPadding
        spacing: Core.Style.spaceL
      }
    }
  }
}
