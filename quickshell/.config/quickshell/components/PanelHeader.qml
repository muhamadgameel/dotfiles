import QtQuick
import QtQuick.Layouts
import "../core" as Core

import "." as Components

/**
* PanelHeader - a panel's title and live status
*
* Every panel colours its icon by state - accent while connected or on, grey
* while off, red while muted - so the icon sits in a chip tinted with that same
* colour. A bare grey glyph on a dark panel read as unstyled rather than as
* "off"; a tinted chip reads as state before the title does.
*
* The subtitle is the panel's live status (uptime, network, output device), so
* it is set to be read rather than to recede.
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
  property color iconColor: Core.Theme.text
  property string title: ""
  property string subtitle: ""

  signal closeClicked

  // Prevent expanding in parent ColumnLayout
  Layout.fillHeight: false
  Layout.fillWidth: true

  Layout.margins: Core.Style.panelPadding

  spacing: Core.Style.spaceM

  Rectangle {
    visible: root.icon !== ""
    Layout.preferredWidth: Core.Style.controlHeightM
    Layout.preferredHeight: Core.Style.controlHeightM
    radius: Core.Style.radiusM
    color: Core.Theme.alpha(root.iconColor, Core.Style.opacityTint)

    Behavior on color {
      ColorAnimation {
        duration: Core.Style.duration(Core.Style.animFast)
        easing.type: Core.Style.easeStandard
      }
    }

    Components.Icon {
      anchors.centerIn: parent
      icon: root.icon
      size: Core.Style.fontXL
      color: root.iconColor
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Components.Text {
      Layout.fillWidth: true
      text: root.title
      size: Core.Style.fontXL
      font.weight: Core.Style.weightBold
    }

    Components.Text {
      Layout.fillWidth: true
      visible: root.subtitle !== ""
      text: root.subtitle
      size: Core.Style.fontM
      color: Core.Theme.textDim
    }
  }

  // Neutral, not the danger variant: closing a panel loses nothing, and a red
  // hover read as a destructive action.
  Components.Button {
    Layout.alignment: Qt.AlignTop
    icon: "close"
    iconColor: Core.Theme.textDim
    tooltipText: "Close"
    tooltipDirection: "left"
    onClicked: root.closeClicked()
  }
}
