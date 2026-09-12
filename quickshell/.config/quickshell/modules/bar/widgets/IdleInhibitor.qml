import QtQuick

import "../../../components" as Components
import "../../../core" as Core
import "../../../services" as Services

/**
* IdleInhibitor - keep-awake toggle
*
* Deliberately loud when active: an inhibitor left on by accident drains the
* battery silently, so it gets an accent colour and a pulsing dot rather than a
* subtle state change.
*/
Components.Button {
  id: root

  icon: Services.Idle.statusIcon
  iconSize: Core.Style.fontL
  iconColor: Services.Idle.inhibited ? Core.Theme.warning : Core.Theme.textMuted

  tooltipText: {
    const lines = [Services.Idle.inhibited ? "Keeping the screen awake" : "Idle timeout active"];
    lines.push("");
    lines.push(Services.Idle.inhibited ? "Click to allow sleeping again" : "Click to prevent locking and blanking");
    return lines.join("\n");
  }

  onClicked: Services.Idle.toggle()

  // Unmistakable while it is on.
  Components.StatusDot {
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottomMargin: Core.Style.spaceXXS
    visible: Services.Idle.inhibited
    pulse: true
    color: Core.Theme.warning
  }
}
