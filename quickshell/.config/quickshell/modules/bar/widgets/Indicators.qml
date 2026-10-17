import QtQuick
import QtQuick.Layouts

import "../../../core" as Core
import "../../../services" as Services

/**
* Indicators - what is capturing the screen right now
*
* One icon each, shown only while it is true. A click stops the recording; a
* share ends in the app that shares.
*/
RowLayout {
  spacing: Core.Style.spaceXS

  BarButton {
    visible: Services.Recorder.recording
    icon: "video"
    iconColor: Core.Theme.error
    tooltipText: "Recording the screen\n\nClick: Stop and save"
    onClicked: Services.Recorder.stop()
  }

  BarButton {
    visible: Services.Privacy.screenShared
    icon: "monitor"
    iconColor: Core.Theme.warning
    tooltipText: "An app is sharing the screen or a window"
  }
}
