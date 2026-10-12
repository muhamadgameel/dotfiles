import QtQuick

import "../../../components" as Components
import "../../../core" as Core
import "../../../services" as Services

/**
* Microphone - Bar widget for the default audio input
*
* Just the icon, red while muted, as in the mic OSD; the level is in the
* tooltip. A dot shows while an app records.
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

  tooltipText: {
    if (!Services.Audio.hasSource)
      return "No microphone";
    const name = Services.Audio.deviceName(Services.Audio.source);
    const level = Math.round(Services.Audio.micVolume * 100);
    const lines = [Services.Audio.micMuted ? `${name} (muted)` : `${name}: ${level}%`];
    if (Services.Privacy.micInUse)
      lines.push(`In use by ${Services.Privacy.micUsers.join(", ")}`);
    lines.push("");
    lines.push("Scroll: Adjust level");
    lines.push("Left click: Open sound panel");
    lines.push("Middle click: Toggle mute");
    return lines.join("\n");
  }

  acceptedButtons: Qt.LeftButton | Qt.MiddleButton
  onClicked: function (button) {
    if (button === Qt.LeftButton) {
      root.panelRequested();
    } else if (button === Qt.MiddleButton) {
      Services.Audio.toggleMicMute();
    }
  }

  Components.StatusDot {
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.margins: Core.Style.spaceXS
    visible: Services.Privacy.micInUse
    color: Core.Theme.warning
  }

  Components.WheelSteps {
    onScrolled: steps => Services.Audio.setMicVolume(Services.Audio.micVolume + steps * 0.05)
  }
}
