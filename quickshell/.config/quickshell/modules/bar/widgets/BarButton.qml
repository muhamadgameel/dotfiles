import QtQuick

import "../../../components" as Components
import "../../../core" as Core

/**
* BarButton - a button at the bar's height, round like the pills it sits in
*/
Components.Button {
  implicitHeight: Core.Style.widgetSize
  radius: height / 2
}
