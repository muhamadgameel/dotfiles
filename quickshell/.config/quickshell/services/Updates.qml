pragma Singleton

import QtQuick
import Quickshell

import "../core" as Core

/**
* Updates - what pacman and the AUR have waiting
*
* checkupdates syncs a copy of the package database, so asking changes nothing
* on the system. The upgrade runs in a terminal of its own: as a child of the
* shell, a saved QML file would kill pacman halfway.
*/
Singleton {
  id: root

  // "name old -> new", the repositories first, then the AUR.
  readonly property var packages: _kept.lines === "" ? [] : _kept.lines.split("\n")
  readonly property int count: packages.length
  readonly property bool checking: _repo.running || _aur.running
  readonly property real checkedAt: _kept.checkedAt

  readonly property int checkEveryMs: 6 * 3600 * 1000

  function check() {
    _repo.running = true;
  }

  function upgrade() {
    Quickshell.execDetached(["uwsm-app", "--", "alacritty", "-e", "bash", "-c", "yay -Syu; qs ipc call updates check >/dev/null; read -rsn1 -p 'Press a key to close.'"]);
  }

  // What the last check found survives a reload. A restart asks again.
  PersistentProperties {
    id: _kept

    reloadableId: "updates"

    property string lines: ""
    property real checkedAt: 0
  }

  property string _repoLines: ""

  Core.Command {
    id: _repo
    tag: "Updates"

    command: ["checkupdates"]

    // 0 with a list, 2 with nothing to update. Anything else could not ask, the
    // network being down for one, and the last answer stands.
    onDone: (code, out) => {
      if (code !== 0 && code !== 2)
        return;
      root._repoLines = out.trim();
      _aur.running = true;
    }
  }

  Core.Command {
    id: _aur

    command: ["yay", "-Qua"]

    onDone: (code, out) => {
      _kept.lines = [root._repoLines, code === 0 ? out.trim() : ""].filter(part => part !== "").join("\n");
      _kept.checkedAt = Date.now();
    }
  }

  // Looks once a minute whether a check is due, so the six hours count from the
  // last check and a reload does not push them back.
  Timer {
    interval: 60000
    repeat: true
    running: true
    onTriggered: {
      if (Date.now() - _kept.checkedAt >= root.checkEveryMs)
        root.check();
    }
  }
}
