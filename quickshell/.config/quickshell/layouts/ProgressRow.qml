import QtQuick
import QtQuick.Layouts

import "../components" as Components
import "../config" as Config
import "../core" as Core

/**
* ProgressRow - Versatile progress display component
*
* Supports multiple layouts:
*
* 1. Basic (original): Icon + Progress + Percentage
*    ProgressRow { icon: "cpu"; value: 0.75 }
*
* 2. Labeled: Label + Info + Progress
*    ProgressRow { label: "RAM"; labelInfo: "8GB / 16GB"; value: 0.5 }
*
* 3. With value text: Icon + Progress + Custom value
*    ProgressRow { icon: "thermometer"; value: 0.65; valueText: "65°C" }
*
* 4. Full: Icon + (Label + Progress) + Value
*    ProgressRow { icon: "thermometer"; label: "CPU"; value: 0.65; valueText: "65°C" }
*/
ColumnLayout {
  id: root

  // === Icon Properties ===
  property string icon: ""
  property string iconName: ""
  property color iconColor: Config.Theme.text
  property int iconSize: Core.Style.fontXL

  // === Label Properties ===
  property string label: ""        // Row label (e.g., "RAM", "CPU")
  property string labelInfo: ""    // Right-aligned info text (e.g., "8GB / 16GB")

  // === Progress Properties ===
  property real value: 0
  property real maxValue: 1
  property color progressColor: Config.Theme.accent
  property int progressHeight: 6

  // === Value Display ===
  property bool showPercentage: true
  property string valueText: ""    // Custom value text (overrides percentage)

  // === Internal ===
  readonly property bool hasIcon: icon !== "" || iconName !== ""
  readonly property bool hasLabel: label !== ""
  readonly property bool hasLabelInfo: labelInfo !== ""
  readonly property bool hasValueText: valueText !== ""

  spacing: Core.Style.spaceXS
  Layout.fillWidth: true

  // === Main Row ===
  RowLayout {
    Layout.fillWidth: true
    spacing: Core.Style.spaceM

    // Icon
    Components.Icon {
      icon: root.icon !== "" ? root.icon : ""
      name: root.iconName !== "" ? root.iconName : ""
      size: root.iconSize
      color: root.iconColor
      visible: root.hasIcon

      Behavior on color {
        ColorAnimation {
          duration: Core.Style.animNormal
        }
      }
    }

    // Label column with progress (when label is present)
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Core.Style.spaceXS
      visible: root.hasLabel

      // Label row with info
      RowLayout {
        Layout.fillWidth: true

        Components.Label {
          text: root.label
          size: Core.Style.fontS
        }

        Item {
          Layout.fillWidth: true
        }

        Components.Label {
          visible: root.hasLabelInfo
          text: root.labelInfo
          size: Core.Style.fontS
          color: Config.Theme.textDim
        }
      }

      // Progress bar below label
      Components.ProgressBar {
        Layout.fillWidth: true
        Layout.preferredHeight: root.progressHeight
        value: root.value
        maxValue: root.maxValue
        progressColor: root.progressColor
      }
    }

    // Progress bar inline with icon (when no label)
    Components.ProgressBar {
      Layout.fillWidth: true
      Layout.preferredHeight: root.progressHeight
      visible: !root.hasLabel
      value: root.value
      maxValue: root.maxValue
      progressColor: root.progressColor
    }

    // Value/Percentage display
    Components.Label {
      visible: root.showPercentage || root.hasValueText
      text: root.hasValueText ? root.valueText : Math.round(root.value / root.maxValue * 100) + "%"
      size: root.hasValueText ? Core.Style.fontL : Core.Style.fontM
      font.weight: root.hasValueText ? Core.Style.weightBold : Core.Style.weightMedium
      color: root.hasValueText ? root.iconColor : Config.Theme.text

      Behavior on color {
        ColorAnimation {
          duration: Core.Style.animNormal
        }
      }
    }
  }
}
