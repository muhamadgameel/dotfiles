pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

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

  headerIcon: "dashboard"
  headerIconColor: Core.Theme.accent
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
      subtitle: !wifiOn ? "Off" : Services.Network.wifiConnected ? Services.Network.wifiSSID : Services.Network.searching ? "Searching..." : "Not connected"
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
      // Says so when game mode, not the setting, is what is holding popups.
      subtitle: !Services.Notification.doNotDisturb ? "Off" : Config.Config.doNotDisturb ? "Popups hidden" : "Game mode"
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

    // Full width: a seventh toggle in a two-column grid would sit alone.
    Components.QuickToggle {
      Layout.fillWidth: true
      Layout.columnSpan: 2

      icon: "gamepad"
      label: "Game Mode"
      subtitle: Services.GameMode.active ? `${Services.GameMode.reason} - popups held, Performance power` : "Off"
      active: Services.GameMode.active

      onToggled: Services.GameMode.toggle()
    }
  }

  // === Power mode ===
  // Talks to power-profiles-daemon through Quickshell's UPower module, so there
  // is no powerprofilesctl process to spawn. Performance only appears when the
  // hardware offers it.
  RowLayout {
    Layout.fillWidth: true
    spacing: Core.Style.spaceXS

    Repeater {
      model: [
        {
          profile: PowerProfile.PowerSaver,
          label: "Saver",
          icon: "battery-medium"
        },
        {
          profile: PowerProfile.Balanced,
          label: "Balanced",
          icon: "gauge"
        },
        {
          profile: PowerProfile.Performance,
          label: "Performance",
          icon: "rocket"
        },
      ]

      delegate: Components.Button {
        id: modeButton

        required property var modelData

        readonly property bool current: PowerProfiles.profile === modeButton.modelData.profile

        Layout.fillWidth: true
        visible: modeButton.modelData.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
        variant: modeButton.current ? "primary" : "secondary"
        icon: modeButton.modelData.icon
        iconSize: Core.Style.fontM
        text: modeButton.modelData.label
        textSize: Core.Style.fontS
        tooltipText: `${modeButton.modelData.label} power mode`
        onClicked: PowerProfiles.profile = modeButton.modelData.profile
      }
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
        iconColor: Services.Audio.muted ? Core.Theme.error : Core.Theme.text
        iconTooltip: Services.Audio.muted ? "Unmute" : "Mute"
        value: Services.Audio.volume
        maxValue: Services.Audio.maxVolume
        progressColor: Services.Audio.muted ? Core.Theme.error : Services.Audio.volume > 1.0 ? Core.Theme.warning : Core.Theme.accent

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

      // Night light. The slider runs warmest-to-the-right, so it reads as how
      // much filter rather than as a colour temperature going down; the icon
      // turns it on and off, the way the volume icon mutes.
      SliderRow {
        id: nightLight

        readonly property int span: Services.NightLight.temperatureMin + Services.NightLight.temperatureMax

        Layout.fillWidth: true
        visible: Services.NightLight.available

        icon: Services.NightLight.enabled ? "moon" : "sun"
        iconColor: Services.NightLight.active ? Core.Theme.warning : Core.Theme.text
        iconTooltip: Services.NightLight.enabled ? "Night light off" : "Night light on"
        minValue: Services.NightLight.temperatureMin
        maxValue: Services.NightLight.temperatureMax
        value: nightLight.span - Services.NightLight.temperature
        progressColor: Services.NightLight.active ? Core.Theme.warning : Core.Theme.textMuted
        valueText: Services.NightLight.enabled ? `${Services.NightLight.temperature}K` : "Off"

        onIconClicked: Services.NightLight.toggle()
        onMoved: value => {
          Services.NightLight.setTemperature(nightLight.span - value);
          Services.NightLight.setEnabled(true);
        }
      }
    }
  }

  // === Now playing ===
  // Only while a player exists. Tapping the card opens the full media panel.
  Components.Card {
    Layout.fillWidth: true
    visible: Services.Media.hasPlayer
    implicitHeight: Core.Style.controlHeightL + Core.Style.spaceS * 2
    radius: Core.Style.radiusM
    interactive: true
    onClicked: root._openPanel("media")

    RowLayout {
      anchors.fill: parent
      anchors.margins: Core.Style.spaceS
      spacing: Core.Style.spaceS

      Item {
        Layout.preferredWidth: Core.Style.controlHeightL
        Layout.preferredHeight: Core.Style.controlHeightL

        Rectangle {
          anchors.fill: parent
          radius: Core.Style.radiusS
          color: Core.Theme.surface
        }

        Components.Icon {
          anchors.centerIn: parent
          visible: thumb.status !== Image.Ready
          icon: "music"
          size: Core.Style.fontL
          color: Core.Theme.textDim
        }

        Components.RoundedImage {
          id: thumb

          anchors.fill: parent
          radius: Core.Style.radiusS
          source: Services.Media.trackArtUrl
          sourceSize: Qt.size(Core.Style.px(96), Core.Style.px(96))
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Components.Text {
          Layout.fillWidth: true
          text: Services.Media.trackTitle || Services.Media.identity
          weight: Core.Style.weightBold
        }

        Components.Text {
          Layout.fillWidth: true
          visible: Services.Media.trackArtist !== ""
          text: Services.Media.trackArtist
          size: Core.Style.fontXS
          color: Core.Theme.textDim
        }
      }

      Components.Button {
        icon: "skip-previous"
        iconSize: Core.Style.fontM
        enabled: Services.Media.canGoPrevious
        tooltipText: "Previous"
        onClicked: Services.Media.previous()
      }

      Components.Button {
        variant: "primary"
        icon: Services.Media.statusIcon
        iconSize: Core.Style.fontM
        enabled: Services.Media.isPlaying ? Services.Media.canPause : Services.Media.canPlay
        tooltipText: Services.Media.isPlaying ? "Pause" : "Play"
        onClicked: Services.Media.playPause()
      }

      Components.Button {
        icon: "skip-next"
        iconSize: Core.Style.fontM
        enabled: Services.Media.canGoNext
        tooltipText: "Next"
        onClicked: Services.Media.next()
      }
    }
  }

  // --- Slider Row ---
  component SliderRow: RowLayout {
    id: sliderRow

    property string icon: ""
    property color iconColor: Core.Theme.text
    property string iconTooltip: ""
    property real value: 0
    property real minValue: 0
    property real maxValue: 1.0
    property color progressColor: Core.Theme.accent
    property string valueText: Math.round(sliderRow.value * 100) + "%"

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
      minValue: sliderRow.minValue
      maxValue: sliderRow.maxValue
      progressColor: sliderRow.progressColor
      onValueUpdated: newValue => sliderRow.moved(newValue)
    }

    Components.Text {
      Layout.preferredWidth: Core.Style.controlHeightM
      horizontalAlignment: Text.AlignRight
      text: sliderRow.valueText
      size: Core.Style.fontS
      color: Core.Theme.textDim
    }
  }
}
