pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core
import "../../services" as Services

/**
* AudioPanel - Full-featured audio control panel similar to pavucontrol
*
* Features:
* - Output volume control with device selection
* - Input/microphone volume control with device selection
* - Per-application volume controls for playback and recording streams
* - Visual indicators for volume levels and boost
*/
Components.SlidingPanel {
  id: root

  panelId: "audio"
  namespace: "quickshell-audio-panel"
  scrollable: true
  contentSpacing: Core.Style.spaceM

  // Header configuration
  headerIcon: Services.Audio.getVolumeIcon()
  headerIconColor: Services.Audio.muted ? Config.Theme.error : Config.Theme.accent
  headerTitle: "Sound"
  headerSubtitle: Services.Audio.deviceName(Services.Audio.sink)

  // === OUTPUT SECTION ===
  VolumeSection {
    Layout.fillWidth: true

    title: "Output"
    icon: "volume-high"
    mutedIcon: "volume-mute"
    levelIcon: Services.Audio.getVolumeIcon()

    node: Services.Audio.sink
    volume: Services.Audio.volume
    muted: Services.Audio.muted
    maxValue: Services.Audio.maxVolume
    devices: Services.Audio.sinkDevices

    onVolumeRequested: value => Services.Audio.setVolume(value)
    onMuteToggled: Services.Audio.toggleMute()
    onDeviceSelected: node => Services.Audio.setDefaultSink(node)
  }

  Components.Divider {}

  // === INPUT SECTION ===
  VolumeSection {
    Layout.fillWidth: true

    title: "Input"
    icon: "microphone"
    mutedIcon: "microphone-off"
    levelIcon: Services.Audio.getMicIcon()

    node: Services.Audio.source
    volume: Services.Audio.micVolume
    muted: Services.Audio.micMuted
    devices: Services.Audio.sourceDevices

    onVolumeRequested: value => Services.Audio.setMicVolume(value)
    onMuteToggled: Services.Audio.toggleMicMute()
    onDeviceSelected: node => Services.Audio.setDefaultSource(node)
  }

  Components.Divider {}

  // === STREAMS SECTION ===
  RowLayout {
    Layout.fillWidth: true
    spacing: Core.Style.spaceS

    Components.Text {
      text: "Applications"
      weight: Core.Style.weightBold
      Layout.fillWidth: true
    }

    Components.Text {
      text: _streamCount + " active"
      color: Config.Theme.textDim
      size: Core.Style.fontS

      readonly property int _streamCount: Services.Audio.sinkStreams.length + Services.Audio.sourceStreams.length
    }
  }
  ColumnLayout {
    id: streamList

    Layout.fillWidth: true
    spacing: Core.Style.spaceXS

    // Playback Streams
    Repeater {
      model: Services.Audio.sinkStreams
      delegate: StreamItem {
        Layout.fillWidth: true
        isOutput: true
      }
    }

    // Recording Streams
    Repeater {
      model: Services.Audio.sourceStreams
      delegate: StreamItem {
        Layout.fillWidth: true
        isOutput: false
      }
    }

    // Empty State
    Components.EmptyState {
      Layout.fillWidth: true
      visible: Services.Audio.sinkStreams.length === 0 && Services.Audio.sourceStreams.length === 0
      icon: "volume-off"
      message: "No active streams"
      hint: "Applications will appear here when playing or recording audio"
    }
  }

  // ==========================================================================
  // INLINE COMPONENTS
  // ==========================================================================

  // --- Volume Section ---
  // Output and input are the same controls bound to different nodes.
  component VolumeSection: ColumnLayout {
    id: section

    property string title: ""
    property string icon: ""        // section header, and the unmuted button
    property string mutedIcon: ""
    property string levelIcon: ""   // follows the level, beside the device name

    property var node: null
    property real volume: 0
    property bool muted: false
    property real maxValue: 1.0
    property var devices: []

    signal volumeRequested(real value)
    signal muteToggled
    signal deviceSelected(var node)

    // Past unity gain is where clipping starts, so it is worth flagging.
    readonly property bool _boosted: section.volume > 1.0

    spacing: Core.Style.spaceS

    Components.SectionHeader {
      title: section.title
      icon: section.icon
    }

    // Controls
    RowLayout {
      Layout.fillWidth: true
      spacing: Core.Style.spaceS

      Components.Icon {
        icon: section.levelIcon
        size: Core.Style.fontL
        color: section.muted ? Config.Theme.error : Config.Theme.accent
      }

      Components.Text {
        text: Services.Audio.deviceName(section.node)
        size: Core.Style.fontS
        color: Config.Theme.textDim
        Layout.fillWidth: true
      }

      // Volume percentage
      Components.Text {
        text: Math.round(section.volume * 100) + "%"
        size: Core.Style.fontM
        weight: Core.Style.weightBold
        color: section.muted ? Config.Theme.textMuted : section._boosted ? Config.Theme.warning : Config.Theme.text
      }

      // Mute button
      Components.Button {
        icon: section.muted ? section.mutedIcon : section.icon
        iconColor: section.muted ? Config.Theme.error : Config.Theme.text
        tooltipText: section.muted ? "Unmute" : "Mute"
        onClicked: section.muteToggled()
      }
    }

    // Volume Slider
    Components.Slider {
      Layout.fillWidth: true
      value: section.volume
      maxValue: section.maxValue
      onValueUpdated: newValue => section.volumeRequested(newValue)
      progressColor: section.muted ? Config.Theme.error : section._boosted ? Config.Theme.warning : Config.Theme.accent
    }

    // Device selector (collapsible)
    DeviceSelector {
      Layout.fillWidth: true
      title: section.title + " Devices"
      devices: section.devices
      currentDevice: section.node
      onDeviceSelected: node => section.deviceSelected(node)
    }
  }

  // --- Device Selector ---
  component DeviceSelector: Components.Collapsible {
    id: deviceSelectorRoot

    property var devices: []
    property var currentDevice: null

    signal deviceSelected(var node)

    expanded: false

    Repeater {
      model: deviceSelectorRoot.devices

      Components.Card {
        id: deviceCard

        required property var modelData

        Layout.fillWidth: true
        implicitHeight: Core.Style.controlHeightM

        readonly property bool isActive: deviceSelectorRoot.currentDevice?.id === modelData.id

        backgroundColor: isActive ? Config.Theme.alpha(Config.Theme.accent, 0.15) : Config.Theme.transparent
        borderColor: isActive ? Config.Theme.accent : Config.Theme.transparent
        borderWidth: isActive ? 1 : 0

        interactive: !isActive
        hoverEnabled: !isActive

        onClicked: deviceSelectorRoot.deviceSelected(modelData)

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: Core.Style.spaceM
          anchors.rightMargin: Core.Style.spaceM
          spacing: Core.Style.spaceS

          Components.Icon {
            icon: Services.Audio.deviceIcon(deviceCard.modelData)
            size: Core.Style.fontL
            color: deviceCard.isActive ? Config.Theme.accent : Config.Theme.text
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Components.Text {
              text: Services.Audio.deviceName(deviceCard.modelData)
              color: deviceCard.isActive ? Config.Theme.accent : Config.Theme.text
              weight: deviceCard.isActive ? Core.Style.weightBold : Core.Style.weightNormal
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            Components.Text {
              visible: deviceCard.modelData.description && deviceCard.modelData.description !== deviceCard.modelData.nickname
              text: deviceCard.modelData.name || ""
              size: Core.Style.fontXS
              color: Config.Theme.textMuted
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }

          Components.Icon {
            visible: deviceCard.isActive
            icon: "check"
            size: Core.Style.fontM
            color: Config.Theme.accent
          }
        }
      }
    }
  }

  // --- Stream Item (per-application control) ---
  component StreamItem: Components.Card {
    id: streamRoot

    required property var modelData
    property bool isOutput: true

    // Alias for clarity and to ensure we're using the required property
    readonly property var node: modelData

    implicitHeight: streamContent.implicitHeight + Core.Style.spaceS * 2
    hoverEnabled: true

    // Direct property access for better reactivity
    readonly property var nodeAudio: node?.audio ?? null
    readonly property real streamVolume: nodeAudio?.volume ?? 0
    readonly property bool streamMuted: nodeAudio?.muted ?? false

    readonly property string streamName: {
      if (!node)
        return "Unknown";
      // Access properties object - try multiple fallbacks
      const props = node.properties;
      const appName = props ? props["application.name"] : null;
      const mediaName = props ? props["media.name"] : null;
      return appName || mediaName || node.nickname || node.description || "Unknown";
    }

    readonly property string streamIcon: Services.Audio.streamIcon(node)

    ColumnLayout {
      id: streamContent

      anchors.fill: parent
      anchors.margins: Core.Style.spaceS
      spacing: Core.Style.spaceXS

      // Stream header
      RowLayout {
        Layout.fillWidth: true
        spacing: Core.Style.spaceS

        Components.Icon {
          icon: streamRoot.streamIcon
          size: Core.Style.fontL
          color: streamRoot.streamMuted ? Config.Theme.textMuted : Config.Theme.text
        }

        Components.Text {
          text: streamRoot.streamName
          elide: Text.ElideRight
          Layout.fillWidth: true
          color: streamRoot.streamMuted ? Config.Theme.textMuted : Config.Theme.text
        }

        // Recording indicator
        Components.Badge {
          visible: !streamRoot.isOutput
          text: "REC"
          backgroundColor: Config.Theme.error
        }

        Components.Text {
          text: Math.round(streamRoot.streamVolume * 100) + "%"
          size: Core.Style.fontS
          color: streamRoot.streamMuted ? Config.Theme.textMuted : Config.Theme.textDim
        }

        Components.Button {
          icon: streamRoot.streamMuted ? (streamRoot.isOutput ? "volume-mute" : "microphone-off") : (streamRoot.isOutput ? "volume-high" : "microphone")
          iconSize: Core.Style.fontM
          iconColor: streamRoot.streamMuted ? Config.Theme.error : Config.Theme.text
          tooltipText: streamRoot.streamMuted ? "Unmute" : "Mute"
          onClicked: {
            if (streamRoot.node?.audio) {
              streamRoot.node.audio.muted = !streamRoot.node.audio.muted;
            }
          }
        }
      }

      Components.Slider {
        Layout.fillWidth: true
        value: streamRoot.streamVolume
        maxValue: 1.5
        onValueUpdated: newValue => {
          if (streamRoot.node?.audio) {
            streamRoot.node.audio.volume = Core.Utils.clamp(newValue, 0, 1.5);
          }
        }
        progressColor: streamRoot.streamMuted ? Config.Theme.error : (streamRoot.streamVolume > 1.0 ? Config.Theme.warning : Config.Theme.accent)
      }
    }
  }
}
