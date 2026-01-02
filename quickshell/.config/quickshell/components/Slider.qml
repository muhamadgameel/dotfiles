import QtQuick

import "../config" as Config
import "../core" as Core

/**
* Slider - Horizontal slider control for adjusting values
*
* A draggable slider with smooth animations and keyboard support.
* Ideal for volume, brightness, and similar controls.
*
* Usage:
*   // Basic slider
*   Slider {
*       value: 0.5
*       onValueUpdated: handleChange(newValue)
*   }
*
*   // With min/max and step
*   Slider {
*       value: 50
*       minValue: 0
*       maxValue: 100
*       step: 5
*   }
*
*   // Custom colors
*   Slider {
*       value: 0.7
*       progressColor: Theme.success
*       handleColor: Theme.accent
*   }
*/
Item {
  id: root

  // === Value Properties ===
  property real value: 0
  property real minValue: 0
  property real maxValue: 1
  property real step: 0  // 0 = continuous

  // === Styling Properties ===
  property color trackColor: Config.Theme.surface
  property color progressColor: Config.Theme.accent
  property color handleColor: Config.Theme.text
  property color handleHoverColor: Config.Theme.text
  property color handleDragColor: Config.Theme.accent
  property int trackHeight: 8
  property int handleSize: 16
  property bool showHandle: true

  // === Behavior Properties ===
  property bool enabled: true
  property bool liveUpdate: true  // Emit valueChanged while dragging

  // === State (readonly) ===
  readonly property bool hovered: mouseArea.containsMouse
  readonly property bool dragging: mouseArea.pressed
  readonly property real normalizedValue: (value - minValue) / (maxValue - minValue)

  // === Signals ===
  signal valueUpdated(real newValue)
  signal dragStarted
  signal dragEnded

  // === Dimensions ===
  implicitWidth: 200
  implicitHeight: Math.max(trackHeight, handleSize)

  opacity: enabled ? 1.0 : 0.5

  // === Track Background ===
  Rectangle {
    id: track
    anchors.centerIn: parent
    width: parent.width
    height: root.trackHeight
    radius: height / 2
    color: root.trackColor
  }

  // Normal range marker (100%)
  Rectangle {
    visible: root.maxValue > 1.0
    anchors.verticalCenter: track.verticalCenter
    x: track.width * (1.0 / root.maxValue) - 1
    width: 2
    height: track.height + 4
    radius: 1
    color: Config.Theme.textMuted
    opacity: 0.5
  }

  // === Progress Fill ===
  Rectangle {
    id: progress
    anchors.left: track.left
    anchors.verticalCenter: track.verticalCenter
    width: track.width * root.normalizedValue
    height: track.height
    radius: track.radius
    color: root.progressColor

    Behavior on width {
      enabled: !root.dragging
      NumberAnimation {
        duration: Core.Style.animFast
        easing.type: Easing.OutQuad
      }
    }
  }

  // === Handle ===
  Rectangle {
    id: handle
    visible: root.showHandle
    x: (track.width - width) * root.normalizedValue
    anchors.verticalCenter: track.verticalCenter
    width: root.handleSize
    height: root.handleSize
    radius: width / 2
    color: root.dragging ? root.handleDragColor : (root.hovered ? root.handleHoverColor : root.handleColor)
    scale: root.dragging ? 1.1 : (root.hovered ? 1.05 : 1.0)

    Behavior on color {
      ColorAnimation {
        duration: Core.Style.animFast
      }
    }

    Behavior on scale {
      NumberAnimation {
        duration: Core.Style.animFast
        easing.type: Easing.OutQuad
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

    onPressed: mouse => {
      root.dragStarted();
      updateValue(mouse.x);
    }

    onPositionChanged: mouse => {
      if (pressed) {
        updateValue(mouse.x);
      }
    }

    onReleased: {
      root.dragEnded();
    }

    function updateValue(mouseX) {
      let normalized = Core.Utils.clamp(mouseX / track.width, 0, 1);
      let newValue = root.minValue + normalized * (root.maxValue - root.minValue);

      // Apply step if defined
      if (root.step > 0) {
        newValue = Math.round(newValue / root.step) * root.step;
      }

      newValue = Core.Utils.clamp(newValue, root.minValue, root.maxValue);

      if (newValue !== root.value) {
        root.value = newValue;
        if (root.liveUpdate) {
          root.valueUpdated(newValue);
        }
      }
    }
  }

  // === Keyboard Support ===
  Keys.onLeftPressed: adjustValue(-1)
  Keys.onRightPressed: adjustValue(1)
  Keys.onUpPressed: adjustValue(1)
  Keys.onDownPressed: adjustValue(-1)

  function adjustValue(direction) {
    if (!enabled)
      return;
    let stepSize = step > 0 ? step : (maxValue - minValue) / 20;
    let newValue = Core.Utils.clamp(value + direction * stepSize, minValue, maxValue);
    if (newValue !== value) {
      value = newValue;
      valueUpdated(newValue);
    }
  }

  // === Public API ===
  function setValue(newValue) {
    value = Core.Utils.clamp(newValue, minValue, maxValue);
    valueUpdated(value);
  }
}
