pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../core" as Core
import "../services" as Services

/**
* Screenshot - grim/slurp capture
*
* Destinations match the existing keybinds in hypr/settings/keybinds.lua
* (~/Pictures/Screenshots, created if missing) so the menu and the keys agree
* on where things land.
*/
Singleton {
  id: root

  readonly property string directoryExpr: '"$(xdg-user-dir PICTURES)/Screenshots"'

  // Display-only resolved form; the capture itself uses directoryExpr.
  property string directory: `${Quickshell.env("HOME")}/Pictures/Screenshots`

  Process {
    running: true
    command: ["xdg-user-dir", "PICTURES"]

    stdout: StdioCollector {
      onStreamFinished: {
        const dir = text.trim();
        if (dir !== "")
          root.directory = `${dir}/Screenshots`;
      }
    }
  }

  // Set while a capture is running, so the UI can show progress and the menu
  // can hide itself out of the shot.
  property bool capturing: false

  // Path of the most recent capture, "" if none this session.
  property string lastPath: ""

  signal captured(string path)
  signal failed(string message)

  function _filename() {
    return `${root.directoryExpr}/"$(date +%Y-%m-%d_%H-%M-%S)".png`;
  }

  /**
  * @param mode - "region" (drag) | "window" (pick one) | "output" | "screen"
  * @param toClipboard - copy instead of saving to disk
  * @param delaySeconds - wait before capturing
  */
  function capture(mode, toClipboard, delaySeconds) {
    if (capturing) {
      // Used to return in silence, which is how one wedged capture could
      // disable the whole feature without leaving a trace anywhere.
      Core.Logger.w("Screenshot", `ignoring ${mode}: a capture is already in progress`);
      return false;
    }

    // Latched here rather than in _start(), so a second request during the wait
    // is refused like any other overlapping one.
    capturing = true;
    root._pending = ({
        mode: mode,
        toClipboard: toClipboard === true,
        delaySeconds: delaySeconds > 0 ? delaySeconds : 0
      });
    watchdog.restart();

    // Close whatever is open rather than only waiting for it. A capture asked
    // for from a keybind or `qs ipc call` has no panel politely closing itself
    // in the background, and without this the request would sit waiting for a
    // teardown that was never coming. It also means no panel can end up in a
    // shot no matter which entry point was used.
    Services.Panels.close();
    root._settleIfClear();
    return true;
  }

  // === Waiting for the shell to get out of the shot ===

  // The request in flight, held while the panels finish closing.
  property var _pending: null

  // Time between the panel window being destroyed and the compositor having
  // actually repainted without it. A couple of frames.
  readonly property int surfaceSettleMs: 120

  /**
  * Start the settle countdown once no panel window is left.
  *
  * Panels.retainedPanel is the authority on that: it holds a panel alive
  * through its close animation and clears when the loader tears the window
  * down. Watching it rather than copying the animation duration means the wait
  * stays correct if that timing is ever retuned.
  */
  function _settleIfClear() {
    if (root._pending && Services.Panels.retainedPanel === "")
      settleTimer.restart();
  }

  Connections {
    target: Services.Panels

    function onRetainedPanelChanged() {
      root._settleIfClear();
    }
  }

  Timer {
    id: settleTimer
    interval: root.surfaceSettleMs
    repeat: false

    onTriggered: {
      const request = root._pending;
      root._pending = null;
      if (request)
        root._start(request.mode, request.toClipboard, request.delaySeconds);
    }
  }

  function _start(mode, toClipboard, delaySeconds) {
    // set -e so a failed grim does not go on to report a file it never wrote.
    // exec </dev/null so slurp does not sit waiting on a pipe
    const lines = ["set -eo pipefail", "exec </dev/null"];

    if (delaySeconds > 0)
      lines.push(`sleep ${delaySeconds}`);

    let geometry = "";

    if (mode === "region") {
      // Cancelling is a normal outcome, not a failure: slurp exits non-zero and
      // this leaves quietly rather than handing grim an empty -g and letting it
      // complain about invalid geometry.
      lines.push("geom=$(slurp -d) || exit 0");
      lines.push('[ -n "$geom" ] || exit 0');
      geometry = '-g "$geom" ';
    } else if (mode === "window") {
      lines.push('rects=$(jq -rn --argjson m "$(hyprctl monitors -j)" --argjson c "$(hyprctl clients -j)" \'($m | map(.activeWorkspace.id)) as $ws | $c[] | select(.mapped and (.hidden | not) and (.workspace.id | IN($ws[]))) | "\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])"\')');
      lines.push('[ -n "$rects" ] || { echo "no windows on screen to pick" >&2; exit 1; }');
      lines.push('geom=$(echo "$rects" | slurp -r) || exit 0');
      lines.push('[ -n "$geom" ] || exit 0');
      geometry = '-g "$geom" ';
    } else if (mode === "output") {
      geometry = `-o "$(hyprctl -j activeworkspace | jq -r '.monitor')" `;
    }

    if (toClipboard) {
      // wl-copy stays resident to serve the selection, so its stdio is sent to
      // /dev/null; left attached it would hold the collectors' pipes open and
      // the capture would never look finished.
      lines.push(`grim ${geometry}- | wl-copy --type image/png >/dev/null 2>&1`);
      lines.push("echo CLIPBOARD");
    } else {
      lines.push(`mkdir -p ${root.directoryExpr}`);
      lines.push(`f=${root._filename()}`);
      lines.push(`grim ${geometry}"$f"`);
      lines.push('echo "$f"');
    }

    _proc.mode = mode;
    _proc.command = ["sh", "-c", lines.join("\n")];
    _proc.running = true;
  }

  // A capture that never finishes must not disable the feature until the next
  // restart, which is exactly what the slurp hang did. Generous enough that a
  // slow deliberate selection is never cut short.
  readonly property int watchdogMs: 180000

  Timer {
    id: watchdog
    interval: root.watchdogMs
    repeat: false
    onTriggered: {
      if (!root.capturing)
        return;
      const what = root._pending ? root._pending.mode : _proc.mode;
      Core.Logger.w("Screenshot", `capture '${what}' did not finish in ${root.watchdogMs / 1000}s, cancelling`);
      settleTimer.stop();
      root._pending = null;
      _proc.running = false;
      root.capturing = false;
    }
  }

  Process {
    id: _proc

    property string mode: ""
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        const out = text.trim();
        if (out === "" || out === "CLIPBOARD") {
          if (out === "CLIPBOARD")
            root.captured("");
          return;
        }
        root.lastPath = out;
        root.captured(out);
        Core.Logger.i("Screenshot", `Saved ${out}`);
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        const err = text.trim();
        // A cancelled selection now exits 0 from the script itself, so anything
        // reaching here is a real problem. The explicit check stays for the
        // cancellation paths that still write to stderr.
        if (err === "" || err.includes("selection cancelled"))
          return;
        Core.Logger.w("Screenshot", err);
        root.failed(err.split("\n")[0]);
      }
    }

    onExited: {
      watchdog.stop();
      root.capturing = false;
    }
  }

  /**
  * Forget lastPath if the file is no longer on disk.
  *
  * Checked when the panel opens rather than watched continuously: it only
  * matters at the moment someone can actually click those buttons, and a
  * watcher on a path that is usually absent earns nothing.
  */
  function verifyLastPath() {
    if (lastPath === "" || _existsProc.running)
      return;

    _existsProc.candidate = lastPath;
    _existsProc.command = ["test", "-e", lastPath];
    _existsProc.running = true;
  }

  Process {
    id: _existsProc

    // The path this check was started for. A capture can finish while the check
    // is in flight, and clearing lastPath then would throw away a live file.
    property string candidate: ""

    running: false

    onExited: code => {
      if (code === 0 || root.lastPath !== _existsProc.candidate)
        return;

      Core.Logger.i("Screenshot", `forgetting ${_existsProc.candidate}, no longer on disk`);
      root.lastPath = "";
    }
  }

  /**
  * Open the most recent capture in the default image viewer.
  */
  function openLast() {
    if (lastPath === "")
      return;
    Quickshell.execDetached(["xdg-open", lastPath]);
  }

  /**
  * Copy the most recent capture to the clipboard.
  */
  function copyLast() {
    if (lastPath === "")
      return;
    Quickshell.execDetached(["sh", "-c", 'wl-copy --type image/png < "$1"', "quickshell-copy", lastPath]);
  }
}
