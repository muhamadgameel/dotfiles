import QtQuick

import "../../../components" as Components
import "../../../core" as Core
import "../../../services" as Services

/**
* Microphone - Bar widget for the default audio input
*
* Just the icon, red while muted, as in the mic OSD; the level is in the
* tooltip.
*
* Reads Audio.hasSource rather than sourceReady. Connecting a Bluetooth headset
* swaps the default source, and binding to the raw flag made the widget flash
* "off / --" for the duration of the swap.
*/
Components.Button {
  id: root

  signal panelRequested

  icon: Services.Audio.getMicIcon()

  iconColor: {
    if (!Services.Audio.hasSource)
      return Core.Theme.textMuted;
    return Services.Audio.micMuted ? Core.Theme.error : Core.Theme.text;
  }
  iconSize: Core.Style.fontL

  tooltipText: {
    if (!Services.Audio.hasSource)
      return "No microphone";
    const name = Services.Audio.deviceName(Services.Audio.source);
    const level = Math.round(Services.Audio.micVolume * 100);
    const lines = [Services.Audio.micMuted ? `${name} (muted)` : `${name}: ${level}%`];
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
