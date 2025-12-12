pragma Singleton

import QtQuick
import Quickshell

import "../config" as Config

Singleton {
  id: root

  readonly property bool debugEnabled: Config.Config.debugMode

  function _formatMessage(module, ...args) {
    var timestamp = Qt.formatDateTime(new Date(), "hh:mm:ss");
    var paddedModule = module.substring(0, 12).padStart(12, " ");
    return `[${timestamp}] ${paddedModule} | ${args.join(" ")}`;
  }

  // Debug log (only when debugEnabled)
  function d(module, ...args) {
    if (debugEnabled) {
      console.log(_formatMessage(module, ...args));
    }
  }

  // Info log
  function i(module, ...args) {
    console.info(_formatMessage(module, ...args));
  }

  // Warning log
  function w(module, ...args) {
    console.warn(_formatMessage(module, ...args));
  }

  // Error log
  function e(module, ...args) {
    console.error(_formatMessage(module, ...args));
  }
}
