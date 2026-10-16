pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

import "../core" as Core

/**
* KeyboardLayout - the layout the keyboards are on
*
* Every keyboard device has a layout of its own, and they are switched together.
* A device that has just appeared announces its layout too, the first one, and
* becomes Hyprland's "main" keyboard at once, so neither the last event nor the
* main keyboard says what is being typed. This takes the layout most devices
* are on.
*/
Singleton {
  id: root

  // "English (US)", and "EN" for the bar.
  property string name: ""
  readonly property string label: name.slice(0, 2).toUpperCase()

  // Whether more than one layout is configured.
  property bool hasChoice: false

  // Whether that layout is the first one configured.
  property bool isDefault: true

  function next() {
    _next.running = true;
  }

  Core.Command {
    id: _read

    running: true
    command: ["hyprctl", "-j", "devices"]

    onDone: (code, out) => {
      const keyboards = Core.Utils.parseJson(out, ({})).keyboards ?? [];
      const count = {};
      for (const keyboard of keyboards)
        count[keyboard.active_keymap] = (count[keyboard.active_keymap] ?? 0) + 1;
      root.name = Object.keys(count).sort((a, b) => count[b] - count[a])[0] ?? "";
      root.isDefault = keyboards.some(keyboard => keyboard.active_keymap === root.name && keyboard.active_layout_index === 0);
      root.hasChoice = keyboards.some(keyboard => keyboard.layout.includes(","));
    }
  }

  Core.Command {
    id: _next

    command: ["hyprctl", "switchxkblayout", "all", "next"]
  }

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      if (event.name === "activelayout")
        _read.running = true;
    }
  }
}
