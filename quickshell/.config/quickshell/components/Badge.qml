import QtQuick

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
  property color textColor: Core.Theme.accent

  // === Count Variant Properties ===
  property int count: 0

  // === Shared Properties ===
  property color backgroundColor: {
    if (variant === "count")
      return Core.Theme.error;
    return Core.Theme.alpha(textColor, Core.Style.opacityTintStrong);
  }

  // === Computed Properties ===
  readonly property bool isTextVariant: variant === "text"
  readonly property bool isCountVariant: variant === "count"
  readonly property string displayText: {
    if (isCountVariant)
      return count > 99 ? "99+" : count.toString();
    return text;
  }

  // === Visibility ===
  visible: isTextVariant ? text !== "" : count > 0

  // === Dimensions ===
  implicitWidth: {
    if (isCountVariant) {
      return count > 0 ? Math.max(Core.Style.px(14), badgeText.implicitWidth + Core.Style.px(6)) : Core.Style.px(8);
    }
    return badgeText.width + Core.Style.spaceM;
  }
  implicitHeight: {
    if (isCountVariant) {
      return count > 0 ? Core.Style.px(14) : Core.Style.px(8);
    }
    return badgeText.height + Core.Style.spaceXS;
  }

  // === Appearance ===
  radius: Core.Style.radiusFull
  color: backgroundColor

  Behavior on implicitWidth {
    NumberAnimation {
      duration: Core.Style.duration(Core.Style.animFast)
      easing.type: Core.Style.easeStandard
    }
  }

  Behavior on implicitHeight {
    NumberAnimation {
      duration: Core.Style.duration(Core.Style.animFast)
      easing.type: Core.Style.easeStandard
    }
  }

  // === Text Content ===
  // QtQuick's Text, so the family is set explicitly - see Button.qml.
  Text {
    id: badgeText
    anchors.centerIn: parent
    text: root.displayText
    font.family: Core.Style.fontFamily
    font.pixelSize: Core.Style.fontS
    font.weight: root.isCountVariant ? Font.Bold : Font.Normal
    color: root.isCountVariant ? Core.Theme.bg : root.textColor
    visible: root.isTextVariant || root.count > 0
  }
}
