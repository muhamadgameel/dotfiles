pragma Singleton

import QtQuick
import Quickshell.Services.Pipewire

import "../config" as Config
import "../services" as Services

QtObject {
  id: root

  // Core properties
  property PwNode sink: Pipewire.defaultAudioSink
  property PwNode source: Pipewire.defaultAudioSource
  property bool ready: Pipewire.ready
  property bool sinkReady: sink?.ready ?? false
  property bool sourceReady: source?.ready ?? false

  // Sink (output) properties
  property real volume: sinkReady ? (sink.audio?.volume ?? 0) : 0
  property bool muted: sinkReady ? (sink.audio?.muted ?? false) : false

  // Source (input/microphone) properties
  property real micVolume: sourceReady ? (source.audio?.volume ?? 0) : 0
  property bool micMuted: sourceReady ? (source.audio?.muted ?? false) : false

  // Connection to listen to PipeWire audio changes (sink/output)
  property var _sinkAudioConnection: Connections {
    target: root.sink?.audio ?? null
    enabled: root.sinkReady

    function onVolumeChanged() {
      root._showVolumeOSD();
    }

    function onMutedChanged() {
      root._showVolumeOSD();
    }
  }

  // Connection to listen to PipeWire audio changes (source/microphone)
  property var _sourceAudioConnection: Connections {
    target: root.source?.audio ?? null
    enabled: root.sourceReady

    function onVolumeChanged() {
      root._showMicOSD();
    }

    function onMutedChanged() {
      root._showMicOSD();
    }
  }

  // Private: Show volume OSD with computed data
  function _showVolumeOSD() {
    Services.OSD.show("progressRow", {
      iconName: _getVolumeIcon(volume, muted),
      value: volume,
      maxValue: 1.5,
      iconColor: muted ? Config.Theme.error : Config.Theme.text,
      progressColor: muted ? Config.Theme.error : (volume > 1.0 ? Config.Theme.warning : Config.Theme.accent),
      valueText: Math.round(volume / 1 * 100) + "%"
    });
  }

  // Private: Show microphone OSD with computed data
  function _showMicOSD() {
    Services.OSD.show("progressRow", {
      icon: _getMicIcon(micVolume, micMuted),
      value: micVolume,
      maxValue: 1.0,
      iconColor: micMuted ? Config.Theme.error : Config.Theme.text,
      progressColor: micMuted ? Config.Theme.error : Config.Theme.accent
    });
  }

  // Private: Get volume icon based on level and mute state
  function _getVolumeIcon(value, isMuted) {
    if (isMuted)
      return "volume-mute";
    if (value == 0)
      return "volume-off";
    if (value < 0.33)
      return "volume-low";
    if (value <= 0.66)
      return "volume-medium";
    return "volume-high";
  }

  // Private: Get microphone icon based on mute state
  function _getMicIcon(value, isMuted) {
    return (isMuted || value < 0.01) ? "🎤" : "🎙️";
  }

  // Device detection
  property bool isHeadphones: {
    if (!sinkReady || !sink)
      return false;

    let desc = sink.description?.toLowerCase() || "";
    let name = sink.name?.toLowerCase() || "";
    let nickname = sink.nickname?.toLowerCase() || "";
    let deviceApi = sink.properties["device.api"]?.toLowerCase() || "";
    let bluezProfile = sink.properties["api.bluez5.profile"]?.toLowerCase() || "";

    let isBluetooth = deviceApi === "bluez5" && bluezProfile.includes("a2dp");
    let hasHeadphoneKeyword = desc.includes("headphone") || desc.includes("headset") || desc.includes("earbuds") || desc.includes("airpods") || desc.includes("buds") || desc.includes("earpods") || name.includes("headphone") || name.includes("headset") || nickname.includes("headphone") || nickname.includes("headset");

    return isBluetooth || hasHeadphoneKeyword;
  }

  // Track nodes to ensure proper binding
  property var _tracker: PwObjectTracker {
    objects: [root.sink, root.source]
  }

  // Volume control functions
  function setVolume(vol) {
    if (!sinkReady || !sink.audio)
      return;
    sink.audio.volume = Math.max(0, Math.min(1.5, vol));
  }

  function toggleMute() {
    if (!sinkReady || !sink.audio)
      return;
    sink.audio.muted = !muted;
  }

  // Microphone control functions
  function setMicVolume(vol) {
    if (!sourceReady || !source.audio)
      return;
    source.audio.volume = Math.max(0, Math.min(1.0, vol));
  }

  function toggleMicMute() {
    if (!sourceReady || !source.audio)
      return;
    source.audio.muted = !micMuted;
  }

  // Device management
  function setDefaultSink(node) {
    Pipewire.preferredDefaultAudioSink = node;
  }

  function setDefaultSource(node) {
    Pipewire.preferredDefaultAudioSource = node;
  }

  // Device lists
  function getSinkDevices() {
    return Pipewire.nodes.values.filter(node => {
      return node.isSink && node.audio && !node.isStream;
    });
  }

  function getSourceDevices() {
    return Pipewire.nodes.values.filter(node => {
      return node.isSource && node.audio && !node.isStream;
    });
  }

  function getSinkStreams() {
    return Pipewire.nodes.values.filter(node => {
      return node.isSink && node.audio && node.isStream;
    });
  }

  function getSourceStreams() {
    return Pipewire.nodes.values.filter(node => {
      return node.isSource && node.audio && node.isStream;
    });
  }

  // Helper to get friendly device name
  function deviceName(node) {
    if (!node)
      return "Unknown";
    return node.nickname || node.description || node.name || "Unknown Device";
  }
}
