import QtQuick
import QtQuick.Layouts
import "../core" as Core

import "." as Components

/**
* QuickToggle - a quick-settings tile
*
* Tap the tile to toggle the setting; tap the chevron (or right-click) to open
* the full panel for it. Filled with the accent while on, so the state reads at
* a glance across a grid of them.
*
* Usage:
*   QuickToggle {
*       icon: "wifi"
*       label: "Wi-Fi"
*       subtitle: "Home network"
*       active: Services.Network.wifiEnabled
*       hasDetails: true
*       onToggled: Services.Network.setWifiEnabled(!active)
*       onDetailsRequested: Services.Panels.open("network", screen)
*   }
*/
Components.Card {
  id: root

  property string icon: ""
  property string label: ""
  property string subtitle: ""
  property bool active: false

  // Waiting on the change to land (a systemctl call, say): shows a spinner and
  // refuses further taps until it does.
  property bool busy: false

  // Show the chevron that opens the full panel for this setting.
  property bool hasDetails: false

  signal toggled
  signal detailsRequested

  // Foreground on the accent fill when on, on the surface when off.
  readonly property color _fg: root.active ? Core.Theme.bg : Core.Theme.text
  readonly property color _fgDim: root.active ? Core.Theme.alpha(Core.Theme.bg, 0.72) : Core.Theme.textDim

  implicitHeight: Core.Style.controlHeightL + Core.Style.spaceS
  radius: Core.Style.radiusM

  interactive: !root.busy
  opacity: root.enabled ? 1 : Core.Style.opacityDisabled

  backgroundColor: root.active ? Core.Theme.accent : Core.Theme.cardBg
  // On the accent fill, the same hover and press as a primary button.
  hoverColor: root.active ? Core.Theme.accentHover : Core.Theme.surface
  activeColor: root.active ? Core.Theme.accentPressed : Core.Theme.surfaceActive

  onClicked: button => {
    if (button === Qt.RightButton && root.hasDetails)
      root.detailsRequested();
    else if (button === Qt.LeftButton)
      root.toggled();
  }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: Core.Style.spaceM
    anchors.rightMargin: root.hasDetails ? Core.Style.spaceXS : Core.Style.spaceM
    spacing: Core.Style.spaceS

    Components.Icon {
      icon: root.icon
      size: Core.Style.fontXL
      color: root._fg
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 0

      Components.Text {
        Layout.fillWidth: true
        text: root.label
        weight: Core.Style.weightBold
        color: root._fg
      }

      Components.Text {
        Layout.fillWidth: true
        visible: root.subtitle !== ""
        text: root.subtitle
        size: Core.Style.fontXS
        color: root._fgDim
      }
    }

    Components.Spinner {
      visible: root.busy
      size: Core.Style.fontM
      color: root._fg
    }

    Components.Button {
      visible: root.hasDetails
      icon: "chevron-right"
      iconSize: Core.Style.fontM
      iconColor: root._fg
      hoverColor: Core.Theme.alpha(root._fg, 0.14)
      tooltipText: "More settings"
      onClicked: root.detailsRequested()
    }
  }
}
