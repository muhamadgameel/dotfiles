import QtQuick

import "../../../components" as Components
import "../../../config" as Config
import "../../../core" as Core
import "../../../services" as Services

Components.Button {
  id: root

  signal panelRequested

  icon: {
    // Headphone icons
    if (!Services.Audio.sinkReady)
      return Services.Audio.isHeadphones ? "headphones-off" : "volume-off";

    if (Services.Audio.isHeadphones) {
      if (Services.Audio.muted || Services.Audio.volume === 0)
        return "headphones-off";
      return "headphones";
    }

    // Speaker icons
    if (Services.Audio.muted)
      return "volume-mute";
    if (Services.Audio.volume === 0)
      return "volume-off";
    if (Services.Audio.volume < 0.33)
      return "volume-low";
    if (Services.Audio.volume < 0.66)
      return "volume-medium";
    return "volume-high";
  }

  iconColor: Services.Audio.muted ? Config.Theme.textMuted : Config.Theme.text
  iconSize: Core.Style.fontL

  text: Services.Audio.sinkReady ? Math.round(Services.Audio.volume * 100) + "%" : "--"
  textColor: Services.Audio.muted ? Config.Theme.textMuted : Config.Theme.text

  tooltipText: Services.Audio.deviceName(Services.Audio.sink)

  // Scroll to change volume
  onWheel: function (wheel) {
    let delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
    Services.Audio.setVolume(Services.Audio.volume + delta);
  }

  // Click handlers
  onClicked: function (button) {
    if (button === Qt.LeftButton) {
      root.panelRequested();
    } else if (button === Qt.MiddleButton) {
      Services.Audio.toggleMute();
    }
  }
}
