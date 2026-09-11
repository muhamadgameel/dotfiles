import QtQuick

import "../config" as Config
import "../core" as Core

/**
* Slider - Horizontal slider control for adjusting values
*
* A draggable slider with smooth animations and keyboard support.
* Ideal for volume, brightness, and similar controls.
*
* The slider never writes `value`. Bind it to the state it controls and apply
* valueUpdated there. It used to assign `value` while dragging, which silently
* broke the caller's binding on the first drag - after that the slider stopped
* following the state, so dragging the volume slider once meant the volume keys
* no longer moved it.
*
* While dragging, and for a moment after letting go, it shows where the handle
* is (displayValue) rather than `value`, so the handle does not snap back before
* the change has made its way through the service and back.
*
* Usage:
*   // Basic slider
*   Slider {
*       value: Services.Audio.volume
*       onValueUpdated: newValue => Services.Audio.setVolume(newValue)
*   }
*
*   // Apply only on release (seeking, where every step is expensive)
*   Slider {
*       value: Services.Media.progress
*       liveUpdate: false
*       onValueUpdated: newValue => Services.Media.seekFraction(newValue)
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
  property int trackHeight: Core.Style.px(8)
  property int handleSize: Core.Style.px(16)
  property bool showHandle: true

  // === Behavior Properties ===
  // Emit valueUpdated while dragging. False emits once, on release.
  property bool liveUpdate: true

  // === State (readonly) ===
  readonly property bool hovered: mouseArea.containsMouse
  readonly property bool dragging: mouseArea.pressed

  // What the slider is showing: the handle's own position while it is being
  // moved or settling, the bound value otherwise.
  readonly property real displayValue: root._holding ? root._dragValue : root.value
  readonly property real normalizedValue: root.maxValue > root.minValue ? Core.Utils.clamp((root.displayValue - root.minValue) / (root.maxValue - root.minValue), 0, 1) : 0

  // === Signals ===
  signal valueUpdated(real newValue)
  signal dragStarted
  signal dragEnded

  // === Internal ===
  property real _dragValue: 0

  // Showing _dragValue. Set as a drag or key press starts, and cleared once the
  // bound value catches up (or the grace period runs out) - but never mid-drag,
  // where `value` can move for unrelated reasons, a playing track's position.
  property bool _holding: false

  onValueChanged: {
    if (!root.dragging)
      root._holding = false;
  }

  Timer {
    id: holdTimer
    interval: Core.Style.animSlow * 3
    onTriggered: root._holding = false
  }

  function _hold(newValue) {
    root._dragValue = newValue;
    root._holding = true;
    holdTimer.restart();
  }

  // === Dimensions ===
  implicitWidth: Core.Style.px(200)
  implicitHeight: Math.max(trackHeight, handleSize)

  opacity: enabled ? 1.0 : Core.Style.opacityDisabled

  Behavior on opacity {
    NumberAnimation {
      duration: Core.Style.duration(Core.Style.animFast)
    }
  }

  // === Track Background ===
  Rectangle {
    id: track
    anchors.centerIn: parent
    width: parent.width
    height: root.trackHeight
    radius: Core.Style.radiusFull
    color: root.trackColor
  }

  // Normal range marker (100%)
  Rectangle {
    visible: root.maxValue > 1.0
    anchors.verticalCenter: track.verticalCenter
    width: Core.Style.px(2)
    x: track.width * (1.0 / root.maxValue) - width / 2
    height: track.height + Core.Style.px(4)
    radius: width / 2
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
        duration: Core.Style.duration(Core.Style.animFast)
        easing.type: Core.Style.easeStandard
      }
    }
  }

  // === Handle ===
  Rectangle {
    id: handle
    visible: root.showHandle
    x: (track.width - width) * root.normalizedValue
    anchors.verticalCenter: track.verticalCenter

    Behavior on x {
      enabled: !root.dragging
      NumberAnimation {
        duration: Core.Style.duration(Core.Style.animFast)
        easing.type: Core.Style.easeStandard
      }
    }
    width: root.handleSize
    height: root.handleSize
    radius: Core.Style.radiusFull
    color: root.dragging ? root.handleDragColor : (root.hovered ? root.handleHoverColor : root.handleColor)
    scale: root.dragging ? 1.1 : (root.hovered ? 1.05 : 1.0)

    Behavior on color {
      ColorAnimation {
        duration: Core.Style.duration(Core.Style.animFast)
      }
    }

    Behavior on scale {
      NumberAnimation {
        duration: Core.Style.duration(Core.Style.animFast)
        easing.type: Core.Style.easeStandard
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
      root._hold(root.value);
      root.dragStarted();
      updateValue(mouse.x);
    }

    onPositionChanged: mouse => {
      if (pressed) {
        updateValue(mouse.x);
      }
    }

    onReleased: {
      // Restart the grace period from the release, not from the press.
      holdTimer.restart();
      if (!root.liveUpdate)
        root.valueUpdated(root._dragValue);
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

      if (newValue !== root._dragValue) {
        root._dragValue = newValue;
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
    const stepSize = step > 0 ? step : (maxValue - minValue) / 20;
    root.setValue(root.displayValue + direction * stepSize);
  }

  // === Public API ===
  // Moves the handle and reports the change; the caller applies it to `value`.
  function setValue(newValue) {
    const clamped = Core.Utils.clamp(newValue, minValue, maxValue);
    if (clamped === root.displayValue)
      return;
    root._hold(clamped);
    root.valueUpdated(clamped);
  }
}
