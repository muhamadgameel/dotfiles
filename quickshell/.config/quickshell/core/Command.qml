import QtQuick
import Quickshell.Io

import "." as Core

/**
* Command - a Process that collects its output and reports once, when it exits
*
* Usage:
*   Command {
*       tag: "Display"
*       command: ["hyprctl", "-j", "monitors"]
*       onDone: (code, out, err) => parse(out)
*   }
*/
Process {
  id: root

  // Logger module for what the command writes to stderr; "" keeps it quiet.
  property string tag: ""
  // What those lines start with, for when the command's own name says little.
  property string label: ""

  signal done(int code, string out, string err)

  // Quickshell sends no exited for a program that cannot start, so a caller waiting
  // on done would wait forever: that is reported as a failed run, code -1.
  property bool _exited: false

  stdout: StdioCollector {
    id: out
  }

  stderr: StdioCollector {
    id: err
  }

  onExited: code => {
    root._exited = true;
    const msg = err.text.trim();
    if (msg !== "" && root.tag !== "")
      Core.Logger.w(root.tag, root.label === "" ? msg : `${root.label}: ${msg}`);
    root.done(code, out.text, err.text);
  }

  onRunningChanged: {
    if (root.running)
      return;
    if (!root._exited)
      root.done(-1, "", "");
    root._exited = false;
  }
}
