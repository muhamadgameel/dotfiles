import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core
import "../../layouts" as Layouts
import "../../services" as Services

/**
* SettingsPanel - Sliding settings panel with click-outside-to-close
*/
Layouts.SlidingPanel {
  id: root

  namespace: "quickshell-settings"
  hasBackdrop: true

  // Header
  Layouts.PanelHeader {
    Layout.fillWidth: true
    icon: "settings"
    title: "Settings"
    onCloseClicked: root.close()
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
