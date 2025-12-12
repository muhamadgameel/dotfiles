import QtQuick
import QtQuick.Layouts

import "../../../components" as Components
import "../../../config" as Config
import "../../../core" as Core
import "../../../services" as Services

Item {
  id: root

  implicitWidth: content.implicitWidth
  implicitHeight: parent.height

  RowLayout {
    id: content
    anchors.centerIn: parent
    spacing: Core.Style.spaceS

    // Time
    Components.Label {
      text: Services.Time.timeLong
      size: Core.Style.fontL
      font.weight: Core.Style.weightBold
    }

    // Separator
    Components.Divider {
      vertical: true
      Layout.preferredHeight: Core.Style.fontL
    }

    // Date
    Components.Label {
      text: Services.Time.dateShort
      size: Core.Style.fontM
      color: Config.Theme.textDim
      font.weight: Core.Style.weightNormal
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onEntered: {
      Services.Tooltip.show(root, Services.Time.dateLong, "bottom");
    }

    onExited: {
      Services.Tooltip.hide();
    }

    onClicked: {
      Core.Logger.d("Clock", "Clicked - show calendar panel");
      // TODO: Open calendar panel
    }
  }
}
