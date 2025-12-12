import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core
import "../../layouts" as Layouts
import "../../services" as Services

/*
* SettingsPanel - Sliding settings panel with click-outside-to-close
*/
Item {
  id: root

  property var parentWindow: null
  property bool isOpen: false

  readonly property int panelWidth: Core.Style.panelWidth
  readonly property int topOffset: Core.Style.barHeight + Core.Style.spaceM

  function toggle() {
    isOpen = !isOpen;
    if (isOpen) {
      Services.Panel.willOpen(root);
      // Force focus for keyboard handling
      Qt.callLater(() => panelWindow.requestActiveFocus());
    } else {
      Services.Panel.didClose(root);
    }
  }

  function open() {
    if (!isOpen)
      toggle();
  }

  function close() {
    if (isOpen)
      toggle();
  }

  // Backdrop for click-outside-to-close
  PanelWindow {
    id: backdropWindow

    screen: root.parentWindow?.screen ?? null
    visible: root.isOpen && Config.Config.panelBackdropEnabled

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    color: Config.Theme.transparent

    WlrLayershell.namespace: "quickshell-backdrop"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Backdrop overlay with fade animation
    Rectangle {
      anchors.fill: parent
      color: Config.Theme.alpha(Config.Theme.bgDark, Config.Config.panelBackdropOpacity)

      opacity: root.isOpen ? 1.0 : 0.0
      Behavior on opacity {
        NumberAnimation {
          duration: Core.Style.animNormal
          easing.type: Easing.OutQuad
        }
      }

      // Click backdrop to close
      MouseArea {
        anchors.fill: parent
        onClicked: root.close()
      }
    }
  }

  // Panel Window
  PanelWindow {
    id: panelWindow

    screen: root.parentWindow?.screen ?? null
    visible: root.isOpen || slideAnim.running

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

    implicitWidth: root.panelWidth

    color: Config.Theme.transparent

    WlrLayershell.namespace: "quickshell-settings"
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

    // Content
    Rectangle {
      id: contentRect
      anchors.fill: parent
      anchors.margins: Core.Style.spaceS
      radius: Core.Style.radiusL
      color: Config.Theme.alpha(Config.Theme.bg, 0.98)
      border.color: Config.Theme.surfaceHover
      border.width: 1

      // Enable focus for keyboard handling
      focus: root.isOpen

      Keys.onEscapePressed: root.close()

      // Prevent clicks from reaching backdrop
      MouseArea {
        anchors.fill: parent
        onClicked: {
          contentRect.forceActiveFocus();
        }
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Core.Style.panelPadding
        spacing: Core.Style.spaceL

        // Header
        RowLayout {
          Layout.fillWidth: true
          spacing: Core.Style.spaceM

          Components.Icon {
            icon: "⚙️"
            size: Core.Style.fontXL
          }

          Components.Label {
            text: "Settings"
            size: Core.Style.fontXL
            font.weight: Core.Style.weightBold
            Layout.fillWidth: true
          }

          Components.Button {
            icon: "✕"
            tooltipText: "Close"
            tooltipDirection: "left"
            onClicked: root.close()
          }
        }

        Components.Divider {}

        // Settings content
        Flickable {
          Layout.fillWidth: true
          Layout.fillHeight: true
          contentHeight: settingsColumn.height
          clip: true
          boundsBehavior: Flickable.StopAtBounds

          ColumnLayout {
            id: settingsColumn
            width: parent.width
            spacing: Core.Style.spaceL

            // Appearance Section
            Layouts.Collapsible {
              title: "🎨 Appearance"
              Layout.fillWidth: true

              Layouts.FormRow {
                label: "Dark Mode"
                hasToggle: true
                toggleChecked: true
              }

              Layouts.FormRow {
                label: "Animations"
                hasToggle: true
                toggleChecked: Config.Config.animationsEnabled
              }
            }

            // Bar Section
            Layouts.Collapsible {
              title: "📊 Bar"
              Layout.fillWidth: true

              Layouts.FormRow {
                label: "Show Clock"
                hasToggle: true
                toggleChecked: Config.Config.barShowClock
              }

              Layouts.FormRow {
                label: "Position"
                valueText: Config.Config.barPosition.charAt(0).toUpperCase() + Config.Config.barPosition.slice(1)
              }
            }

            // System Section
            Layouts.Collapsible {
              title: "💻 System"
              Layout.fillWidth: true

              Layouts.FormRow {
                label: "Notifications"
                hasToggle: true
                toggleChecked: true
              }

              Layouts.FormRow {
                label: "Do Not Disturb"
                hasToggle: true
                toggleChecked: false
              }
            }

            Components.Divider {}

            ColumnLayout {
              id: contentColumn
              Layout.fillWidth: true
              spacing: Core.Style.spaceXS

              Components.Label {
                text: "ℹ️ About"
              }

              Components.Label {
                text: "QuickShell config v0.0.1"
                color: Config.Theme.textMuted
              }

              Components.Label {
                text: "Create by Muhamad Gameel <mgameel@pm.me>"
                size: Core.Style.fontS
                color: Config.Theme.textMuted
              }
            }

            Item {
              height: Core.Style.spaceL
            }
          }
        }
      }
    }
  }
}
