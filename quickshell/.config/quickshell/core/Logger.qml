pragma Singleton

import QtQuick
import Quickshell

/**
* Logger - levelled logging for the shell
*
* Everything that wants to say something goes through here rather than through
* console.*, so there is one place that decides the format, the level, and what
* gets dropped.
*
* Deliberately dependency-free. Binding the level to Config.debugMode here
* meant Config could not log without Settings, Logger and Config all trying to
* construct each other. The level is *pushed* in from shell.qml instead, so
* nothing this file touches can call back into it.
*
* Usage:
*   Core.Logger.d("Audio", "sink changed", node.name)
*   Core.Logger.w("Network", `nmcli exited ${code}`)
*/
Singleton {
  id: root

  // === Levels ===
  readonly property int levelDebug: 0
  readonly property int levelInfo: 1
  readonly property int levelWarn: 2
  readonly property int levelError: 3
  readonly property int levelOff: 4

  readonly property var levelNames: ["debug", "info", "warn", "error", "off"]

  /**
  * Messages below this are dropped. Set from shell.qml, which follows
  * Config.debugMode.
  */
  property int level: levelInfo

  readonly property string levelName: levelNames[level] ?? "info"

  // === Repeat suppression ===
  // The polling services can emit the same line every tick when something is
  // wrong. Identical consecutive messages are counted instead of printed, and
  // the tally is flushed when a different message arrives.
  readonly property int repeatWindowMs: 10000

  property string _lastKey: ""
  property int _repeats: 0
  property double _lastAt: 0

  // === Public API ===

  function d(module, ...args) {
    root._emit(root.levelDebug, module, args);
  }

  function i(module, ...args) {
    root._emit(root.levelInfo, module, args);
  }

  function w(module, ...args) {
    root._emit(root.levelWarn, module, args);
  }

  function e(module, ...args) {
    root._emit(root.levelError, module, args);
  }

  // === Internals ===

  /**
  * Render one argument.
  *
  * args.join(" ") used to be enough only because every call site passed
  * strings; anything else came out as "[object Object]", which is exactly the
  * case you were trying to inspect.
  */
  function _render(value) {
    if (typeof value === "string")
      return value;
    if (value === null)
      return "null";
    if (value === undefined)
      return "undefined";
    if (value instanceof Error)
      return `${value.name}: ${value.message}`;
    if (typeof value === "object") {
      try {
        return JSON.stringify(value);
      } catch (err) {
        return String(value);
      }
    }
    return String(value);
  }

  function _format(module, text) {
    const timestamp = Qt.formatDateTime(new Date(), "hh:mm:ss");
    const paddedModule = String(module).substring(0, 12).padStart(12, " ");
    return `[${timestamp}] ${paddedModule} | ${text}`;
  }

  function _write(severity, line) {
    if (severity >= root.levelError)
      console.error(line);
    else if (severity >= root.levelWarn)
      console.warn(line);
    else if (severity >= root.levelInfo)
      console.info(line);
    else
      console.log(line);
  }

  function _emit(severity, module, args) {
    if (severity < root.level)
      return;

    const text = args.map(root._render).join(" ");
    const key = `${severity} ${module} ${text}`;
    const now = Date.now();

    if (key === root._lastKey && (now - root._lastAt) < root.repeatWindowMs) {
      root._repeats++;
      root._lastAt = now;
      return;
    }

    if (root._repeats > 0) {
      root._write(severity, root._format("Logger", `last message repeated ${root._repeats} more time(s)`));
      root._repeats = 0;
    }

    root._lastKey = key;
    root._lastAt = now;
    root._write(severity, root._format(module, text));
  }
}
