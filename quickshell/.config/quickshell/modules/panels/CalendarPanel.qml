pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core
import "../../services" as Services

/**
* CalendarPanel - month view, replacing the dead TODO on the clock widget
*/
Components.SlidingPanel {
  id: root

  panelId: "calendar"

  headerIcon: "calendar"
  headerIconColor: Core.Theme.accent
  headerTitle: Services.Time.timeShort
  headerSubtitle: Services.Time.dateLong

  // Month currently on screen, as an offset from the real current month.
  property int monthOffset: 0

  // Always reopen on today rather than wherever the user browsed to last.
  onOpened: root.monthOffset = 0

  property date today: new Date()

  // Reuse the shared clock's day change instead of adding a polling timer.
  Connections {
    target: Services.Time

    function onDateLongChanged() {
      root.today = new Date();
    }
  }

  readonly property date viewMonth: {
    const d = new Date(today.getFullYear(), today.getMonth() + monthOffset, 1);
    return d;
  }

  readonly property int viewYear: viewMonth.getFullYear()
  readonly property int viewMonthIndex: viewMonth.getMonth()

  // First column of the grid, as a JS weekday (0 = Sunday).
  readonly property int weekStart: Config.Config.calendarWeekStart

  readonly property var _weekdayNames: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

  // The week rotated to begin at weekStart.
  readonly property var dayNames: root._weekdayNames.slice(root.weekStart).concat(root._weekdayNames.slice(0, root.weekStart))

  readonly property int daysInMonth: new Date(viewYear, viewMonthIndex + 1, 0).getDate()

  // How far the 1st sits from the first column.
  readonly property int leadingBlanks: {
    const jsDay = new Date(viewYear, viewMonthIndex, 1).getDay();  // 0 = Sunday
    return (jsDay - root.weekStart + 7) % 7;
  }

  function isToday(day) {
    return monthOffset === 0 && day === today.getDate();
  }

  // === Month navigation ===
  Components.WheelSteps {
    onScrolled: steps => root.monthOffset -= steps
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    RowLayout {
      Layout.fillWidth: true
      spacing: Core.Style.spaceS

      Components.Button {
        icon: "chevron-left"
        iconSize: Core.Style.fontM
        tooltipText: "Previous month"
        onClicked: root.monthOffset--
      }

      Components.Text {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: Qt.formatDate(root.viewMonth, "MMMM yyyy")
        size: Core.Style.fontL
        weight: Core.Style.weightBold
      }

      Components.Button {
        icon: "chevron-right"
        iconSize: Core.Style.fontM
        tooltipText: "Next month"
        onClicked: root.monthOffset++
      }
    }

    // Opens under the month row instead of pushing the grid down in one frame.
    // The gap above the button is inside the animated height, so closing ends
    // without a jump.
    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: root.monthOffset !== 0 ? todayButton.implicitHeight + root.contentSpacing : 0
      clip: true
      visible: Layout.preferredHeight > 0
      opacity: root.monthOffset !== 0 ? 1 : 0

      Behavior on Layout.preferredHeight {
        Components.AnimNormal {}
      }

      Behavior on opacity {
        Components.AnimFast {}
      }

      Components.Button {
        id: todayButton

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        variant: "secondary"
        text: "Back to today"
        textSize: Core.Style.fontS
        onClicked: root.monthOffset = 0
      }
    }
  }

  // === Weekday header ===
  GridLayout {
    Layout.fillWidth: true
    columns: 7
    uniformCellWidths: true
    columnSpacing: 0
    rowSpacing: Core.Style.spaceXS

    Repeater {
      model: root.dayNames

      delegate: Components.Text {
        required property string modelData

        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: modelData
        size: Core.Style.fontXS
        color: Core.Theme.textMuted
        weight: Core.Style.weightBold
      }
    }
  }

  // === Day grid ===
  GridLayout {
    Layout.fillWidth: true
    columns: 7
    uniformCellWidths: true
    columnSpacing: 0
    rowSpacing: Core.Style.spaceXXS

    // Blanks before the 1st so the columns line up with the weekday header.
    Repeater {
      model: root.leadingBlanks

      delegate: Item {
        Layout.fillWidth: true
        Layout.preferredHeight: Core.Style.controlHeightS
      }
    }

    Repeater {
      model: root.daysInMonth

      delegate: Rectangle {
        id: dayCell

        required property int index

        readonly property int day: index + 1
        readonly property bool today: root.isToday(day)

        Layout.fillWidth: true
        Layout.preferredHeight: Core.Style.controlHeightS

        radius: Core.Style.radiusS
        color: today ? Core.Theme.accent : Core.Theme.transparent

        Components.Text {
          anchors.centerIn: parent
          text: dayCell.day
          size: Core.Style.fontS
          color: dayCell.today ? Core.Theme.bg : Core.Theme.text
          weight: dayCell.today ? Core.Style.weightBold : Core.Style.weightNormal
        }
      }
    }
  }

  Components.Divider {
    Layout.topMargin: Core.Style.spaceS
    visible: Services.Weather.ready
  }

  // === Weather, once a city is set ===
  RowLayout {
    Layout.fillWidth: true
    visible: Services.Weather.ready
    spacing: 0
    uniformCellSizes: true

    Repeater {
      model: Services.Weather.days

      delegate: ColumnLayout {
        id: dayColumn

        required property var modelData
        required property int index

        // The date is a day, not a moment: built from its parts so no time zone moves it.
        readonly property var parts: modelData.date.split("-")
        readonly property date day: new Date(parts[0], parts[1] - 1, parts[2])

        Layout.fillWidth: true
        spacing: Core.Style.spaceXXS

        Components.Text {
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
          text: dayColumn.index === 0 ? "Today" : Qt.formatDate(dayColumn.day, "ddd")
          size: Core.Style.fontS
          color: Core.Theme.textDim
        }

        Components.Icon {
          Layout.alignment: Qt.AlignHCenter
          icon: Services.Weather.icon(dayColumn.modelData.code, false)
          size: Core.Style.fontXL
        }

        Components.Text {
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
          text: `${Math.round(dayColumn.modelData.max)}°`
          size: Core.Style.fontS
          weight: Core.Style.weightBold
        }

        Components.Text {
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
          text: `${Math.round(dayColumn.modelData.min)}°`
          size: Core.Style.fontS
          color: Core.Theme.textDim
        }
      }
    }
  }
}
