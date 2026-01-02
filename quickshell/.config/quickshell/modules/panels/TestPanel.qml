import QtQuick
import QtQuick.Layouts

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core
import "../../layouts" as Layouts

/**
* TestPanel - Component showcase and testing panel
*
* Displays all available components for visual testing and verification.
*/
Layouts.SlidingPanel {
  id: root

  namespace: "quickshell-test-panel"
  hasBackdrop: false

  // Header configuration
  headerIcon: "settings"
  headerIconColor: Config.Theme.accent
  headerTitle: "Component Test Panel"
  headerSubtitle: "Showcase of all UI components"

  // Test state
  property bool testToggle: false
  property real testSlider: 0.5
  property bool showWarning: false
  property string testInput: ""

  Components.Spacer {}

  // ═══════════════════════════════════════════════════════════════════
  // ICONS SECTION
  // ═══════════════════════════════════════════════════════════════════
  Components.Text {
    text: "Icon Component"
    size: Core.Style.fontXL
    weight: Core.Style.weightBold
  }

  RowLayout {
    spacing: Core.Style.spaceM

    Components.Icon {
      icon: "bell"
      size: Core.Style.fontXL
    }

    Components.Icon {
      icon: "󰂚"
      size: Core.Style.fontXL
    }

    Components.Icon {
      icon: "/home/mgameel/Downloads/firefox.png"
      size: 32
    }

    Components.Icon {
      icon: "refresh"
      spinning: true
      size: Core.Style.fontXL
    }
  }

  Components.Divider {}

  // ═══════════════════════════════════════════════════════════════════
  // TEXT SECTION
  // ═══════════════════════════════════════════════════════════════════
  Components.Text {
    text: "Text Component"
    size: Core.Style.fontXL
    weight: Core.Style.weightBold
  }

  Components.Text {
    text: "Hello"
  }

  Components.Text {
    icon: "cpu"
    text: "CPU"
    size: Core.Style.fontXL
    weight: Core.Style.weightBold
  }

  Components.Text {
    text: "Settings"
    icon: "chevron-right"
    iconPosition: "right"
  }

  Components.Text {
    text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
    icon: "cpu"
    wrapMode: Text.Wrap
    iconSize: Core.Style.fontXXL
    maximumLineCount: 3
    weight: Core.Style.weightBold
  }

  Components.Text {
    text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
    wrapMode: Text.Wrap
    iconSize: Core.Style.fontXXL
    maximumLineCount: 2
  }

  Components.Divider {}

  // ═══════════════════════════════════════════════════════════════════
  // BUTTONS SECTION
  // ═══════════════════════════════════════════════════════════════════
  Components.Text {
    text: "Buttons"
    size: Core.Style.fontXL
    weight: Core.Style.weightBold
  }

  Flow {
    Layout.fillWidth: true
    spacing: Core.Style.spaceS

    Components.Button {
      text: "Default"
      icon: "split"
    }

    Components.Button {
      variant: "primary"
      text: "Primary"
      icon: "check"
    }

    Components.Button {
      variant: "secondary"
      text: "Secondary"
      icon: "info"
    }

    Components.Button {
      variant: "danger"
      text: "Danger"
      icon: "trash"
    }

    Components.Button {
      variant: "ghost"
      text: "Ghost"
      icon: "eye"
    }
  }

  Flow {
    Layout.fillWidth: true
    spacing: Core.Style.spaceS

    Components.Button {
      text: "Default"
    }

    Components.Button {
      variant: "primary"
      text: "Primary"
    }

    Components.Button {
      variant: "secondary"
      text: "Secondary"
    }

    Components.Button {
      variant: "danger"
      text: "Danger"
    }

    Components.Button {
      variant: "ghost"
      text: "Ghost"
    }
  }

  Flow {
    Layout.fillWidth: true
    spacing: Core.Style.spaceS

    Components.Button {
      icon: "settings"
      tooltipText: "Icon only"
    }

    Components.Button {
      variant: "primary"
      icon: "plus"
      tooltipText: "Primary icon"
    }

    Components.Button {
      variant: "danger"
      icon: "close"
      tooltipText: "Danger icon"
    }

    Components.Button {
      icon: "refresh"
      iconSpinning: true
      tooltipText: "Spinning icon"
    }

    Components.Button {
      text: "Disabled"
      enabled: false
    }
  }

  Components.Divider {}

  // ═══════════════════════════════════════════════════════════════════
  // BADGES SECTION
  // ═══════════════════════════════════════════════════════════════════

  Components.Text {
    text: "Badges"
    size: Core.Style.fontXL
    weight: Core.Style.weightBold
  }

  Flow {
    Layout.fillWidth: true
    spacing: Core.Style.spaceS

    Components.Badge {
      text: "Default"
    }

    Components.Badge {
      text: "Success"
      textColor: Config.Theme.success
    }

    Components.Badge {
      text: "Warning"
      textColor: Config.Theme.warning
    }

    Components.Badge {
      text: "Error"
      textColor: Config.Theme.error
    }

    Components.Badge {
      variant: "count"
      count: 5
    }

    Components.Badge {
      variant: "count"
      count: 99
    }

    Components.Badge {
      variant: "count"
      count: 150
      backgroundColor: Config.Theme.accent
    }
  }

  Components.Divider {}

  // ═══════════════════════════════════════════════════════════════════
  // STATUS DOTS SECTION
  // ═══════════════════════════════════════════════════════════════════

  Components.Text {
    text: "Status Dots"
    size: Core.Style.fontXL
    weight: Core.Style.weightBold
  }

  RowLayout {
    spacing: Core.Style.spaceL

    RowLayout {
      spacing: Core.Style.spaceS
      Components.StatusDot {
        color: Config.Theme.success
      }
      Components.Text {
        text: "Online"
        size: Core.Style.fontS
      }
    }

    RowLayout {
      spacing: Core.Style.spaceS
      Components.StatusDot {
        color: Config.Theme.warning
      }
      Components.Text {
        text: "Away"
        size: Core.Style.fontS
      }
    }

    RowLayout {
      spacing: Core.Style.spaceS
      Components.StatusDot {
        color: Config.Theme.error
      }
      Components.Text {
        text: "Busy"
        size: Core.Style.fontS
      }
    }

    RowLayout {
      spacing: Core.Style.spaceS
      Components.StatusDot {
        color: Config.Theme.accent
        pulse: true
      }
      Components.Text {
        text: "Syncing"
        size: Core.Style.fontS
      }
    }
  }

  Components.Divider {}

  // ═══════════════════════════════════════════════════════════════════
  // SLIDER SECTION
  // ═══════════════════════════════════════════════════════════════════

  Components.Text {
    text: "Slider"
    size: Core.Style.fontXL
    weight: Core.Style.weightBold
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Core.Style.spaceM

    Components.Slider {
      Layout.fillWidth: true
      value: root.testSlider
      onValueUpdated: root.testSlider = newValue
    }

    Components.Text {
      text: Math.round(root.testSlider * 100) + "%"
      size: Core.Style.fontM
      color: Config.Theme.accent
    }
  }

  Components.Slider {
    Layout.fillWidth: true
    value: 0.7
    progressColor: Config.Theme.success
    handleColor: Config.Theme.success
  }

  Components.Slider {
    Layout.fillWidth: true
    value: 0.3
    progressColor: Config.Theme.warning
    showHandle: false
  }

  Components.Divider {}

  // ═══════════════════════════════════════════════════════════════════
  // PROGRESS BARS SECTION
  // ═══════════════════════════════════════════════════════════════════

  Components.Text {
    text: "Progress Bars"
    size: Core.Style.fontXL
    weight: Core.Style.weightBold
  }

  Layouts.ProgressRow {
    Layout.fillWidth: true
    icon: "cpu"
    value: 0.65
    progressColor: Config.Theme.accent
  }

  Layouts.ProgressRow {
    Layout.fillWidth: true
    label: "Memory"
    labelInfo: "8.2 GB / 16 GB"
    value: 0.51
    progressColor: Config.Theme.accentAlt
    showPercentage: false
  }

  Layouts.ProgressRow {
    Layout.fillWidth: true
    icon: "thermometer"
    label: "CPU Temp"
    value: 0.72
    valueText: "72°C"
    progressColor: Config.Theme.warning
  }

  Components.Divider {}

  // ═══════════════════════════════════════════════════════════════════
  // CARDS SECTION
  // ═══════════════════════════════════════════════════════════════════

  Components.Text {
    text: "Cards"
    size: Core.Style.fontXL
    weight: Core.Style.weightBold
  }

  Components.Card {
    Layout.fillWidth: true
    implicitHeight: 60
    padding: Core.Style.spaceM
    backgroundColor: Config.Theme.surface
    borderColor: Config.Theme.overlay
    borderWidth: 1

    Components.Text {
      anchors.centerIn: parent
      text: "Basic Card with border"
    }
  }

  Components.Card {
    Layout.fillWidth: true
    implicitHeight: 60
    padding: Core.Style.spaceM
    interactive: true

    Components.Text {
      anchors.centerIn: parent
      text: "Interactive Card (hover me!)"
    }
  }

  Components.Divider {}

  // ═══════════════════════════════════════════════════════════════════
  // FORM CONTROLS SECTION
  // ═══════════════════════════════════════════════════════════════════

  Components.Text {
    text: "Form Controls"
    size: Core.Style.fontXL
    weight: Core.Style.weightBold
  }

  Components.TextField {
    Layout.fillWidth: true
    placeholder: "Enter some text..."
    text: root.testInput
    onAccepted: console.log("Submitted:", root.testInput)
  }

  Layouts.FormRow {
    label: "Enable Feature"
    hasToggle: true
    toggleChecked: root.testToggle
    onToggled: root.testToggle = checked
  }

  Layouts.FormRow {
    label: "Version"
    valueText: "1.0.0"
  }

  Layouts.FormRow {
    label: "Status"
    valueText: root.testToggle ? "Enabled" : "Disabled"
  }

  Components.Divider {}

  // ═══════════════════════════════════════════════════════════════════
  // SPINNERS & LOADING SECTION
  // ═══════════════════════════════════════════════════════════════════

  Components.Text {
    text: "Spinners & Loading"
    size: Core.Style.fontXL
    weight: Core.Style.weightBold
  }

  RowLayout {
    spacing: Core.Style.spaceL

    RowLayout {
      spacing: Core.Style.spaceS
      Components.Spinner {
        size: Core.Style.fontM
      }
      Components.Text {
        text: "Small"
        size: Core.Style.fontS
      }
    }

    RowLayout {
      spacing: Core.Style.spaceS
      Components.Spinner {
        size: Core.Style.fontXL
        color: Config.Theme.accent
      }
      Components.Text {
        text: "Medium"
        size: Core.Style.fontS
      }
    }

    RowLayout {
      spacing: Core.Style.spaceS
      Components.Spinner {
        size: Core.Style.fontXXL
        color: Config.Theme.success
      }
      Components.Text {
        text: "Large"
        size: Core.Style.fontS
      }
    }
  }

  Components.Divider {}

  // ═══════════════════════════════════════════════════════════════════
  // WARNING OVERLAY SECTION
  // ═══════════════════════════════════════════════════════════════════

  Components.Text {
    text: "Warning Overlay"
    size: Core.Style.fontXL
    weight: Core.Style.weightBold
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Core.Style.spaceM

    Components.Card {
      implicitWidth: 120
      implicitHeight: 60
      backgroundColor: Config.Theme.surface

      Components.Text {
        anchors.centerIn: parent
        text: "Warning"
        size: Core.Style.fontS
      }

      Components.WarningOverlay {
        active: root.showWarning
        severity: "warning"
      }
    }

    Components.Card {
      implicitWidth: 120
      implicitHeight: 60
      backgroundColor: Config.Theme.surface

      Components.Text {
        anchors.centerIn: parent
        text: "Critical"
        size: Core.Style.fontS
      }

      Components.WarningOverlay {
        active: root.showWarning
        severity: "critical"
      }
    }

    Components.Button {
      text: root.showWarning ? "Stop" : "Start"
      variant: root.showWarning ? "danger" : "primary"
      onClicked: root.showWarning = !root.showWarning
    }
  }

  Components.Divider {}

  // ═══════════════════════════════════════════════════════════════════
  // COLLAPSIBLE SECTION
  // ═══════════════════════════════════════════════════════════════════

  Layouts.Collapsible {
    Layout.fillWidth: true
    title: "Collapsible Section"
    icon: "folder"
    expanded: false

    Components.Text {
      text: "This content is inside a collapsible section."
      size: Core.Style.fontS
      color: Config.Theme.textDim
    }

    Layouts.FormRow {
      label: "Hidden Option 1"
      valueText: "Value"
    }

    Layouts.FormRow {
      label: "Hidden Option 2"
      hasToggle: true
    }
  }

  Components.Divider {}

  // ═══════════════════════════════════════════════════════════════════
  // EMPTY STATE SECTION
  // ═══════════════════════════════════════════════════════════════════

  Components.Text {
    text: "Empty State"
    size: Core.Style.fontXL
    weight: Core.Style.weightBold
  }

  Layouts.EmptyState {
    Layout.fillWidth: true
    message: "Long empty message to test wrapping and alignment with a hint below it"
    hint: "Long hint to test wrapping and alignment with the message above it, Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
  }

  Components.Divider {
    implicitWidth: 200
    anchors.horizontalCenter: parent.horizontalCenter
  }

  Layouts.EmptyState {
    Layout.fillWidth: true
    message: "Nothing here yet"
    hint: "Items will appear when available"
  }

  Components.Divider {
    implicitWidth: 200
    anchors.horizontalCenter: parent.horizontalCenter
  }

  Layouts.EmptyState {
    Layout.fillWidth: true
    message: "Nothing here yet"
  }

  Components.Divider {}

  // ═══════════════════════════════════════════════════════════════════
  // ERROR BANNER SECTION
  // ═══════════════════════════════════════════════════════════════════

  Components.Text {
    text: "Error Banner"
    size: Core.Style.fontXL
    weight: Core.Style.weightBold
  }

  Layouts.StatusBanner {
    Layout.fillWidth: true
    type: "error"
    message: "Something went wrong. Please try again. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
  }

  Layouts.StatusBanner {
    Layout.fillWidth: true
    type: "warning"
    message: "Something went wrong. Please try again."
  }

  Layouts.StatusBanner {
    Layout.fillWidth: true
    type: "success"
    message: "Something went wrong. Please try again."
  }

  Layouts.StatusBanner {
    Layout.fillWidth: true
    type: "info"
    message: "Something went wrong. Please try again."
  }

  Layouts.StatusBanner {
    Layout.fillWidth: true
    type: "unknown"
    message: "Something went wrong. Please try again."
  }

  // Bottom padding
  Components.Spacer {
    size: Core.Style.spaceXL
  }
}
