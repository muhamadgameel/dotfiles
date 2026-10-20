pragma Singleton

import QtQuick
import Quickshell

/**
* Logger - levelled logging for the shell
*
* Everything that wants to say something goes through here rather than through
* console.*, so there is one place that decides the format and the level.
*
* Deliberately dependency-free. Binding the level to Config.debugMode here
* meant Config could not log without Settings, Logger and Config all trying to
* construct each other. The level is *pushed* in from shell.qml instead, so
* nothing this file touches can call back into it.
*
* Usage:
*   Core.Logger.d("Audio", `sink changed to ${node.name}`)
*   Core.Logger.w("Network", `nmcli exited ${code}`)
*/
Singleton {
  id: root

  readonly property int levelDebug: 0
  readonly property int levelInfo: 1
  readonly property int levelWarn: 2

  // Messages below this are dropped. Set from shell.qml, which follows
  // Config.debugMode.
  property int level: levelInfo

  function d(module, text) {
    root._emit(root.levelDebug, module, text);
  }

  function i(module, text) {
    root._emit(root.levelInfo, module, text);
  }

  function w(module, text) {
    root._emit(root.levelWarn, module, text);
  }

  function _emit(severity, module, text) {
    if (severity < root.level)
      return;

    const line = `[${Qt.formatDateTime(new Date(), "hh:mm:ss")}] ${String(module).substring(0, 12).padStart(12, " ")} | ${text}`;
    if (severity >= root.levelWarn)
      console.warn(line);
    else if (severity >= root.levelInfo)
      console.info(line);
    else
      console.log(line);
  }
}
