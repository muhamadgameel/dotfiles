import QtQuick

import "../../../components" as Components
import "../../../core" as Core
import "../../../services" as Services

/**
* Indicators - what is capturing the screen right now
*
* Shown only while something is. A click stops the recording.
*/
Components.Button {
  icon: "video"
  iconColor: Core.Theme.error
  tooltipText: "Recording the screen\n\nClick: Stop and save"
  onClicked: Services.Recorder.stop()
}
