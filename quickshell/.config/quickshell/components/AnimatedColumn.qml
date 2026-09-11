import QtQuick

import "../core" as Core

/**
* AnimatedColumn - a Column whose rows glide into place instead of jumping
*
* Rows that get pushed around - by an insertion, a removal, a re-sort, a row
* becoming visible or hidden, or a sibling changing height - slide to their new
* position, and newly added rows fade in (or slide in, with enterOffset).
*
* A row that animates its own exit should do it on an inner item, not on the
* row the column positions - otherwise a move while it is leaving pulls it back.
*
* A ColumnLayout cannot do this: layouts have no transitions, which is why every
* list used to snap. So children size themselves (`width: parent.width`) rather
* than through Layout.* attached properties.
*
* Usage:
*   AnimatedColumn {
*       width: parent.width
*       animated: panel.revealed   // off while the list is first filled in
*
*       Repeater {
*           model: rows
*           delegate: Row { width: parent.width }
*       }
*   }
*/
Column {
  id: root

  // Off while the list is first being built, so a panel that fills its list as
  // it opens does not fade every row in at once.
  property bool animated: true

  // Fade added rows in. Switch off when the rows run their own entrance and
  // exit on opacity (the notification popups): the fade here would fight it,
  // and so would the opacity restore in the move transition below.
  property bool fadeIn: true

  // How far added rows travel in from the right as they fade, px. 0 is a plain
  // fade. Needs fadeIn.
  property real enterOffset: 0

  add: !root.animated || !root.fadeIn ? null : root.enterOffset !== 0 ? slideInTransition : fadeInTransition
  move: !root.animated ? null : root.fadeIn ? moveAndSettleTransition : moveTransition

  Transition {
    id: slideInTransition

    NumberAnimation {
      property: "x"
      from: root.enterOffset
      to: 0
      duration: Core.Style.duration(Core.Style.slideShowDuration)
      easing.type: Core.Style.easeStandard
    }

    NumberAnimation {
      property: "opacity"
      from: 0
      to: 1
      duration: Core.Style.duration(Core.Style.slideShowDuration)
      easing.type: Core.Style.easeStandard
    }
  }

  Transition {
    id: fadeInTransition

    NumberAnimation {
      property: "opacity"
      from: 0
      to: 1
      duration: Core.Style.duration(Core.Style.animNormal)
      easing.type: Core.Style.easeStandard
    }
  }

  Transition {
    id: moveTransition

    NumberAnimation {
      property: "y"
      duration: Core.Style.duration(Core.Style.animNormal)
      easing.type: Core.Style.easeStandard
    }
  }

  // A row moved while its entrance is still running has that entrance cancelled,
  // and would be left stuck part-transparent or part-way in from the edge.
  // Finishing it as part of the move is the documented fix for interrupted view
  // transitions. Assumes rows sit at x: 0, which every list here does.
  Transition {
    id: moveAndSettleTransition

    NumberAnimation {
      property: "y"
      duration: Core.Style.duration(Core.Style.animNormal)
      easing.type: Core.Style.easeStandard
    }

    NumberAnimation {
      property: "x"
      to: 0
      duration: Core.Style.duration(Core.Style.animNormal)
      easing.type: Core.Style.easeStandard
    }

    NumberAnimation {
      property: "opacity"
      to: 1
      duration: Core.Style.duration(Core.Style.animNormal)
      easing.type: Core.Style.easeStandard
    }
  }
}
