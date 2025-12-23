import QtQuick
import QtQuick.Layouts

import "../components" as Components
import "../config" as Config
import "../core" as Core

/**
* ErrorBanner - Displays an error message in a red-tinted banner
*
* Used for showing error states and notifications
*/
Rectangle {
  id: root

  property string message: ""

  implicitHeight: visible ? errorText.height + Core.Style.spaceS * 2 : 0
  radius: Core.Style.radiusS
  color: Config.Theme.alpha(Config.Theme.error, 0.2)

  Components.Label {
    id: errorText
    anchors.centerIn: parent
    text: "⚠ " + root.message
    color: Config.Theme.error
    size: Core.Style.fontS
  }
}
