import QtQuick

import "../config" as Config
import "../core" as Core

/**
* Badge - Versatile badge component for status, tags, and counts
*
* Supports two variants:
* - "text": Pill-shaped label for status or tags
* - "count": Compact notification count badge
*
* Usage:
*   // Text badge (default)
*   Badge {
*       text: "Connected"
*       textColor: Theme.success
*   }
*
*   // Count badge
*   Badge {
*       variant: "count"
*       count: 5
*   }
*
*   // Count badge with custom color
*   Badge {
*       variant: "count"
*       count: notifications.length
*       backgroundColor: Theme.accent
*   }
*/
Rectangle {
  id: root

  // === Variant ===
  property string variant: "text"  // "text" or "count"

  // === Text Variant Properties ===
  property string text: ""
  property color textColor: Config.Theme.accent
  property real fontSize: Core.Style.fontS

  // === Count Variant Properties ===
  property int count: 0
  property int maxCount: 99

  // === Shared Properties ===
  property color backgroundColor: {
    if (variant === "count")
      return Config.Theme.error;
    return Config.Theme.alpha(textColor, 0.2);
  }
  property color borderColor: Config.Theme.transparent
  property int borderWidth: 0

  // === Computed Properties ===
  readonly property bool isTextVariant: variant === "text"
  readonly property bool isCountVariant: variant === "count"
  readonly property string displayText: {
    if (isCountVariant)
      return count > maxCount ? maxCount + "+" : count.toString();
    return text;
  }

  // === Visibility ===
  visible: isTextVariant ? text !== "" : count > 0

  // === Dimensions ===
  implicitWidth: {
    if (isCountVariant) {
      return count > 0 ? Math.max(14, badgeText.implicitWidth + 6) : 8;
    }
    return badgeText.width + Core.Style.spaceM;
  }
  implicitHeight: {
    if (isCountVariant) {
      return count > 0 ? 14 : 8;
    }
    return badgeText.height + Core.Style.spaceXS;
  }

  // === Appearance ===
  radius: implicitHeight / 2
  color: backgroundColor
  border.color: borderColor
  border.width: borderWidth

  Behavior on width {
    NumberAnimation {
      duration: Core.Style.animFast
    }
  }

  // === Text Content ===
  Text {
    id: badgeText
    anchors.centerIn: parent
    text: root.displayText
    font.pixelSize: root.fontSize
    font.weight: root.isCountVariant ? Font.Bold : Font.Normal
    color: root.isCountVariant ? Config.Theme.bg : root.textColor
    visible: root.isTextVariant || root.count > 0
  }
}
