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
      icon: getVolumeIcon(),
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
      icon: getMicIcon(),
      value: micVolume,
      maxValue: 1.0,
      iconColor: micMuted ? Config.Theme.error : Config.Theme.text,
      progressColor: micMuted ? Config.Theme.error : Config.Theme.accent
    });
  }

  // Private: Get volume icon based on level and mute state
  function getVolumeIcon() {
    if (muted)
      return "volume-mute";
    if (volume == 0)
      return "volume-off";
    if (volume < 0.33)
      return "volume-low";
    if (volume <= 0.66)
      return "volume-medium";
    return "volume-high";
  }

  // Private: Get microphone icon based on mute state
  function getMicIcon() {
    if (micMuted || micVolume < 0.01)
      return "microphone-off";
    return "microphone";
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

  // Reactive device lists (properties instead of functions for reactivity)
  readonly property var sinkDevices: {
    const nodes = Pipewire.nodes.values;
    return nodes.filter(node => node.isSink && node.audio && !node.isStream);
  }

  readonly property var sourceDevices: {
    const nodes = Pipewire.nodes.values;
    return nodes.filter(node => node.isSource && node.audio && !node.isStream);
  }

  // Reactive stream lists
  readonly property var sinkStreams: {
    const nodes = Pipewire.nodes.values;
    return nodes.filter(node => node.isSink && node.audio && node.isStream);
  }

  readonly property var sourceStreams: {
    const nodes = Pipewire.nodes.values;
    return nodes.filter(node => node.isSource && node.audio && node.isStream);
  }

  // Track all audio nodes to ensure proper binding
  property var _tracker: PwObjectTracker {
    objects: {
      const base = [root.sink, root.source];
      const devices = [...root.sinkDevices, ...root.sourceDevices];
      const streams = [...root.sinkStreams, ...root.sourceStreams];
      return base.concat(devices, streams);
    }
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

  // Helper to get friendly device name
  function deviceName(node) {
    if (!node)
      return "Unknown";
    return node.nickname || node.description || node.name || "Unknown Device";
  }
}
