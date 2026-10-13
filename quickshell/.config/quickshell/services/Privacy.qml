pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

/**
* Privacy - what is listening, and whether the screen is shared
*
* An app records from a microphone when its stream is linked from an input
* device. A recorder of desktop audio links from an output instead and never
* appears here. A level meter does appear, and says what it is: pavucontrol's
* "Peak detect" streams carry stream.monitor.
*/
Singleton {
  id: root

  // The apps recording from any input device.
  readonly property var micUsers: [...new Set(_linked.filter(n => n?.ready && n.properties["stream.monitor"] !== "true").map(n => n.properties["application.name"] || n.name))]
  readonly property bool micInUse: micUsers.length > 0

  // The portal's stream for a share, named after the portal's backend. A
  // screenshot and the shell's recorder do not go through the portal.
  readonly property bool screenShared: Pipewire.nodes.values.some(node => node.name === "xdg-desktop-portal-hyprland")

  // Every node an input device is linked to.
  readonly property var _linked: {
    const nodes = [];
    for (const tracker of inputs.instances) {
      for (const group of tracker.linkGroups)
        nodes.push(group.target);
    }
    return nodes;
  }

  Variants {
    id: inputs

    model: Audio.sourceDevices

    PwNodeLinkTracker {
      required property PwNode modelData

      node: modelData
    }
  }

  // A node's properties are only filled in while it is tracked.
  PwObjectTracker {
    objects: root._linked
  }
}
