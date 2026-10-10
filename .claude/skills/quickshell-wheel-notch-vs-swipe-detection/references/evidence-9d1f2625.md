// Wheel notches only: a swipe is dozens of events, each with a scroll phase.
      if (event.phase === Qt.NoScrollPhase)
        root.monthOffset -= Math.sign(event.angleDelta.y);