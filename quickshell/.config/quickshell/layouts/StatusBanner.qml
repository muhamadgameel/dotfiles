import QtQuick
import QtQuick.Layouts

import "../components" as Components
import "../config" as Config
import "../core" as Core

/**
* StatusBanner - Displays a status message in a colored banner
*
* Supports multiple types: error, warning, success, info
*
* Usage:
*   StatusBanner {
*       visible: hasStatus
*       type: "warning"
*       message: statusMessage
*   }
*/
Rectangle {
  id: root

  // Type can be: "error", "warning", "success", "info"
  property string type: "error"
  property string message: ""
  property string icon: _defaultIcon

  // Internal: resolve color based on type
  readonly property color _statusColor: {
    switch (type) {
    case "success":
      return Config.Theme.success;
    case "warning":
      return Config.Theme.warning;
    case "info":
      return Config.Theme.accentAlt;
    case "error":
      return Config.Theme.error;
    default:
      return Config.Theme.overlay;
    }
  }

  // Internal: default icon based on type
  readonly property string _defaultIcon: {
    switch (type) {
    case "success":
      return "check";
    case "warning":
      return "warning";
    case "info":
      return "info";
    case "error":
      return "error";
    default:
      return "question";
    }
  }

  implicitHeight: visible ? content.height + Core.Style.spaceS * 2 : 0
  radius: Core.Style.radiusS
  color: Config.Theme.alpha(_statusColor, 0.2)

  RowLayout {
    id: content
    anchors {
      left: parent.left
      right: parent.right
      verticalCenter: parent.verticalCenter
      margins: Core.Style.spaceM
    }
    spacing: Core.Style.spaceS

    Components.Icon {
      icon: root.icon
      size: Core.Style.fontL
      color: root._statusColor
      Layout.alignment: Qt.AlignCenter
    }

    Components.Text {
      Layout.fillWidth: true
      text: root.message
      color: root._statusColor
      size: Core.Style.fontM
      wrapMode: Text.Wrap
    }
  }
}
