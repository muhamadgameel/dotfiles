import QtQuick
import "../components" as Components

import "../config" as Config
import "../core" as Core

/**
* Spinner - Rotating loading indicator
*
* A simple spinning icon for loading states.
* Extracted from Icon.spinning for standalone use.
*
* Usage:
*   // Basic spinner
*   Spinner { running: isLoading }
*
*   // Custom size and color
*   Spinner {
*       running: true
*       size: 24
*       color: Theme.accent
*   }
*
*   // Custom speed
*   Spinner {
*       running: true
*       duration: 500  // Faster spin
*   }
*/
Item {
  id: root

  // === Properties ===
  property bool running: true
  property real size: Core.Style.fontL
  property color color: Config.Theme.text
  property int duration: 1000
  property string icon: "loading"

  // === Dimensions ===
  implicitWidth: size
  implicitHeight: size

  visible: running

  Components.Icon {
    icon: root.icon
    size: root.size
    color: root.color
    spinning: root.running && root.visible
    spinDuration: root.duration
  }
}
