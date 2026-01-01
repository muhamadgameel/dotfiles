import QtQuick
import QtQuick.Layouts

import "../components" as Components
import "../config" as Config
import "../core" as Core

/**
* PanelHeader - Reusable header component for panels
*
* Displays an icon, title, subtitle, and close button
*
* Usage:
*   PanelHeader {
*       icon: "settings"
*       iconColor: Theme.accent
*       title: "Settings"
*       subtitle: "Configure your preferences"
*       onCloseClicked: panel.close()
*   }
*/
RowLayout {
  id: root

  property string icon: ""
  property color iconColor: Config.Theme.text
  property string title: ""
  property string subtitle: ""

  // === Margin Properties ===
  property int leftMargin: Core.Style.panelPadding
  property int rightMargin: Core.Style.panelPadding
  property int topMargin: Core.Style.panelPadding
  property int bottomMargin: Core.Style.panelPadding

  signal closeClicked

  // Prevent expanding in parent ColumnLayout
  Layout.fillHeight: false
  Layout.fillWidth: true

  // Apply margins via Layout attached properties
  Layout.leftMargin: root.leftMargin
  Layout.rightMargin: root.rightMargin
  Layout.topMargin: root.topMargin
  Layout.bottomMargin: root.bottomMargin

  spacing: Core.Style.spaceM

  Components.Icon {
    visible: root.icon !== ""
    icon: root.icon
    size: Core.Style.fontXXL
    color: root.iconColor
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Components.Text {
      text: root.title
      size: Core.Style.fontXL
      font.weight: Core.Style.weightBold
    }

    Components.Text {
      text: root.subtitle
      size: Core.Style.fontS
      color: Config.Theme.textDim
      visible: root.subtitle !== ""
    }
  }

  Components.Spacer {}

  Components.Button {
    icon: "close"
    variant: "danger"
    tooltipText: "Close"
    tooltipDirection: "left"
    onClicked: root.closeClicked()
  }
}
