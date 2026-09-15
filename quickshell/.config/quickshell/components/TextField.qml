import QtQuick
import QtQuick.Layouts

import "../core" as Core

/**
* TextField - Reusable text input field with placeholder and focus styling
*
* Usage:
*   // Basic text input
*   TextField {
*       placeholder: "Enter text..."
*       onAccepted: handleSubmit()
*   }
*
*   // Password field
*   TextField {
*       placeholder: "Enter password..."
*       echoMode: TextInput.Password
*       onAccepted: login()
*   }
*
*   // With initial value
*   TextField {
*       text: "Default value"
*       placeholder: "Enter name..."
*   }
*/
Rectangle {
  id: root

  // === Content Properties ===
  property string text: ""
  property string placeholder: ""
  property int echoMode: TextInput.Normal  // Normal, Password, NoEcho, PasswordEchoOnEdit

  // === Layout Properties ===
  Layout.fillWidth: true
  Layout.preferredHeight: Core.Style.widgetSize + Core.Style.spaceS

  // === Signals ===
  signal accepted  // Emitted when Enter/Return is pressed
  signal cancelled  // Emitted when Escape is pressed

  // === Appearance ===
  radius: Core.Style.radiusS
  color: Core.Theme.bgDark
  border {
    color: textInput.activeFocus ? Core.Theme.accent : Core.Theme.surfaceHover
    width: Core.Style.borderThin
  }

  Behavior on border.color {
    ColorAnimation {
      duration: Core.Style.duration(Core.Style.animFast)
      easing.type: Core.Style.easeStandard
    }
  }

  // === Text Input ===
  TextInput {
    id: textInput
    anchors.fill: parent
    anchors.leftMargin: Core.Style.spaceS
    anchors.rightMargin: Core.Style.spaceS
    verticalAlignment: TextInput.AlignVCenter
    color: Core.Theme.text
    echoMode: root.echoMode
    // Set explicitly: QtQuick's input falls back to the system sans otherwise.
    font.family: Core.Style.fontFamily
    font.pixelSize: Core.Style.fontM
    clip: true
    selectByMouse: true

    text: root.text

    onTextChanged: {
      root.text = textInput.text;
    }

    Keys.onReturnPressed: root.accepted()
    Keys.onEnterPressed: root.accepted()
    Keys.onEscapePressed: root.cancelled()

    // Placeholder text
    Text {
      anchors.fill: parent
      verticalAlignment: Text.AlignVCenter
      text: root.placeholder
      color: Core.Theme.textMuted
      font.family: Core.Style.fontFamily
      font.pixelSize: Core.Style.fontM
      visible: !textInput.text && !textInput.activeFocus
    }
  }

  // === Public API ===
  function clear() {
    textInput.text = "";
  }

  function forceActiveFocus() {
    textInput.forceActiveFocus();
  }
}
