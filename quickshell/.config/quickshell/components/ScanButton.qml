import QtQuick
import "../core" as Core

import "." as Components

/**
* ScanButton - refresh button that spins while a scan runs
*
* Disabled for the length of the scan, so it cannot be re-triggered and dims
* through Button's own disabled state.
*
* Usage:
*   ScanButton {
*       scanning: Services.Network.scanning
*       tooltipText: "Scan for networks"
*       onClicked: Services.Network.scan()
*   }
*/
Components.Button {
  id: root

  property bool scanning: false

  icon: "refresh"
  iconSize: Core.Style.fontM
  iconSpinning: root.scanning
  enabled: !root.scanning
}
