import QtQuick

import "../config" as Config

Rectangle {
  id: root

  property bool vertical: false

  implicitWidth: vertical ? 1 : parent.width
  implicitHeight: vertical ? parent.height : 1
  color: Config.Theme.surfaceHover
}
