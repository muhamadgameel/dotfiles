import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "../components" as Components
import "../config" as Config
import "../core" as Core

/**
* SlidingPanel - Base component for sliding panels with common infrastructure
*
* Provides:
* - PanelWindow setup with WlrLayershell configuration
* - Slide animation (margins.right behavior)
* - Optional header with icon, title, subtitle, close button
* - Optional scrollable content area
* - Content padding and spacing configuration
* - Escape key handling and focus management
* - open(), close(), toggle() API
*
* Usage:
*   // Simple panel with header and scrollable content
*   SlidingPanel {
*       headerIcon: "settings"
*       headerTitle: "Settings"
*       headerSubtitle: "Configure your preferences"
*
*       FormRow { label: "Option 1"; hasToggle: true }
*       FormRow { label: "Option 2"; valueText: "Value" }
*   }
*
*   // Non-scrollable panel (manages its own scrolling)
*   SlidingPanel {
*       headerTitle: "Network"
*       scrollable: false
*
*       // Custom content with internal Flickable
*   }
*/
Item {
  id: root

  // === Required Properties ===
  property var parentWindow: null

  // === Panel Configuration ===
  property string namespace: "quickshell-panel"
  property bool hasBackdrop: false
  property real backdropOpacity: Config.Config.panelBackdropOpacity

  // === Header Properties (optional - shown when headerTitle is set) ===
  property string headerIcon: ""
  property string headerTitle: ""
  property string headerSubtitle: ""
  property color headerIconColor: Config.Theme.text

  // === Content Configuration ===
  property bool scrollable: true
  property int contentSpacing: Core.Style.spaceL

  // === State ===
  property bool isOpen: false

  // === Content ===
  default property alias content: contentLoader.contentTarget

  // === Signals ===
  signal opened
  signal closed

  // === Computed Properties ===
  readonly property int panelWidth: Core.Style.panelWidth
  readonly property int topOffset: Core.Style.barHeight + Core.Style.spaceM
  readonly property bool hasHeader: headerTitle !== ""

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
        id: mainLayout
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
        ContentLoader {
          id: contentLoader
          Layout.fillWidth: true
          Layout.fillHeight: true
          scrollable: root.scrollable
          contentSpacing: root.contentSpacing
        }
      }
    }
  }

  // === Content Loader Component ===
  component ContentLoader: Item {
    id: loader

    property bool scrollable: true
    property int contentSpacing: Core.Style.spaceL

    // This property allows content to be added via default property alias
    property alias contentTarget: scrollableContent.data

    // Scrollable content (default)
    Components.ScrollArea {
      id: scrollArea
      anchors.fill: parent
      visible: loader.scrollable
      contentHeight: scrollableContent.height

      ColumnLayout {
        id: scrollableContent
        width: parent.width
        spacing: loader.contentSpacing
      }
    }

    // Non-scrollable content with padding
    Item {
      anchors.fill: parent
      anchors.margins: Core.Style.panelPadding
      visible: !loader.scrollable

      ColumnLayout {
        id: directContent
        anchors.fill: parent
        spacing: loader.contentSpacing

        // Reparent items when switching modes
        Component.onCompleted: {
          if (!loader.scrollable) {
            // Move items from scrollableContent to directContent
            while (scrollableContent.children.length > 0) {
              scrollableContent.children[0].parent = directContent;
            }
          }
        }
      }
    }
  }
}
