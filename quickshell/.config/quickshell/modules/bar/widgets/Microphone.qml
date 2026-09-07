import QtQuick

import "../../../components" as Components
import "../../../config" as Config
import "../../../core" as Core
import "../../../services" as Services

/**
* Microphone - Bar widget for the default audio input
*
* Reads Audio.hasSource rather than sourceReady. Connecting a Bluetooth headset
* swaps the default source, and binding to the raw flag made the widget flash
* "off / --" for the duration of the swap.
*/
Components.Button {
  id: root

  signal panelRequested

  icon: Services.Audio.getMicIcon()

  iconColor: Services.Audio.micMuted ? Config.Theme.textMuted : Config.Theme.text
  iconSize: Core.Style.fontL

  text: {
    if (!Services.Audio.hasSource)
      return "--";
    if (Services.Audio.micMuted)
      return "";
    return Math.round(Services.Audio.micVolume * 100) + "%";
  }

  textColor: Services.Audio.micMuted ? Config.Theme.textMuted : Config.Theme.text

  tooltipText: {
    const name = Services.Audio.deviceName(Services.Audio.source);
    const lines = [Services.Audio.micMuted ? `${name} (muted)` : name];
    lines.push("");
    lines.push("Scroll: Adjust level");
    lines.push("Left click: Open sound panel");
    lines.push("Middle click: Toggle mute");
    return lines.join("\n");
  }

  // Scroll to change mic volume
  onWheel: function (wheel) {
    const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
    Services.Audio.setMicVolume(Services.Audio.micVolume + delta);
  }

  onClicked: function (button) {
    if (button === Qt.LeftButton) {
      root.panelRequested();
    } else if (button === Qt.MiddleButton) {
      Services.Audio.toggleMicMute();
    }
  }
}
