pragma ComponentBehavior: Bound

import QtQuick

import "." as Components

/**
* InfoList - collapsible list of read-only label/value rows
*
* Usage:
*   InfoList {
*       title: "Connection Info"
*       icon: "chart"
*       rows: [
*           { label: "Interface", value: iface },
*           { label: "IP Address", value: ip },
*       ]
*   }
*/
Components.Collapsible {
  id: root

  // [{ label, value }]
  property var rows: []

  expanded: false

  // Driven by the row count rather than by the array. `rows` is a fresh array
  // whenever any one value in it changes - a signal-strength poll, say - and a
  // Repeater on the array rebuilt every row each time. Keyed by count, a row
  // only comes or goes with the count and just rebinds its text otherwise.
  Repeater {
    model: root.rows.length

    Components.FormRow {
      required property int index

      readonly property var row: root.rows[index] ?? ({})

      label: String(row.label ?? "")
      valueText: String(row.value ?? "")
    }
  }
}
