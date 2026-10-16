import QtQuick

import "../core" as Core

// A PropertyAnimation, so it animates colours as well as numbers.
PropertyAnimation {
  duration: Core.Style.duration(Core.Style.animFast)
  easing.type: Core.Style.easeStandard
}
