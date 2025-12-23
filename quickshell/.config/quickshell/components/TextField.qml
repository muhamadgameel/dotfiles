import QtQuick
import QtQuick.Layouts

import "../config" as Config
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
  property int inputMethodHints: Qt.ImhNone

  // === Styling Properties ===
  property color backgroundColor: Config.Theme.bgDark
  property color borderColor: Config.Theme.surfaceHover
  property color borderFocusColor: Config.Theme.accent
  property color textColor: Config.Theme.text
  property color placeholderColor: Config.Theme.textMuted
  property real fontSize: Core.Style.fontM
  property int borderRadius: Core.Style.radiusS
  property int borderWidth: 1

  // === Layout Properties ===
  Layout.fillWidth: true
  Layout.preferredHeight: Core.Style.widgetSize + Core.Style.spaceS

  // === Signals ===
  signal accepted  // Emitted when Enter/Return is pressed
  signal cancelled  // Emitted when Escape is pressed

  // === Appearance ===
  radius: borderRadius
  color: backgroundColor
  border {
    color: textInput.activeFocus ? borderFocusColor : borderColor
    width: borderWidth
  }

  Behavior on border.color {
    ColorAnimation {
      duration: Core.Style.animFast
    }
  }

  // === Text Input ===
  TextInput {
    id: textInput
    anchors.fill: parent
    anchors.leftMargin: Core.Style.spaceS
    anchors.rightMargin: Core.Style.spaceS
    verticalAlignment: TextInput.AlignVCenter
    color: root.textColor
    echoMode: root.echoMode
    inputMethodHints: root.inputMethodHints
    font.pixelSize: root.fontSize
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
      color: root.placeholderColor
      font.pixelSize: root.fontSize
      visible: !textInput.text && !textInput.activeFocus
    }
  }

  // === Public API ===
  function clear() {
    textInput.text = "";
  }

  function selectAll() {
    textInput.selectAll();
  }

  function forceActiveFocus() {
    textInput.forceActiveFocus();
  }
}
