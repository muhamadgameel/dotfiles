pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core
import "../../services" as Services

/**
* QuickSettingsPanel - the everyday toggles and sliders in one place
*
* Tap a tile to toggle its setting. The chevron on a tile hands off to the full
* panel for that setting - opening a panel replaces this one, so there is no
* back-stack to manage.
*
* The sliders here would otherwise raise the OSD on every step of a drag, on
* top of the panel that is already showing the value; Audio and Brightness skip
* the OSD while this panel is open.
*/
Components.SlidingPanel {
  id: root

  panelId: "quicksettings"
  namespace: "quickshell-quicksettings-panel"

  headerIcon: "dashboard"
  headerIconColor: Config.Theme.accent
  headerTitle: "Quick Settings"
  headerSubtitle: Services.Time.dateLong

  function _openPanel(id) {
    Services.Panels.open(id, root.screen);
  }

  // === Toggles ===
  GridLayout {
    Layout.fillWidth: true
    columns: 2
    uniformCellWidths: true
    columnSpacing: Core.Style.spaceS
    rowSpacing: Core.Style.spaceS

    Components.QuickToggle {
      Layout.fillWidth: true

      readonly property bool wifiOn: Services.Network.wifiEnabled

      icon: !wifiOn ? "wifi-off" : Services.Network.wifiConnected ? Services.Network.getSignalIcon(Services.Network.wifiSignal) : "wifi"
      label: "Wi-Fi"
      subtitle: !wifiOn ? "Off" : Services.Network.wifiConnected ? Services.Network.wifiSSID : "Not connected"
      active: wifiOn
      hasDetails: true

      onToggled: Services.Network.setWifiEnabled(!wifiOn)
      onDetailsRequested: root._openPanel("network")
    }

    Components.QuickToggle {
      Layout.fillWidth: true

      enabled: Services.Bluetooth.available
      icon: Services.Bluetooth.statusIcon
      label: "Bluetooth"
      subtitle: Services.Bluetooth.statusText
      active: Services.Bluetooth.enabled
      hasDetails: true

      onToggled: Services.Bluetooth.setEnabled(!Services.Bluetooth.enabled)
      onDetailsRequested: root._openPanel("bluetooth")
    }

    Components.QuickToggle {
      Layout.fillWidth: true

      icon: Services.Audio.muted ? "volume-mute" : Services.Audio.getVolumeIcon()
      label: "Sound"
      subtitle: Services.Audio.muted ? "Muted" : Services.Audio.deviceName(Services.Audio.sink)
      active: !Services.Audio.muted
      hasDetails: true

      onToggled: Services.Audio.toggleMute()
      onDetailsRequested: root._openPanel("audio")
    }

    Components.QuickToggle {
      Layout.fillWidth: true

      icon: Services.Audio.micMuted ? "microphone-off" : "microphone"
      label: "Microphone"
      subtitle: Services.Audio.micMuted ? "Muted" : Services.Audio.deviceName(Services.Audio.source)
      active: !Services.Audio.micMuted
      hasDetails: true

      onToggled: Services.Audio.toggleMicMute()
      onDetailsRequested: root._openPanel("audio")
    }

    Components.QuickToggle {
      Layout.fillWidth: true

      icon: Services.Notification.doNotDisturb ? "bell-off" : "bell"
      label: "Do Not Disturb"
      subtitle: Services.Notification.doNotDisturb ? "Popups hidden" : "Off"
      active: Services.Notification.doNotDisturb

      // No chevron: the label needs the room, and the bar's bell already opens
      // the notification centre.
      onToggled: Config.Config.toggleDoNotDisturb()
    }

    Components.QuickToggle {
      Layout.fillWidth: true

      icon: Services.Idle.statusIcon
      label: "Stay Awake"
      subtitle: Services.Idle.inhibited ? "Idle lock paused" : "Off"
      active: Services.Idle.inhibited
      busy: Services.Idle.busy

      onToggled: Services.Idle.toggle()
    }
  }

  // === Sliders ===
  Components.Card {
    Layout.fillWidth: true
    implicitHeight: sliderColumn.implicitHeight + Core.Style.spaceM * 2
    radius: Core.Style.radiusM
    hoverEnabled: false

    ColumnLayout {
      id: sliderColumn

      anchors.fill: parent
      anchors.margins: Core.Style.spaceM
      spacing: Core.Style.spaceM

      SliderRow {
        Layout.fillWidth: true

        icon: Services.Audio.muted ? "volume-mute" : Services.Audio.getVolumeIcon()
        iconColor: Services.Audio.muted ? Config.Theme.error : Config.Theme.text
        iconTooltip: Services.Audio.muted ? "Unmute" : "Mute"
        value: Services.Audio.volume
        maxValue: Services.Audio.maxVolume
        progressColor: Services.Audio.muted ? Config.Theme.error : Services.Audio.volume > 1.0 ? Config.Theme.warning : Config.Theme.accent

        onIconClicked: Services.Audio.toggleMute()
        onMoved: value => Services.Audio.setVolume(value)
      }

      SliderRow {
        Layout.fillWidth: true
        visible: Services.Brightness.ready

        icon: Services.Brightness.getIcon()
        value: Services.Brightness.brightness

        onMoved: value => Services.Brightness.set(value)
      }
    }
  }

  // --- Slider Row ---
  component SliderRow: RowLayout {
    id: sliderRow

    property string icon: ""
    property color iconColor: Config.Theme.text
    property string iconTooltip: ""
    property real value: 0
    property real maxValue: 1.0
    property color progressColor: Config.Theme.accent

    signal iconClicked
    signal moved(real value)

    spacing: Core.Style.spaceS

    Components.Button {
      icon: sliderRow.icon
      iconColor: sliderRow.iconColor
      tooltipText: sliderRow.iconTooltip
      enabled: sliderRow.iconTooltip !== ""
      // Keep the icon at full strength when it is not a button here.
      opacity: 1
      onClicked: sliderRow.iconClicked()
    }

    Components.Slider {
      Layout.fillWidth: true
      value: sliderRow.value
      maxValue: sliderRow.maxValue
      progressColor: sliderRow.progressColor
      onValueUpdated: newValue => sliderRow.moved(newValue)
    }

    Components.Text {
      Layout.preferredWidth: Core.Style.controlHeightM
      horizontalAlignment: Text.AlignRight
      text: Math.round(sliderRow.value * 100) + "%"
      size: Core.Style.fontS
      color: Config.Theme.textDim
    }
  }
}
