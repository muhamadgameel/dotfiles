import QtQuick

import "../../../components" as Components
import "../../../core" as Core
import "../../../services" as Services

/**
* Volume - Bar widget for the default audio output
*
* Reads Audio.hasSink rather than sinkReady: a device swap (AirPods, docking)
* tears down the old node before the new one is ready, and the raw flag made
* the readout blank mid-swap. See services/Audio.qml.
*/
Components.Button {
  id: root

  signal panelRequested

  icon: {
    if (Services.Audio.isHeadphones)
      return (Services.Audio.muted || Services.Audio.volume === 0) ? "headphones-off" : "headphones";
    return Services.Audio.getVolumeIcon();
  }

  iconColor: Services.Audio.muted ? Core.Theme.textMuted : Core.Theme.text
  iconSize: Core.Style.fontL

  text: Services.Audio.hasSink ? Math.round(Services.Audio.volume * 100) + "%" : "--"

  textColor: {
    if (Services.Audio.muted)
      return Core.Theme.textMuted;
    // Above unity gain is where clipping starts, so it is worth flagging.
    return Services.Audio.volume > 1.0 ? Core.Theme.warning : Core.Theme.text;
  }

  tooltipText: {
    const name = Services.Audio.deviceName(Services.Audio.sink);
    const lines = [Services.Audio.muted ? `${name} (muted)` : name];
    lines.push("");
    lines.push("Scroll: Adjust volume");
    lines.push("Left click: Open sound panel");
    lines.push("Right click: Toggle mute");
    return lines.join("\n");
  }

  // Scroll to change volume
  onWheel: function (wheel) {
    const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
    Services.Audio.setVolume(Services.Audio.volume + delta);
  }

  onClicked: function (button) {
    if (button === Qt.LeftButton) {
      root.panelRequested();
    } else if (button === Qt.RightButton) {
      Services.Audio.toggleMute();
    }
  }
}
