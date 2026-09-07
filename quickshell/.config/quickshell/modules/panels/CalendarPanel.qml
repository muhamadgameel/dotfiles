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
  namespace: "quickshell-calendar-panel"

  headerIcon: "calendar"
  headerIconColor: Config.Theme.accent
  headerTitle: Services.Time.timeShort
  headerSubtitle: Services.Time.dateLong

  // Month currently on screen, as an offset from the real current month.
  property int monthOffset: 0

  // Always reopen on today rather than wherever the user browsed to last.
  onOpened: root.monthOffset = 0

  readonly property date today: new Date()

  readonly property date viewMonth: {
    const d = new Date(today.getFullYear(), today.getMonth() + monthOffset, 1);
    return d;
  }

  readonly property int viewYear: viewMonth.getFullYear()
  readonly property int viewMonthIndex: viewMonth.getMonth()

  // Monday-first, matching the locale convention here.
  readonly property var dayNames: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

  readonly property int daysInMonth: new Date(viewYear, viewMonthIndex + 1, 0).getDate()

  // Weekday index of the 1st, shifted so Monday is 0.
  readonly property int leadingBlanks: {
    const jsDay = new Date(viewYear, viewMonthIndex, 1).getDay();  // 0 = Sunday
    return (jsDay + 6) % 7;
  }

  function isToday(day) {
    return monthOffset === 0 && day === today.getDate();
  }

  // === Month navigation ===
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

  Components.Button {
    Layout.alignment: Qt.AlignHCenter
    visible: root.monthOffset !== 0
    variant: "secondary"
    text: "Back to today"
    textSize: Core.Style.fontS
    onClicked: root.monthOffset = 0
  }

  // === Weekday header ===
  GridLayout {
    Layout.fillWidth: true
    columns: 7
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
        color: Config.Theme.textMuted
        weight: Core.Style.weightBold
      }
    }
  }

  // === Day grid ===
  GridLayout {
    Layout.fillWidth: true
    columns: 7
    columnSpacing: 0
    rowSpacing: Core.Style.spaceXXS

    // Blanks before the 1st so the columns line up with the weekday header.
    Repeater {
      model: root.leadingBlanks

      delegate: Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 32
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
        Layout.preferredHeight: 32

        radius: Core.Style.radiusS
        color: today ? Config.Theme.accent : Config.Theme.transparent

        Components.Text {
          anchors.centerIn: parent
          text: dayCell.day
          size: Core.Style.fontS
          color: dayCell.today ? Config.Theme.bg : Config.Theme.text
          weight: dayCell.today ? Core.Style.weightBold : Core.Style.weightNormal
        }
      }
    }
  }

  Components.Divider {
    Layout.topMargin: Core.Style.spaceS
  }

  // === Clock ===
  ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Components.Text {
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignHCenter
      text: Services.Time.timeLong
      size: Core.Style.fontXXL
      weight: Core.Style.weightBold
    }

    Components.Text {
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignHCenter
      text: Services.Time.dateLong
      size: Core.Style.fontS
      color: Config.Theme.textDim
    }
  }
}
