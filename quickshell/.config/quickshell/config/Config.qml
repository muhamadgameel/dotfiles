pragma Singleton

import QtQuick
import Quickshell

Singleton {
  id: root

  // === Feature Toggles ===
  readonly property bool animationsEnabled: true
  readonly property bool debugMode: true

  // === Bar Configuration ===
  readonly property string barPosition: "top"
  readonly property bool barShowClock: true
  readonly property bool barShowVolume: true
  readonly property bool barShowMicrophone: true
  readonly property bool barShowBrightness: true
  readonly property bool barShowLauncher: true
  readonly property bool barShowNotification: true

  // === OSD Configuration ===
  readonly property string osdPosition: "top_right"
  readonly property int osdDuration: 2000
  readonly property bool osdEnabled: true

  // === Panel Configuration ===
  readonly property bool panelBackdropEnabled: true
  readonly property real panelBackdropOpacity: 0.3

  // === Tooltip Configuration ===
  readonly property int tooltipDelay: 500
  readonly property int tooltipMaxWidth: 320
}
