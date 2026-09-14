import QtQuick

import "../../../components" as Components
import "../../../core" as Core
import "../../../services" as Services

/**
* Media - play/pause indicator for the current player
*
* Just the icon; the track is in the tooltip. A scrolling title took up to
* 220px of the bar.
*
* - Left click:   open the media panel
* - Middle click: play/pause
* - Right click:  next track
* - Scroll:       volume, where the player supports it
*/
Components.Button {
  id: root

  signal panelRequested

  icon: Services.Media.statusIcon
  iconSize: Core.Style.fontL
  iconColor: Services.Media.isPlaying ? Core.Theme.accent : Core.Theme.textDim

  tooltipText: {
    const m = Services.Media;
    const lines = [m.trackTitle, m.trackArtist, m.trackAlbum].filter(line => line !== "");
    if (m.identity !== "")
      lines.push(`— ${m.identity}`);

    lines.push("");
    lines.push("Left click: Open media panel");
    lines.push("Middle click: Play/pause");
    lines.push("Right click: Next track");
    if (m.volumeSupported)
      lines.push(`Scroll: Volume (${Math.round(m.volume * 100)}%)`);
    return lines.join("\n");
  }

  onClicked: function (button) {
    if (button === Qt.MiddleButton)
      Services.Media.playPause();
    else if (button === Qt.RightButton)
      Services.Media.next();
    else
      root.panelRequested();
  }

  onWheel: function (wheel) {
    if (!Services.Media.volumeSupported)
      return;
    const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
    Services.Media.setVolume(Services.Media.volume + delta);
  }
}
