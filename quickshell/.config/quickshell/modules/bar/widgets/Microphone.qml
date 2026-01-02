import QtQuick

import "../../../components" as Components
import "../../../config" as Config
import "../../../core" as Core
import "../../../services" as Services

Components.Button {
  id: root

  signal panelRequested

  icon: {
    if (!Services.Audio.sourceReady)
      return "microphone-off";
    if (Services.Audio.micMuted || Services.Audio.micVolume === 0)
      return "microphone-off";
    if (Services.Audio.micVolume < 0.33)
      return "microphone";
    if (Services.Audio.micVolume < 0.66)
      return "microphone";
    return "microphone";
  }

  iconColor: Services.Audio.micMuted ? Config.Theme.textMuted : Config.Theme.text
  iconSize: Core.Style.fontL

  text: Services.Audio.sourceReady ? Services.Audio.micMuted ? "" : Math.round(Services.Audio.micVolume * 100) + "%" : "--"

  textColor: Services.Audio.micMuted ? Config.Theme.textMuted : Config.Theme.text

  tooltipText: Services.Audio.deviceName(Services.Audio.source)

  // Scroll to change mic volume
  onWheel: function (wheel) {
    let delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
    Services.Audio.setMicVolume(Services.Audio.micVolume + delta);
  }

  // Click handlers
  onClicked: function (button) {
    if (button === Qt.LeftButton) {
      root.panelRequested();
    } else if (button === Qt.MiddleButton) {
      Services.Audio.toggleMicMute();
    }
  }
}
