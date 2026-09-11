pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

import "../config" as Config
import "../core" as Core
import "../services" as Services

/**
* Audio - PipeWire sink/source state and control
*
* Device swaps (plugging in AirPods, docking) briefly tear down the default
* node before the replacement is ready, so the raw *Ready flags dip false for
* that window and anything bound straight to them flickers.
*
* hasSink/hasSource stay true across a swap, and the value properties hold
* their last reading from a ready device, so the bar shows a steady value
* instead of "--".
*/
Singleton {
  id: root

  // === Core nodes ===
  property PwNode sink: Pipewire.defaultAudioSink
  property PwNode source: Pipewire.defaultAudioSource

  property bool ready: Pipewire.ready
  readonly property bool sinkReady: sink?.ready ?? false
  readonly property bool sourceReady: source?.ready ?? false

  // How long a device may be missing before it is reported as actually gone.
  // Long enough to cover a profile switch, short enough that unplugging still
  // reads as immediate.
  readonly property int deviceSwapGraceMs: 1500

  // Sticky presence - see the type comment.
  property bool hasSink: false
  property bool hasSource: false

  // The OSD bar runs to maxVolume so the over-100% range is visible, while the
  // number stays a plain percentage of unity gain.
  readonly property real maxVolume: 1.5

  // === Sink (output) ===
  readonly property real volume: sinkReady ? (sink.audio?.volume ?? 0) : _heldVolume
  readonly property bool muted: sinkReady ? (sink.audio?.muted ?? false) : _heldMuted

  // === Source (input/microphone) ===
  readonly property real micVolume: sourceReady ? (source.audio?.volume ?? 0) : _heldMicVolume
  readonly property bool micMuted: sourceReady ? (source.audio?.muted ?? false) : _heldMicMuted

  // === Held values (last reading from a ready device) ===
  property real _heldVolume: 0
  property bool _heldMuted: false
  property real _heldMicVolume: 0
  property bool _heldMicMuted: false

  onVolumeChanged: {
    if (sinkReady)
      _heldVolume = volume;
  }

  onMutedChanged: {
    if (sinkReady)
      _heldMuted = muted;
  }

  onMicVolumeChanged: {
    if (sourceReady)
      _heldMicVolume = micVolume;
  }

  onMicMutedChanged: {
    if (sourceReady)
      _heldMicMuted = micMuted;
  }

  onSinkReadyChanged: {
    if (sinkReady) {
      sinkGoneTimer.stop();
      root.hasSink = true;
    } else if (root.hasSink) {
      sinkGoneTimer.restart();
    }
  }

  onSourceReadyChanged: {
    if (sourceReady) {
      sourceGoneTimer.stop();
      root.hasSource = true;
    } else if (root.hasSource) {
      sourceGoneTimer.restart();
    }
  }

  Timer {
    id: sinkGoneTimer
    interval: root.deviceSwapGraceMs
    onTriggered: root.hasSink = false
  }

  Timer {
    id: sourceGoneTimer
    interval: root.deviceSwapGraceMs
    onTriggered: root.hasSource = false
  }

  // === OSD triggers ===
  readonly property bool _soundPanelOpen: Services.Panels.openPanel === "audio"

  Connections {
    target: root.sink?.audio ?? null
    enabled: root.sinkReady

    function onVolumeChanged() {
      root._showVolumeOSD();
    }

    function onMutedChanged() {
      root._showVolumeOSD();
    }
  }

  Connections {
    target: root.source?.audio ?? null
    enabled: root.sourceReady

    function onVolumeChanged() {
      root._showMicOSD();
    }

    function onMutedChanged() {
      root._showMicOSD();
    }
  }

  /**
  * Build and show the volume OSD.
  * Reads sink.audio directly instead of root.volume
  */
  function _showVolumeOSD() {
    if (root._soundPanelOpen)
      return;

    const audio = root.sink?.audio ?? null;
    const value = audio?.volume ?? root.volume;
    const isMuted = audio?.muted ?? root.muted;

    Services.OSD.show("progressRow", {
      icon: getVolumeIcon(value, isMuted),
      value: value,
      maxValue: root.maxVolume,
      iconColor: isMuted ? Config.Theme.error : Config.Theme.text,
      progressColor: isMuted ? Config.Theme.error : (value > 1.0 ? Config.Theme.warning : Config.Theme.accent),
      valueText: Math.round(value * 100) + "%"
    }, "volume");
  }

  // Same reasoning as _showVolumeOSD().
  function _showMicOSD() {
    if (root._soundPanelOpen)
      return;

    const audio = root.source?.audio ?? null;
    const value = audio?.volume ?? root.micVolume;
    const isMuted = audio?.muted ?? root.micMuted;

    Services.OSD.show("progressRow", {
      icon: getMicIcon(value, isMuted),
      value: value,
      maxValue: 1.0,
      iconColor: isMuted ? Config.Theme.error : Config.Theme.text,
      progressColor: isMuted ? Config.Theme.error : Config.Theme.accent,
      valueText: Math.round(value * 100) + "%"
    }, "mic");
  }

  // === Icons ===

  function getVolumeIcon(value, isMuted) {
    const vol = value !== undefined ? value : root.volume;
    const off = isMuted !== undefined ? isMuted : root.muted;

    if (off)
      return "volume-mute";
    if (vol === 0)
      return "volume-off";
    if (vol < 0.33)
      return "volume-low";
    if (vol <= 0.66)
      return "volume-medium";
    return "volume-high";
  }

  function getMicIcon(value, isMuted) {
    const vol = value !== undefined ? value : root.micVolume;
    const off = isMuted !== undefined ? isMuted : root.micMuted;

    return (off || vol < 0.01) ? "microphone-off" : "microphone";
  }

  // === Device detection ===

  readonly property bool isHeadphones: {
    if (!sinkReady || !sink)
      return false;

    const deviceApi = sink.properties?.["device.api"]?.toLowerCase() ?? "";
    const bluezProfile = sink.properties?.["api.bluez5.profile"]?.toLowerCase() ?? "";

    // A2DP is a headset profile in practice; bluez speakers report it too, but
    // treating them as headphones only changes the icon.
    if (deviceApi === "bluez5" && bluezProfile.includes("a2dp"))
      return true;

    const desc = sink.description?.toLowerCase() ?? "";
    const name = sink.name?.toLowerCase() ?? "";
    const nickname = sink.nickname?.toLowerCase() ?? "";
    const haystack = `${desc} ${name} ${nickname}`;

    return ["headphone", "headset", "earbuds", "airpods", "buds", "earpods"].some(k => haystack.includes(k));
  }

  // === Reactive device and stream lists ===

  readonly property var sinkDevices: Pipewire.nodes.values.filter(n => n.isSink && n.audio && !n.isStream)
  readonly property var sourceDevices: Pipewire.nodes.values.filter(n => n.isSource && n.audio && !n.isStream)
  readonly property var sinkStreams: Pipewire.nodes.values.filter(n => n.isSink && n.audio && n.isStream)
  readonly property var sourceStreams: Pipewire.nodes.values.filter(n => n.isSource && n.audio && n.isStream)

  // Binding these keeps their audio properties live; without the tracker the
  // volume and mute values on non-default nodes never update.
  PwObjectTracker {
    objects: [root.sink, root.source].concat(root.sinkDevices, root.sourceDevices, root.sinkStreams, root.sourceStreams)
  }

  // === Control ===

  function setVolume(vol) {
    if (!sinkReady || !sink.audio)
      return;
    sink.audio.volume = Core.Utils.clamp(vol, 0, root.maxVolume);
  }

  function toggleMute() {
    if (!sinkReady || !sink.audio)
      return;
    sink.audio.muted = !muted;
  }

  function setMicVolume(vol) {
    if (!sourceReady || !source.audio)
      return;
    source.audio.volume = Core.Utils.clamp(vol, 0, 1.0);
  }

  function toggleMicMute() {
    if (!sourceReady || !source.audio)
      return;
    source.audio.muted = !micMuted;
  }

  function setDefaultSink(node) {
    Pipewire.preferredDefaultAudioSink = node;
  }

  function setDefaultSource(node) {
    Pipewire.preferredDefaultAudioSource = node;
  }

  function deviceName(node) {
    if (!node)
      return "Unknown";
    return node.nickname || node.description || node.name || "Unknown Device";
  }
}
