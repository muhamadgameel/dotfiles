pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

import "../core" as Core
import "../services" as Services

/**
* Media - MPRIS player state and control
*
* Quickshell.Services.Mpris was installed and unused, so the shell had no idea
* anything was playing even though the media keys were already bound to
* playerctl.
*
* Picking "the" player: whichever one the user last interacted with wins, and
* it stays selected while it exists - so pausing Spotify does not silently hand
* control to a background browser tab. Failing that, prefer a playing player,
* then any controllable one.
*/
Singleton {
  id: root

  readonly property var players: Mpris.players.values.filter(p => p && p.canControl)
  readonly property bool hasPlayer: active !== null

  // uniqueId of the explicitly chosen player, "" when following the heuristic.
  property string preferredId: ""

  readonly property var active: {
    if (players.length === 0)
      return null;

    // An explicit pick wins for as long as that player is around.
    if (preferredId !== "") {
      const pinned = players.find(p => p.uniqueId === preferredId);
      if (pinned)
        return pinned;
    }

    return players.find(p => p.isPlaying) ?? players[0];
  }

  // === Track info ===
  readonly property bool isPlaying: active?.isPlaying ?? false
  readonly property string trackTitle: active?.trackTitle ?? ""
  readonly property string trackArtist: active?.trackArtist ?? ""
  readonly property string trackAlbum: active?.trackAlbum ?? ""
  readonly property string trackArtUrl: active?.trackArtUrl ?? ""
  readonly property string identity: active?.identity ?? ""

  // === Position ===
  readonly property bool canSeek: active?.canSeek ?? false
  readonly property bool lengthSupported: active?.lengthSupported ?? false
  readonly property real length: active?.length ?? 0
  readonly property real position: active?.position ?? 0
  readonly property real progress: (lengthSupported && length > 0) ? Math.min(1, position / length) : 0

  // === Capabilities ===
  readonly property bool canPlay: active?.canPlay ?? false
  readonly property bool canPause: active?.canPause ?? false
  readonly property bool canGoNext: active?.canGoNext ?? false
  readonly property bool canGoPrevious: active?.canGoPrevious ?? false
  readonly property bool volumeSupported: stream !== null || (active?.volumeSupported ?? false)
  readonly property bool shuffleSupported: active?.shuffleSupported ?? false
  readonly property bool loopSupported: active?.loopSupported ?? false

  // === Volume ===
  //
  // MPRIS Volume is advisory, and some players lie about it. Chromium publishes
  // the property, reports it as writable, accepts a Set - and then never
  // changes: the value on its own bus stays at 1 while the shell shows whatever
  // it last wrote. Scrolling the widget moved a number and nothing else.
  //
  // The player's PipeWire stream is what actually carries the audio, so that is
  // what the volume control drives. MPRIS is kept as the fallback for a player
  // that has no stream right now (nothing is coming out of it) but does honour
  // the property.

  /**
  * The PipeWire playback stream belonging to the active player, or null.
  *
  * Matched by name: a stream's application.name is the same string the player
  * puts in its MPRIS Identity ("Chromium", "Spotify", "mpv").
  */
  readonly property var stream: {
    if (!active)
      return null;

    const wanted = root._matchKeys(active);
    if (wanted.length === 0)
      return null;

    for (const node of Services.Audio.sinkStreams) {
      const props = node.properties ?? ({});
      const candidates = [props["application.name"], props["application.process.binary"], node.name, node.description];

      for (const candidate of candidates) {
        const key = root._normalize(candidate);
        if (key !== "" && wanted.indexOf(key) >= 0)
          return node;
      }
    }

    return null;
  }

  readonly property real volume: stream?.audio?.volume ?? (active?.volume ?? 0)

  readonly property bool volumeMuted: stream?.audio?.muted ?? false

  function _normalize(text) {
    return String(text ?? "").toLowerCase().replace(/[^a-z0-9]/g, "");
  }

  function _matchKeys(player) {
    return [root._normalize(player.identity), root._normalize(player.desktopEntry)].filter(k => k !== "");
  }

  // === Display helpers ===

  readonly property string statusIcon: isPlaying ? "pause" : "play"

  /**
  * "Title — Artist", or just whichever half exists.
  */
  readonly property string summary: {
    if (!hasPlayer)
      return "";
    if (trackTitle === "")
      return identity;
    return trackArtist === "" ? trackTitle : `${trackTitle} — ${trackArtist}`;
  }

  // === Control ===

  function playPause() {
    if (!active)
      return;
    // Remember whoever the user acted on, so the selection stops drifting.
    preferredId = active.uniqueId;
    active.togglePlaying();
  }

  function next() {
    if (active?.canGoNext) {
      preferredId = active.uniqueId;
      active.next();
    }
  }

  function previous() {
    if (active?.canGoPrevious) {
      preferredId = active.uniqueId;
      active.previous();
    }
  }

  function stop() {
    active?.stop();
  }

  function seek(seconds) {
    if (active?.canSeek)
      active.position = Core.Utils.clamp(seconds, 0, root.length);
  }

  function seekFraction(fraction) {
    if (root.lengthSupported && root.length > 0)
      seek(fraction * root.length);
  }

  /**
  * Set the active player's volume, and show the same OSD the system volume
  * uses so a scroll on the widget has visible feedback.
  *
  * @param vol - 0.0 to 1.0
  */
  function setVolume(vol) {
    const clamped = Core.Utils.clamp(vol, 0, 1);

    if (stream?.audio)
      stream.audio.volume = clamped;
    else if (active?.volumeSupported)
      active.volume = clamped;
    else
      return root.volume;

    root._showVolumeOSD(clamped);
    return clamped;
  }

  function toggleVolumeMute() {
    if (!stream?.audio)
      return false;
    stream.audio.muted = !stream.audio.muted;
    return stream.audio.muted;
  }

  function _showVolumeOSD(value) {
    Services.OSD.show("progressRow", {
      icon: value <= 0 ? "volume-mute" : (value < 0.5 ? "volume-low" : "volume-high"),
      value: value,
      maxValue: 1.0,
      iconColor: Core.Theme.text,
      progressColor: Core.Theme.accent
    });
  }

  function toggleShuffle() {
    if (active?.shuffleSupported)
      active.shuffle = !active.shuffle;
  }

  function cycleLoop() {
    if (!active?.loopSupported)
      return;

    switch (active.loopState) {
    case MprisLoopState.None:
      active.loopState = MprisLoopState.Playlist;
      break;
    case MprisLoopState.Playlist:
      active.loopState = MprisLoopState.Track;
      break;
    default:
      active.loopState = MprisLoopState.None;
      break;
    }
  }

  /**
  * Pin a specific player, or pass "" to go back to the heuristic.
  */
  function selectPlayer(id) {
    preferredId = id ?? "";
  }

  function raise() {
    if (active?.canRaise)
      active.raise();
  }

  // Drop a pin whose player has gone away, so the heuristic takes over again.
  onPlayersChanged: {
    if (preferredId !== "" && !players.some(p => p.uniqueId === preferredId))
      preferredId = "";
  }

  // MprisPlayer only refreshes `position` when asked, so poll while something
  // is playing and a view is interested. Reading it is computed locally from the
  // last known position and the time since, so a short interval costs no D-Bus
  // round trip - and moves the seek bar smoothly rather than in 1s steps.
  property bool positionWatched: false

  Timer {
    interval: 250
    repeat: true
    running: root.positionWatched && root.isPlaying && root.canSeek
    onTriggered: {
      if (root.active)
        root.active.positionChanged();
    }
  }
}
