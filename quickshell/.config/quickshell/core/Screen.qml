pragma Singleton

import QtQuick
import Quickshell

Singleton {
  id: root

  // Get screen containing a global point
  function getScreenAt(globalX, globalY) {
    for (var i = 0; i < Quickshell.screens.length; i++) {
      var s = Quickshell.screens[i];
      if (globalX >= s.x && globalX < s.x + s.width && globalY >= s.y && globalY < s.y + s.height) {
        return s;
      }
    }
    return Quickshell.screens[0] || null;
  }

  // Get screen containing an item's center
  function getScreenForItem(item) {
    if (!item)
      return Quickshell.screens[0] || null;

    var center = item.mapToGlobal(item.width / 2, item.height / 2);
    return getScreenAt(center.x, center.y);
  }

  // Helper to create result object
  function makeResult(pos) {
    return {
      x: pos.x,
      y: pos.y
    };
  }

  // Calculate best position for a popup relative to anchor
  // Returns { x, y } where x,y are relative to anchor item
  function calculatePopupPosition(anchorItem, popupWidth, popupHeight, preferredDir, margin) {
    var defaultResult = {
      x: 0,
      y: 0
    };

    if (!anchorItem)
      return defaultResult;

    var screen = getScreenForItem(anchorItem);
    if (!screen)
      return defaultResult;

    var anchorGlobal = anchorItem.mapToGlobal(0, 0);
    var anchorW = anchorItem.width;
    var anchorH = anchorItem.height;

    // Calculate available space in each direction
    var spaceTop = anchorGlobal.y - screen.y;
    var spaceBottom = (screen.y + screen.height) - (anchorGlobal.y + anchorH);
    var spaceLeft = anchorGlobal.x - screen.x;
    var spaceRight = (screen.x + screen.width) - (anchorGlobal.x + anchorW);

    // Position configs for each direction
    var positions = {
      bottom: {
        x: (anchorW - popupWidth) / 2,
        y: anchorH + margin,
        fits: spaceBottom >= popupHeight + margin
      },
      top: {
        x: (anchorW - popupWidth) / 2,
        y: -popupHeight - margin,
        fits: spaceTop >= popupHeight + margin
      },
      right: {
        x: anchorW + margin,
        y: (anchorH - popupHeight) / 2,
        fits: spaceRight >= popupWidth + margin
      },
      left: {
        x: -popupWidth - margin,
        y: (anchorH - popupHeight) / 2,
        fits: spaceLeft >= popupWidth + margin
      }
    };

    // If preferred direction fits, use it
    if (preferredDir !== "auto" && positions[preferredDir] && positions[preferredDir].fits) {
      return makeResult(positions[preferredDir]);
    }

    // Auto: try directions in order of preference
    var order = ["bottom", "top", "right", "left"];
    for (var i = 0; i < order.length; i++) {
      var dir = order[i];
      if (positions[dir].fits) {
        return makeResult(positions[dir]);
      }
    }

    // None fit perfectly - use direction with most space
    var spaces = {
      top: spaceTop,
      bottom: spaceBottom,
      left: spaceLeft,
      right: spaceRight
    };
    var bestDir = "bottom";
    var bestSpace = spaceBottom;

    var dirs = ["top", "bottom", "left", "right"];
    for (var j = 0; j < dirs.length; j++) {
      var d = dirs[j];
      if (spaces[d] > bestSpace) {
        bestSpace = spaces[d];
        bestDir = d;
      }
    }

    var result = makeResult(positions[bestDir]);

    // Clamp horizontal position to keep on screen
    // TODO: explain this better
    var globalX = anchorGlobal.x + result.x;
    if (globalX < screen.x) {
      result.x = screen.x - anchorGlobal.x + margin;
    } else if (globalX + popupWidth > screen.x + screen.width) {
      result.x = (screen.x + screen.width) - anchorGlobal.x - popupWidth - margin;
    }

    return result;
  }
}
