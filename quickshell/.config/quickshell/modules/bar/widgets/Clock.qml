import QtQuick
import QtQuick.Layouts

import "../../../components" as Components
import "../../../config" as Config
import "../../../core" as Core
import "../../../services" as Services

/**
* Clock - time and date, and the way in to the calendar
*
* Left click opens the calendar panel.
*/
Item {
  id: root

  signal calendarRequested

  implicitWidth: content.implicitWidth
  implicitHeight: Core.Style.widgetSize

  RowLayout {
    id: content
    anchors.centerIn: parent
    spacing: Core.Style.spaceS

    // Time
    Components.Text {
      text: Config.Config.barClockShowSeconds ? Services.Time.timeLong : Services.Time.timeShort
      size: Core.Style.fontL
      weight: Core.Style.weightBold
    }

    // Separator
    Components.Divider {
      vertical: true
      Layout.preferredHeight: Core.Style.fontL
    }

    // Date
    Components.Text {
      text: Services.Time.dateShort
      size: Core.Style.fontM
      color: Core.Theme.textDim
      weight: Core.Style.weightNormal
    }
  }

  Component.onDestruction: Services.Tooltip.forget(root)

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onEntered: {
      Services.Tooltip.show(root, `${Services.Time.dateLong}\n\nClick: Calendar`, "bottom");
    }

    onExited: {
      Services.Tooltip.hide();
    }

    acceptedButtons: Qt.LeftButton

    onClicked: root.calendarRequested()
  }
}
