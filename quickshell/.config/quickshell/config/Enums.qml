pragma Singleton

import QtQuick
import Quickshell

/**
* Enums - shared enumerations
*
* QML enums have to live on a type, and a value has to be reachable as
* Type.Enum.Value. Putting them on one singleton keeps the numbers out of the
* services that raise them and the components that render them, so neither side
* can drift.
*
* Usage:
*   Config.Enums.Urgency.Critical
*/
Singleton {
  id: root

  enum Urgency {
    Low = 0,
    Normal = 1,
    Critical = 2
  }
}
