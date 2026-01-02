import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core
import "../../layouts" as Layouts
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
Layouts.SlidingPanel {
  id: root

  namespace: "quickshell-audio-panel"
  scrollable: true

  // Header configuration
  headerIcon: Services.Audio.getVolumeIcon()
  headerIconColor: Services.Audio.muted ? Config.Theme.error : Config.Theme.accent
  headerTitle: "Sound"
  headerSubtitle: Services.Audio.deviceName(Services.Audio.sink)

  // Panel content
  Item {
    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
      anchors.fill: parent
      spacing: Core.Style.spaceM

      Components.Spacer {}

      // === OUTPUT SECTION ===
      OutputSection {
        Layout.fillWidth: true
      }

      Components.Divider {}

      // === INPUT SECTION (Collapsible) ===
      InputSection {
        Layout.fillWidth: true
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
        width: parent.width
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
        Layouts.EmptyState {
          Layout.fillWidth: true
          visible: Services.Audio.sinkStreams.length === 0 && Services.Audio.sourceStreams.length === 0
          icon: "volume-off"
          message: "No active streams"
          hint: "Applications will appear here when playing or recording audio"
        }
      }
    }
  }

  // ==========================================================================
  // INLINE COMPONENTS
  // ==========================================================================

  // --- Output Section ---
  component OutputSection: ColumnLayout {
    spacing: Core.Style.spaceS

    Components.Text {
      text: "Output"
      weight: Core.Style.weightBold
      size: Core.Style.fontL
    }

    // Controls
    RowLayout {
      Layout.fillWidth: true
      spacing: Core.Style.spaceS

      Components.Icon {
        icon: Services.Audio.getVolumeIcon()
        size: Core.Style.fontXL
        color: Services.Audio.muted ? Config.Theme.error : Config.Theme.accent
      }

      Components.Text {
        text: Services.Audio.deviceName(Services.Audio.sink)
        size: Core.Style.fontS
        color: Config.Theme.textDim
        Layout.fillWidth: true
      }

      // Volume percentage
      Components.Text {
        text: Math.round(Services.Audio.volume * 100) + "%"
        size: Core.Style.fontM
        weight: Core.Style.weightBold
        color: Services.Audio.muted ? Config.Theme.textMuted : Services.Audio.volume > 1.0 ? Config.Theme.warning : Config.Theme.text
      }

      // Mute button
      Components.Button {
        icon: Services.Audio.muted ? "volume-mute" : "volume-high"
        iconColor: Services.Audio.muted ? Config.Theme.error : Config.Theme.text
        tooltipText: Services.Audio.muted ? "Unmute" : "Mute"
        onClicked: Services.Audio.toggleMute()
      }
    }

    // Volume Slider
    Components.Slider {
      Layout.fillWidth: true
      value: Services.Audio.volume
      maxValue: 1.5
      onValueUpdated: newValue => Services.Audio.setVolume(newValue)
      progressColor: Services.Audio.muted ? Config.Theme.error : (Services.Audio.volume > 1.0 ? Config.Theme.warning : Config.Theme.accent)
    }

    // Device selector (collapsible)
    DeviceSelector {
      Layout.fillWidth: true
      title: "Output Devices"
      devices: Services.Audio.sinkDevices
      currentDevice: Services.Audio.sink
      onDeviceSelected: node => Services.Audio.setDefaultSink(node)
    }
  }

  // --- Input Section ---
  component InputSection: ColumnLayout {
    spacing: Core.Style.spaceS

    Components.Text {
      text: "Input"
      weight: Core.Style.weightBold
      size: Core.Style.fontL
    }

    // Controls
    RowLayout {
      Layout.fillWidth: true
      spacing: Core.Style.spaceS

      Components.Icon {
        icon: Services.Audio.getMicIcon()
        size: Core.Style.fontL
        color: Services.Audio.micMuted ? Config.Theme.error : Config.Theme.accent
      }

      Components.Text {
        text: Services.Audio.deviceName(Services.Audio.source)
        size: Core.Style.fontS
        color: Config.Theme.textDim
        Layout.fillWidth: true
      }

      // Volume percentage
      Components.Text {
        text: Math.round(Services.Audio.micVolume * 100) + "%"
        size: Core.Style.fontM
        weight: Core.Style.weightBold
        color: Services.Audio.micMuted ? Config.Theme.textMuted : Config.Theme.text
      }

      // Mute button
      Components.Button {
        icon: Services.Audio.micMuted ? "microphone-off" : "microphone"
        iconColor: Services.Audio.micMuted ? Config.Theme.error : Config.Theme.text
        tooltipText: Services.Audio.micMuted ? "Unmute" : "Mute"
        onClicked: Services.Audio.toggleMicMute()
      }
    }

    // Volume Slider
    Components.Slider {
      Layout.fillWidth: true
      value: Services.Audio.micVolume
      onValueUpdated: newValue => Services.Audio.setMicVolume(newValue)
      progressColor: Services.Audio.micMuted ? Config.Theme.error : Config.Theme.accent
    }

    // Device selector
    DeviceSelector {
      Layout.fillWidth: true
      title: "Input Devices"
      devices: Services.Audio.sourceDevices
      currentDevice: Services.Audio.source
      onDeviceSelected: node => Services.Audio.setDefaultSource(node)
    }
  }

  // --- Device Selector ---
  component DeviceSelector: Layouts.Collapsible {
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
        implicitHeight: 44

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
            icon: _getDeviceIcon(modelData)
            size: Core.Style.fontL
            color: deviceCard.isActive ? Config.Theme.accent : Config.Theme.text
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Components.Text {
              text: Services.Audio.deviceName(modelData)
              color: deviceCard.isActive ? Config.Theme.accent : Config.Theme.text
              weight: deviceCard.isActive ? Core.Style.weightBold : Core.Style.weightNormal
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            Components.Text {
              visible: modelData.description && modelData.description !== modelData.nickname
              text: modelData.name || ""
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

    function _getDeviceIcon(node) {
      if (!node)
        return "speaker";

      const desc = (node.description || "").toLowerCase();
      const name = (node.name || "").toLowerCase();
      const deviceApi = node.properties["device.api"] || "";

      // Bluetooth
      if (deviceApi === "bluez5")
        return "bluetooth-connected";

      // Headphones
      if (desc.includes("headphone") || desc.includes("headset") || name.includes("headphone") || name.includes("headset")) {
        return "headphones";
      }

      // HDMI/Display
      if (desc.includes("hdmi") || name.includes("hdmi"))
        return "monitor";

      // USB
      if (desc.includes("usb") || name.includes("usb"))
        return "usb";

      // Default
      return node.isSource ? "microphone" : "speaker";
    }
  }

  // --- Stream Item (per-application control) ---
  component StreamItem: Components.Card {
    id: streamRoot

    required property var modelData
    property bool isOutput: true

    // Alias for clarity and to ensure we're using the required property
    readonly property var node: modelData

    implicitHeight: 64
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

    readonly property string streamIcon: {
      if (!node)
        return "music";

      const props = node.properties;
      const appName = (props ? props["application.name"] : "") || "";
      const mediaClass = (props ? props["media.class"] : "") || "";
      const appNameLower = appName.toLowerCase();
      const mediaClassLower = mediaClass.toLowerCase();

      // Common applications
      if (appNameLower.includes("firefox") || appNameLower.includes("chrome") || appNameLower.includes("chromium") || appNameLower.includes("brave"))
        return "browser";
      if (appNameLower.includes("spotify") || appNameLower.includes("music"))
        return "music";
      if (appNameLower.includes("discord") || appNameLower.includes("telegram") || appNameLower.includes("slack"))
        return "message";
      if (appNameLower.includes("obs") || appNameLower.includes("video"))
        return "video";
      if (appNameLower.includes("game") || appNameLower.includes("steam"))
        return "apps";

      // By media class
      if (mediaClassLower.includes("video"))
        return "video";
      if (mediaClassLower.includes("voice") || mediaClassLower.includes("phone"))
        return "phone";

      return isOutput ? "volume" : "microphone";
    }

    ColumnLayout {
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
            streamRoot.node.audio.volume = Math.max(0, Math.min(1.5, newValue));
          }
        }
        progressColor: streamRoot.streamMuted ? Config.Theme.error : (streamRoot.streamVolume > 1.0 ? Config.Theme.warning : Config.Theme.accent)
      }
    }
  }
}
