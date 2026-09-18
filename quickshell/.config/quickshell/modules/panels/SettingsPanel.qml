pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core
import "../../services" as Services

/**
* SettingsPanel - the settings that were only reachable over IPC
*
* Every row writes through Config, which owns the defaults. Scale is stepped
* rather than a slider: it drives panelWidth, the padding and every font, so a
* drag would resize the panel under the pointer.
*/
Components.SlidingPanel {
  id: root

  panelId: "settings"

  headerIcon: "settings"
  headerIconColor: Core.Theme.accent
  headerTitle: "Settings"
  headerSubtitle: Core.Theme.name

  readonly property var scales: [0.75, 1.0, 1.25, 1.5]

  // In bar order, left to right.
  readonly property var barKeys: ["barShowLauncher", "barShowWindowTitle", "barShowClock", "barShowTray", "barShowIdleInhibitor", "barShowVolume", "barShowMicrophone", "barShowMedia", "barShowNetwork", "barShowBluetooth", "barShowSystemStats", "barShowBattery", "barShowBrightness", "barShowNotification", "barShowWallpaper", "barShowScreenshot", "barShowPower"]

  // Widgets that stay hidden even when on, so a toggle that seems to do nothing
  // says why. Each matches a condition in modules/bar/Bar.qml.
  readonly property var barNotes: ({
      barShowTray: "when filled",
      barShowIdleInhibitor: "when on",
      barShowMedia: "when playing",
      barShowBattery: "when present",
      barShowBrightness: "when available"
    })

  readonly property int hiddenCount: root.barKeys.filter(k => !Config.Config.flag(k)).length

  function barLabel(key) {
    const name = key.replace("barShow", "").replace(/([A-Z])/g, " $1").trim();
    return name.charAt(0) + name.slice(1).toLowerCase();
  }

  // === Appearance ===
  Components.SectionHeader {
    Layout.fillWidth: true
    title: "Appearance"
    icon: "palette"
  }

  Repeater {
    model: Core.Themes.names

    delegate: Components.Card {
      id: themeRow

      required property string modelData

      readonly property var colors: Core.Themes.get(themeRow.modelData)
      readonly property bool current: Core.Theme.name === themeRow.modelData

      Layout.fillWidth: true
      implicitHeight: Core.Style.controlHeightM
      radius: Core.Style.radiusM
      interactive: true
      backgroundColor: themeRow.colors.bg
      hoverColor: themeRow.colors.surface
      activeColor: themeRow.colors.surfaceHover
      borderColor: themeRow.current ? themeRow.colors.accent : Core.Theme.transparent
      borderWidth: themeRow.current ? Core.Style.borderThin * 2 : 0

      onClicked: Config.Config.setTheme(themeRow.modelData)

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Core.Style.spaceM
        anchors.rightMargin: Core.Style.spaceM
        spacing: Core.Style.spaceS

        Repeater {
          model: [themeRow.colors.accent, themeRow.colors.accentAlt, themeRow.colors.warning]

          delegate: Rectangle {
            required property color modelData

            implicitWidth: Core.Style.px(10)
            implicitHeight: Core.Style.px(10)
            radius: Core.Style.radiusFull
            color: modelData
          }
        }

        Components.Text {
          Layout.fillWidth: true
          Layout.leftMargin: Core.Style.spaceXS
          text: themeRow.modelData
          color: themeRow.colors.text
        }

        Components.Icon {
          visible: themeRow.current
          icon: "check"
          size: Core.Style.fontM
          color: themeRow.colors.accent
        }
      }
    }
  }

  Components.Card {
    Layout.fillWidth: true
    implicitHeight: Core.Style.controlHeightM
    radius: Core.Style.radiusM
    hoverEnabled: false

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Core.Style.spaceM
      anchors.rightMargin: Core.Style.spaceS
      spacing: Core.Style.spaceS

      Components.Text {
        text: "Scale"
      }

      Repeater {
        model: root.scales

        delegate: Components.Button {
          id: scaleButton

          required property real modelData

          Layout.fillWidth: true
          variant: Math.abs(Config.Config.uiScale - scaleButton.modelData) < 0.01 ? "primary" : "secondary"
          text: `${Math.round(scaleButton.modelData * 100)}%`
          textSize: Core.Style.fontS
          onClicked: Config.Config.setUiScale(scaleButton.modelData)
        }
      }
    }
  }

  Components.FormRow {
    Layout.fillWidth: true
    label: "Animations"
    hasToggle: true
    toggleChecked: Config.Config.animationsEnabled
    onToggled: on => Config.Config.setFlag("animationsEnabled", on)
  }

  Components.FormRow {
    Layout.fillWidth: true
    label: "Shadows"
    hasToggle: true
    toggleChecked: Config.Config.shadowsEnabled
    onToggled: on => Config.Config.setFlag("shadowsEnabled", on)
  }

  // === Bar ===
  Components.SectionHeader {
    Layout.fillWidth: true
    title: "Bar"
    icon: "layers"

    Components.Text {
      visible: root.hiddenCount > 0
      text: `${root.hiddenCount} hidden`
      size: Core.Style.fontXS
      color: Core.Theme.textMuted
    }
  }

  Components.Collapsible {
    Layout.fillWidth: true
    title: "Widgets"
    icon: "grid"

    Repeater {
      model: root.barKeys

      delegate: Components.FormRow {
        id: widgetRow

        required property string modelData

        Layout.fillWidth: true
        label: root.barLabel(widgetRow.modelData)
        valueText: root.barNotes[widgetRow.modelData] ?? ""
        hasToggle: true
        toggleChecked: Config.Config.flag(widgetRow.modelData)
        onToggled: on => Config.Config.setFlag(widgetRow.modelData, on)
      }
    }
  }

  Components.FormRow {
    Layout.fillWidth: true
    label: "Clock seconds"
    hasToggle: true
    toggleChecked: Config.Config.barClockShowSeconds
    onToggled: on => Config.Config.setFlag("barClockShowSeconds", on)
  }

  Components.FormRow {
    Layout.fillWidth: true
    label: "Empty workspaces"
    hasToggle: true
    toggleChecked: Config.Config.workspaceShowEmpty
    onToggled: on => Config.Config.setFlag("workspaceShowEmpty", on)
  }

  // === Display ===
  Components.SectionHeader {
    Layout.fillWidth: true
    title: "Display"
    icon: "monitor"
  }

  Components.FormRow {
    Layout.fillWidth: true
    label: "On-screen display"
    hasToggle: true
    toggleChecked: Config.Config.osdEnabled
    onToggled: on => Config.Config.setFlag("osdEnabled", on)
  }

  Components.FormRow {
    Layout.fillWidth: true
    enabled: Services.NightLight.available
    label: "Night light"
    valueText: Services.NightLight.available ? `${Services.NightLight.temperature}K` : "hyprsunset off"
    hasToggle: true
    toggleChecked: Config.Config.nightLight
    onToggled: on => Services.NightLight.setEnabled(on)
  }

  Components.FormRow {
    Layout.fillWidth: true
    label: "Lower refresh on battery"
    valueText: `${Config.Config.batteryRefreshRate} Hz`
    hasToggle: true
    toggleChecked: Config.Config.lowRefreshOnBattery
    onToggled: on => Config.Config.setFlag("lowRefreshOnBattery", on)
  }
}
