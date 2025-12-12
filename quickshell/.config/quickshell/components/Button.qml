import QtQuick

import "../config" as Config
import "../core" as Core
import "../services" as Services

/**
* Button - Versatile button component with icon and/or text
*
* Usage:
*   // Icon-only button
*   Button {
*       icon: "settings"
*       onClicked: openSettings()
*   }
*
*   // Text button
*   Button {
*       text: "Submit"
*       onClicked: submit()
*   }
*
*   // Icon + text
*   Button {
*       icon: "save"
*       text: "Save"
*       onClicked: save()
*   }
*
*   // Destructive action (close/delete style)
*   Button {
*       icon: "close"
*       useActiveColorOnHover: true
*       onClicked: close()
*   }
*/
Rectangle {
  id: root

  // === Content Properties ===
  property string icon: ""
  property real iconSize: Core.Style.fontL
  property color iconColor: Config.Theme.text
  property color iconHoverColor: iconColor

  property string text: ""
  property real textSize: Core.Style.fontM
  property color textColor: Config.Theme.text
  property color textHoverColor: textColor

  property real padding: 0

  // === Background Properties ===
  property bool showBackground: true
  property color backgroundColor: Config.Theme.transparent
  property color hoverColor: Config.Theme.surfaceHover
  property color activeColor: Config.Theme.error

  // === Behavior Properties ===
  property bool useActiveColorOnHover: false  // For destructive actions (close, delete)

  // === Tooltip Properties ===
  property string tooltipText: ""
  property string tooltipDirection: "auto"

  // === Signals ===
  signal clicked(var mouse)
  signal wheel(var wheel)
  signal entered
  signal exited

  // === State (readonly) ===
  readonly property bool hovered: mouseArea.containsMouse
  readonly property bool pressed: mouseArea.pressed
  readonly property real spaceBetweenIconAndText: Core.Style.spaceS

  // === Appearance ===
  implicitWidth: (root.icon !== "" ? Core.Style.widgetSize : 0) + (root.text !== "" ? textLabel.implicitWidth + spaceBetweenIconAndText : 0) + padding * 2
  implicitHeight: Core.Style.widgetSize + padding * 2
  radius: Core.Style.radiusS

  color: {
    if (!showBackground)
      return Config.Theme.transparent;
    if (useActiveColorOnHover && hovered)
      return activeColor;
    return hovered ? hoverColor : backgroundColor;
  }

  Behavior on color {
    ColorAnimation {
      duration: Core.Style.animFast
    }
  }

  // === Content ===
  Row {
    anchors.centerIn: parent
    spacing: root.text !== "" ? root.spaceBetweenIconAndText : 0

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.icon !== ""
      name: root.icon
      size: root.iconSize
      color: {
        if (root.useActiveColorOnHover && root.hovered)
          return Config.Theme.bg;
        return root.hovered ? root.iconHoverColor : root.iconColor;
      }

      Behavior on color {
        ColorAnimation {
          duration: Core.Style.animFast
        }
      }
    }

    Label {
      id: textLabel
      anchors.verticalCenter: parent.verticalCenter
      visible: root.text !== ""
      text: root.text
      size: root.textSize
      color: {
        if (root.useActiveColorOnHover && root.hovered)
          return Config.Theme.bg;
        return root.hovered ? root.textHoverColor : root.textColor;
      }

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
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
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
