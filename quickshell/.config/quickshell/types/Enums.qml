pragma Singleton

import QtQuick
import Quickshell

/*
* Enums - Centralized type definitions
* Single source of truth for all enum types used across the shell
*/
Singleton {
  id: root

  enum Urgency {
    Low = 0,
    Normal = 1,
    Critical = 2
  }
}
