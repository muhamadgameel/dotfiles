import QtQuick

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
*/
Rectangle {
  id: root

  activeFocusOnTab: root.enabled

  // === Variant ===
  property string variant: "default"  // "default", "primary", "secondary", "danger"

  // === Content Properties ===
  property string icon: ""
  property real iconSize: Core.Style.fontL
  property bool iconSpinning: false

  property string text: ""
  property real textSize: Core.Style.fontM

  property real padding: Core.Style.spaceS

  // === Color Properties (for easy customization) ===
  property color iconColor: Core.Theme.transparent
  property color textColor: Core.Theme.transparent
  property color backgroundColor: Core.Theme.transparent
  property color hoverColor: Core.Theme.transparent

  // === Tooltip Properties ===
  property string tooltipText: ""
  property string tooltipDirection: "auto"

  // === Signals ===
  signal clicked(int button)
  signal wheel(var wheel)

  // === State (readonly) ===
  readonly property bool hovered: mouseArea.containsMouse

  // === Computed Colors Based on Variant ===
  readonly property color _backgroundColor: {
    if (!Qt.colorEqual(backgroundColor, Core.Theme.transparent))
      return backgroundColor;
    switch (variant) {
    case "primary":
      return Core.Theme.accent;
    case "secondary":
      return Core.Theme.surface;
    default:
      return Core.Theme.transparent;
    }
  }

  readonly property color _hoverColor: {
    if (!Qt.colorEqual(hoverColor, Core.Theme.transparent))
      return hoverColor;
    switch (variant) {
    case "primary":
      return Core.Theme.accentHover;
    case "secondary":
      return Core.Theme.surfaceHover;
    case "danger":
      return Core.Theme.error;
    default:
      return Core.Theme.surfaceHover;
    }
  }

  // Icon and label share this unless iconColor or textColor is set.
  readonly property color _contentColor: {
    switch (variant) {
    case "primary":
      return Core.Theme.bg;
    case "danger":
      return hovered ? Core.Theme.bg : Core.Theme.text;
    default:
      return Core.Theme.text;
    }
  }

  readonly property color _iconColor: Qt.colorEqual(iconColor, Core.Theme.transparent) ? _contentColor : iconColor
  readonly property color _textColor: Qt.colorEqual(textColor, Core.Theme.transparent) ? _contentColor : textColor

  // === Internal ===
  readonly property bool hasText: text !== ""
  readonly property bool hasIcon: icon !== ""
  readonly property real spaceBetweenIconAndText: Core.Style.spaceS

  // === Appearance ===
  implicitWidth: (hasIcon ? root.iconSize : 0) + (hasText ? textLabel.implicitWidth : 0) + (hasIcon && hasText ? spaceBetweenIconAndText : 0) + padding * 2
  implicitHeight: root.iconSize + padding * 2
  radius: Core.Style.radiusS

  opacity: enabled ? 1.0 : Core.Style.opacityDisabled

  Behavior on opacity {
    NumberAnimation {
      duration: Core.Style.duration(Core.Style.animFast)
      easing.type: Core.Style.easeStandard
    }
  }

  // Fades from the hover colour at zero alpha rather than from `transparent`,
  // which would run the channels through black mid-fade. See Theme.transparentOf.
  readonly property color _effectiveBackground: Qt.colorEqual(_backgroundColor, Core.Theme.transparent) ? Core.Theme.transparentOf(_hoverColor) : _backgroundColor

  color: hovered ? _hoverColor : _effectiveBackground

  Behavior on color {
    ColorAnimation {
      duration: Core.Style.duration(Core.Style.animFast)
      easing.type: Core.Style.easeStandard
    }
  }

  // === Content ===
  Row {
    anchors.centerIn: parent
    spacing: root.hasIcon && root.hasText ? root.spaceBetweenIconAndText : 0

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.icon !== ""
      icon: root.icon
      size: root.iconSize
      spinning: root.iconSpinning
      color: root._iconColor
    }

    Text {
      id: textLabel
      // QtQuick's Text, not components/Text, whose colour fade would lag the
      // button's own hover colours. That means setting the family here: without
      // it the label fell back to the system sans (Noto Sans).
      anchors.verticalCenter: parent.verticalCenter
      visible: root.text !== ""
      text: root.text
      font.family: Core.Style.fontFamily
      font.pixelSize: root.textSize
      font.weight: Core.Style.weightMedium
      color: root._textColor
    }
  }

  // Keyboard focus was invisible everywhere except TextField, which made the
  // shell effectively unusable without a pointer. Drawn outside the control so
  // it never eats into the content box.
  Rectangle {
    anchors.fill: parent
    anchors.margins: -Core.Style.focusRingOffset
    z: -1

    visible: root.activeFocus
    color: Core.Theme.transparent
    radius: parent.radius + Core.Style.focusRingOffset
    border.color: Core.Theme.focusRing
    border.width: Core.Style.focusRingWidth
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
      if (root.tooltipText !== "") {
        Services.Tooltip.show(root, root.tooltipText, root.tooltipDirection);
      }
    }

    onExited: Services.Tooltip.hide()
  }

  // Repeater and Variants delegates get destroyed while still hovered, which
  // would otherwise leave the tooltip service tracking a dead item.
  Component.onDestruction: Services.Tooltip.forget(root)
}
