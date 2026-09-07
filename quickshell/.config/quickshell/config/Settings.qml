pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../core" as Core

/**
* Settings - user settings that survive a restart
*
* Values live in one JSON object under XDG state. Reads go through get() with a
* caller-supplied default, so a missing or partial file is always fine and no
* migration is needed when a key is added. Writes are debounced and atomic.
*
* The file is watched, so editing settings.json by hand takes effect
* immediately - every Config property is a binding on `values`, and replacing
* that object re-evaluates all of them.
*
* Config.qml wraps this with typed, named accessors - prefer those over calling
* get() directly.
*
* Usage:
*   Config.Settings.get("barShowClock", true)
*   Config.Settings.set("barShowClock", false)
*   Config.Settings.toggle("doNotDisturb")
*/
Singleton {
  id: root

  readonly property string directory: `${Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")}/quickshell`
  readonly property string path: `${directory}/settings.json`

  /**
  * The settings object.
  */
  property var values: ({})

  // How long after our own write to ignore the resulting file-change event, so
  // a pending in-memory change is not overwritten by the copy we just saved.
  readonly property int selfWriteGraceMs: 1000

  property double _lastSelfWrite: 0

  // === Public API ===

  /**
  * Read a setting.
  * @param key - Setting name
  * @param fallback - Value to use when unset. This is the source of truth for
  *   defaults; nothing is written to disk until it is actually changed.
  */
  function get(key, fallback) {
    const v = values[key];
    return v === undefined ? fallback : v;
  }

  /**
  * Write a setting and schedule a save.
  */
  function set(key, value) {
    if (values[key] === value)
      return value;

    const next = Object.assign({}, values);
    next[key] = value;
    values = next;

    saveTimer.restart();
    return value;
  }

  /**
  * Flip a boolean setting and return the new value.
  */
  function toggle(key, fallback) {
    return set(key, !get(key, fallback ?? false));
  }

  /**
  * Forget a setting, so its caller-supplied default applies again.
  */
  function unset(key) {
    if (!(key in values))
      return;

    const next = Object.assign({}, values);
    delete next[key];
    values = next;
    saveTimer.restart();
  }

  // === Internals ===

  /**
  * Take the watcher's current contents as the live settings.
  *
  * Skipped while one of our own writes is in flight: FileView.setText() trips
  * the change watcher, and adopting that echo would clobber anything the user
  * changed while the save was still debounced.
  */
  function _adopt() {
    if (saveTimer.running || (Date.now() - root._lastSelfWrite) < root.selfWriteGraceMs)
      return;

    const next = _parse(file.text());
    if (JSON.stringify(next) === JSON.stringify(root.values))
      return;

    root.values = next;
    Core.Logger.d("Settings", `reloaded ${Object.keys(next).length} key(s) from disk`);
  }

  function _parse(raw) {
    try {
      const trimmed = (raw ?? "").trim();
      if (trimmed === "")
        return ({});

      const parsed = JSON.parse(trimmed);
      return (parsed && typeof parsed === "object") ? parsed : ({});
    } catch (e) {
      // Corrupt or unreadable: start from defaults rather than refusing to
      // load. The file is rewritten on the next set().
      Core.Logger.w("Settings", `could not parse ${root.path}, using defaults (${e})`);
      return ({});
    }
  }

  function _save() {
    root._lastSelfWrite = Date.now();
    file.setText(JSON.stringify(root.values, null, 2) + "\n");
  }

  // Coalesces bursts - a slider bound to a setting would otherwise rewrite the
  // file on every frame of a drag.
  Timer {
    id: saveTimer
    interval: 400
    repeat: false
    onTriggered: root._save()
  }

  FileView {
    id: file

    path: root.path
    blockLoading: true   // so the first get() already has real values
    printErrors: false   // absent on first run, which is normal
    atomicWrites: true   // never leave a half-written settings file behind
    watchChanges: true

    // Picked up when the file is edited by hand or by another instance.
    onFileChanged: reload()

    onLoaded: root._adopt()
    onLoadFailed: err => Core.Logger.d("Settings", `no settings file yet (${err})`)
    onSaveFailed: err => Core.Logger.w("Settings", `could not write ${root.path}: ${err}`)
  }

  // blockLoading means the file is read during construction, which can be before
  // the handler above is connected; take the contents once more on completion.
  Component.onCompleted: root.values = _parse(file.text())

  // FileView will not create the directory, and it does not exist on first run.
  Process {
    running: true
    command: ["mkdir", "-p", root.directory]
  }
}
