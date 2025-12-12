pragma Singleton

import QtQuick
import Quickshell

import "../modules/tooltip" as TooltipModule

Singleton {
  id: root

  property var activeTooltip: null
  property Item lastTarget: null

  Component {
    id: tooltipComponent
    TooltipModule.Tooltip {}
  }

  function show(target, text, direction, delay) {
    if (!target || !text)
      return;

    // Ignore if same target (even during hide animation)
    if (lastTarget === target)
      return;

    // Hide existing tooltip
    if (activeTooltip)
      activeTooltip.hide();

    // Create and show new tooltip
    lastTarget = target;
    activeTooltip = tooltipComponent.createObject(null);
    activeTooltip.show(target, text, direction, delay);
  }

  function hide() {
    if (activeTooltip) {
      activeTooltip.hide();
      activeTooltip = null;
    }
    lastTarget = null;
  }
}
