import QtQuick

import "../../../components" as Components
import "../../../config" as Config
import "../../../core" as Core
import "../../../services" as Services

/**
* Clock - the time, and the way in to the calendar
*
* Left click opens the calendar panel.
*/
Item {
  id: root

  signal calendarRequested

  implicitWidth: content.implicitWidth
  implicitHeight: Core.Style.widgetSize

  Components.Text {
    id: content
    anchors.centerIn: parent
    text: Config.Config.barClockShowSeconds ? Services.Time.timeLong : Services.Time.timeShort
    size: Core.Style.fontL
    weight: Core.Style.weightBold
  }

  Component.onDestruction: Services.Tooltip.forget(root)

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onEntered: {
      const weather = Services.Weather.ready ? `\n${Services.Weather.statusText}` : "";
      Services.Tooltip.show(root, `${Services.Time.dateLong}${weather}`, "bottom");
    }

    onExited: {
      Services.Tooltip.hide(root);
    }

    acceptedButtons: Qt.LeftButton

    onClicked: root.calendarRequested()
  }
}
