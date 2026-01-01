import QtQuick

import "../config" as Config
import "../core" as Core
import "../services" as Services

/**
* Button - Versatile button component with icon and/or text
*
* Supports multiple variants for different use cases:
* - "default": Transparent background, hover highlight
* - "primary": Accent colored background
* - "secondary": Surface colored background
* - "danger": Error colored, for destructive actions
* - "ghost": No background, subtle hover
*
* Usage:
*   // Icon-only button
*   Button {
*       icon: "settings"
*       onClicked: openSettings()
*   }
*
*   // Primary button
*   Button {
*       variant: "primary"
*       text: "Submit"
*       onClicked: submit()
*   }
*
*   // Danger button
*   Button {
*       variant: "danger"
*       icon: "trash"
*       text: "Delete"
*       onClicked: delete()
*   }
*
*   // Ghost button
*   Button {
*       variant: "ghost"
*       icon: "close"
*       onClicked: close()
*   }
*/
Rectangle {
  id: root

  // === Variant ===
  property string variant: "default"  // "default", "primary", "secondary", "danger", "ghost"

  // === Content Properties ===
  property string icon: ""
  property real iconSize: Core.Style.fontL
  property bool iconSpinning: false

  property string text: ""
  property real textSize: Core.Style.fontM

  // property real padding: Core.Style.spaceS
  property real padding: Core.Style.spaceS

  // === Color Properties (for easy customization) ===
  property color iconColor: Config.Theme.transparent
  property color textColor: Config.Theme.transparent
  property color backgroundColor: Config.Theme.transparent
  property color hoverColor: Config.Theme.transparent

  // === Tooltip Properties ===
  property string tooltipText: ""
  property string tooltipDirection: "auto"

  // === Behavior Properties ===
  property bool enabled: true

  // === Signals ===
  signal clicked(var mouse)
  signal wheel(var wheel)
  signal entered
  signal exited

  // === State (readonly) ===
  readonly property bool hovered: mouseArea.containsMouse
  readonly property bool pressed: mouseArea.pressed

  // === Computed Colors Based on Variant ===
  readonly property color _backgroundColor: {
    if (backgroundColor !== Config.Theme.transparent)
      return backgroundColor;
    switch (variant) {
    case "primary":
      return Config.Theme.accent;
    case "secondary":
      return Config.Theme.surface;
    case "danger":
      return Config.Theme.transparent;
    case "ghost":
      return Config.Theme.transparent;
    default:
      return Config.Theme.transparent;
    }
  }

  readonly property color _hoverColor: {
    if (hoverColor !== Config.Theme.transparent)
      return hoverColor;
    switch (variant) {
    case "primary":
      return Config.Theme.lighten(Config.Theme.accent, 0.1);
    case "secondary":
      return Config.Theme.surfaceHover;
    case "danger":
      return Config.Theme.error;
    case "ghost":
      return Config.Theme.alpha(Config.Theme.text, 0.1);
    default:
      return Config.Theme.surfaceHover;
    }
  }

  readonly property color _iconColor: {
    if (iconColor !== Config.Theme.transparent)
      return iconColor;
    switch (variant) {
    case "primary":
      return Config.Theme.bg;
    case "danger":
      return hovered ? Config.Theme.bg : Config.Theme.text;
    default:
      return Config.Theme.text;
    }
  }

  readonly property color _textColor: {
    if (textColor !== Config.Theme.transparent)
      return textColor;
    switch (variant) {
    case "primary":
      return Config.Theme.bg;
    case "danger":
      return hovered ? Config.Theme.bg : Config.Theme.text;
    default:
      return Config.Theme.text;
    }
  }

  // === Internal ===
  readonly property bool hasText: text !== ""
  readonly property bool hasIcon: icon !== ""
  readonly property real spaceBetweenIconAndText: Core.Style.spaceS

  // === Appearance ===
  implicitWidth: (hasIcon ? root.iconSize : 0) + (hasText ? textLabel.implicitWidth : 0) + (hasIcon && hasText ? spaceBetweenIconAndText : 0) + padding * 2
  implicitHeight: root.iconSize + padding * 2
  radius: Core.Style.radiusS

  opacity: enabled ? 1.0 : 0.5

  // Use hoverColor's RGB with 0 alpha when transparent to prevent black flash during animation
  readonly property color _effectiveBackground: _backgroundColor == Config.Theme.transparent ? Qt.rgba(_hoverColor.r, _hoverColor.g, _hoverColor.b, 0) : _backgroundColor

  color: hovered ? _hoverColor : _effectiveBackground

  Behavior on color {
    ColorAnimation {
      duration: Core.Style.animFast
    }
  }

  // === Content ===
  Row {
    anchors.centerIn: parent
    spacing: hasIcon && hasText ? spaceBetweenIconAndText : 0

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.icon !== ""
      icon: root.icon
      size: root.iconSize
      spinning: root.iconSpinning
      color: root._iconColor

      Behavior on color {
        ColorAnimation {
          duration: Core.Style.animFast
        }
      }
    }

    Text {
      id: textLabel
      anchors.verticalCenter: parent.verticalCenter
      visible: root.text !== ""
      text: root.text
      font.pixelSize: root.textSize
      font.weight: Core.Style.weightMedium
      color: root._textColor

      Behavior on color {
        ColorAnimation {
          duration: Core.Style.animFast
        }
      }
    }
  }

  // === Mouse Handling ===
  MouseArea {
    id: mouseArea
    anchors.fill: parent
    enabled: root.enabled
    hoverEnabled: true
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    onClicked: mouse => root.clicked(mouse.button)
    onWheel: wheel => root.wheel(wheel)

    onEntered: {
      root.entered();
      if (root.tooltipText !== "") {
        Services.Tooltip.show(root, root.tooltipText, root.tooltipDirection);
      }
    }

    onExited: {
      root.exited();
      Services.Tooltip.hide();
    }
  }
}
