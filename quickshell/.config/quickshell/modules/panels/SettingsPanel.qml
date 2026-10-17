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
  readonly property var barKeys: ["barShowLauncher", "barShowWindowTitle", "barShowClock", "barShowTray", "barShowKeyboardLayout", "barShowUpdates", "barShowIdleInhibitor", "barShowVolume", "barShowMicrophone", "barShowMedia", "barShowNetwork", "barShowBluetooth", "barShowSystemStats", "barShowBattery", "barShowNotification"]

  // Widgets that stay hidden even when on, so a toggle that seems to do nothing
  // says why. Each matches a condition in modules/bar/Bar.qml.
  readonly property var barNotes: ({
      barShowKeyboardLayout: "off the first layout",
      barShowUpdates: "when updates wait",
      barShowTray: "when filled",
      barShowIdleInhibitor: "when on",
      barShowMicrophone: "when recording",
      barShowMedia: "when playing",
      barShowBattery: "on battery or charging"
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

  ChoiceRow {
    label: "Scale"
    choices: root.scales.map(scale => ({
          value: scale,
          text: `${Math.round(scale * 100)}%`
        }))
    current: Config.Config.uiScale
    onChosen: value => Config.Config.setUiScale(value)
  }

  Components.FormRow {
    Layout.fillWidth: true
    label: "Animations"
    toggleChecked: Config.Config.animationsEnabled
    onToggled: on => Config.Config.setFlag("animationsEnabled", on)
  }

  Components.FormRow {
    Layout.fillWidth: true
    label: "Shadows"
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
        toggleChecked: Config.Config.flag(widgetRow.modelData)
        onToggled: on => Config.Config.setFlag(widgetRow.modelData, on)
      }
    }
  }

  Components.FormRow {
    Layout.fillWidth: true
    label: "Clock seconds"
    toggleChecked: Config.Config.barClockShowSeconds
    onToggled: on => Config.Config.setFlag("barClockShowSeconds", on)
  }

  Components.FormRow {
    Layout.fillWidth: true
    label: "Empty workspaces"
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
    toggleChecked: Config.Config.osdEnabled
    onToggled: on => Config.Config.setFlag("osdEnabled", on)
  }

  Components.FormRow {
    Layout.fillWidth: true
    enabled: Services.NightLight.available
    label: "Night light"
    valueText: Services.NightLight.available ? `${Services.NightLight.temperature}K` : "hyprsunset off"
    toggleChecked: Config.Config.nightLight
    onToggled: on => Services.NightLight.setEnabled(on)
  }

  Components.FormRow {
    Layout.fillWidth: true
    enabled: Services.NightLight.available
    label: "Night light schedule"
    valueText: `${Config.Config.nightLightStart} - ${Config.Config.nightLightEnd}`
    toggleChecked: Config.Config.nightLightAuto
    onToggled: on => Services.NightLight.setSchedule(on)
  }

  Components.FormRow {
    Layout.fillWidth: true
    label: "Lower refresh on battery"
    valueText: `${Config.Config.batteryRefreshRate} Hz`
    toggleChecked: Config.Config.lowRefreshOnBattery
    onToggled: on => Config.Config.setFlag("lowRefreshOnBattery", on)
  }

  // === System ===
  Components.SectionHeader {
    Layout.fillWidth: true
    title: "System"
    icon: "chip"
  }

  ChoiceRow {
    label: "Week starts"
    choices: [
      {
        value: 6,
        text: "Sat"
      },
      {
        value: 0,
        text: "Sun"
      },
      {
        value: 1,
        text: "Mon"
      }
    ]
    current: Config.Config.calendarWeekStart
    onChosen: value => Config.Config.setCalendarWeekStart(value)
  }

  ChoiceRow {
    label: "Network backend"
    choices: [
      {
        value: "native",
        text: "Native"
      },
      {
        value: "nmcli",
        text: "nmcli"
      }
    ]
    current: Config.Config.networkBackend
    onChosen: value => Config.Config.setNetworkBackend(value)
  }

  // A label and a row of buttons, the current choice filled in.
  component ChoiceRow: Components.Card {
    id: choiceRow

    property string label: ""
    // [{ value, text }]
    property var choices: []
    property var current

    signal chosen(var value)

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
        text: choiceRow.label
      }

      Repeater {
        model: choiceRow.choices

        delegate: Components.Button {
          id: choice

          required property var modelData

          Layout.fillWidth: true
          variant: choiceRow.current === choice.modelData.value ? "primary" : "secondary"
          text: choice.modelData.text
          textSize: Core.Style.fontS
          onClicked: choiceRow.chosen(choice.modelData.value)
        }
      }
    }
  }
}
