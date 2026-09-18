pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../config" as Config
import "../core" as Core

/**
* Wallpaper - which image is on the screen, and what else is available
*
* hyprpaper holds the image; this chooses it. Its entire control surface is
* `hyprctl hyprpaper wallpaper <monitor>,<path>`, which brings three constraints:
*
* - A path containing a comma cannot be expressed, because hyprpaper splits on
*   the first one. Those files are left out rather than offered and then failing.
* - hyprctl exits 0 even when hyprpaper rejects a path, so a change is confirmed
*   by reading listactive back rather than by the exit code.
* - Setting one stops hyprpaper cycling the directory for good. Only a restart
*   resumes it, which is what shuffle() does.
*
* A chosen wallpaper is re-applied at startup: hyprpaper picks from the clock,
* so it comes back on its own rotation and would otherwise drop the choice.
*/
Singleton {
  id: root

  readonly property string directory: Config.Config.wallpaperDirectory

  // hyprpaper reports paths with symlinks resolved, and ~/.config/hypr is a
  // symlink into the repo. Listing from the resolved directory keeps `current`
  // comparable with `wallpapers`.
  property string _resolved: ""

  // Paths in `directory`, sorted by name, minus any the IPC cannot express.
  property var wallpapers: []

  // What hyprpaper says is on screen.
  property string current: ""

  // The chosen one, or "" while hyprpaper cycles the directory itself.
  readonly property string pinned: Config.Config.wallpaper
  readonly property bool shuffling: root.pinned === ""

  property bool busy: false

  // A space or a # in a name makes a bare "file://" + path load nothing, and
  // RoundedImage only shows itself once the image is Ready, so it fails silently.
  function url(path) {
    return `file://${String(path).split("/").map(encodeURIComponent).join("/")}`;
  }

  function name(path) {
    const file = String(path).split("/").pop();
    return file.replace(/\.[^.]+$/, "").replace(/[-_]+/g, " ");
  }

  function refresh() {
    if (root._resolved === "")
      _resolve.running = true;
    else
      _list.running = true;
  }

  function set(path) {
    if (!path || path.indexOf(",") >= 0) {
      Core.Logger.w("Wallpaper", `cannot set ${path}: hyprpaper splits its argument on the first comma`);
      return false;
    }
    root._requested = path;
    root._send(path);
    return true;
  }

  function shuffle() {
    Config.Config.setWallpaper("");
    Core.Logger.i("Wallpaper", "handed back to hyprpaper's rotation");
    _restart.running = true;
  }

  function apply() {
    if (root.pinned !== "")
      root._send(root.pinned);
    else
      _active.running = true;
    root.refresh();
  }

  // Set only once hyprpaper confirms it took the path, so a file that has since
  // been moved or deleted is not saved and retried at every startup.
  property string _requested: ""

  function _send(path) {
    root.busy = true;
    // Empty monitor: every output.
    _set.command = ["hyprctl", "hyprpaper", "wallpaper", `,${path}`];
    _set.running = true;
  }

  Component.onCompleted: root.apply()

  Process {
    id: _resolve

    command: ["readlink", "-f", root.directory]
    onExited: _list.running = true

    stdout: StdioCollector {
      onStreamFinished: root._resolved = text.trim() || root.directory
    }
  }

  Process {
    id: _list

    command: ["find", root._resolved || root.directory, "-maxdepth", "1", "-type", "f"]

    stdout: StdioCollector {
      onStreamFinished: {
        const found = text.split("\n").filter(p => /\.(jpe?g|png|webp|bmp)$/i.test(p));
        const usable = found.filter(p => p.indexOf(",") < 0);
        if (usable.length < found.length)
          Core.Logger.w("Wallpaper", `${found.length - usable.length} file(s) skipped: a comma in the name cannot be passed to hyprpaper`);
        usable.sort((a, b) => a.localeCompare(b));

        // Assigning an equal array still rebuilds every delegate in the grid,
        // which re-decodes all 42 thumbnails on each panel open.
        const same = usable.length === root.wallpapers.length && usable.every((p, i) => p === root.wallpapers[i]);
        if (!same)
          root.wallpapers = usable;
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        const msg = text.trim();
        if (msg)
          Core.Logger.w("Wallpaper", msg);
      }
    }
  }

  Process {
    id: _set

    onExited: _active.running = true

    stdout: StdioCollector {
      onStreamFinished: {
        // hyprctl reports hyprpaper's refusal here and still exits 0.
        if (text.indexOf("error") >= 0)
          Core.Logger.w("Wallpaper", text.trim());
      }
    }
  }

  Process {
    id: _active

    command: ["hyprctl", "hyprpaper", "listactive"]

    stdout: StdioCollector {
      onStreamFinished: {
        root.busy = false;
        const line = text.split("\n").find(l => l.indexOf(": /") > 0);
        root.current = line ? line.slice(line.indexOf(": /") + 2) : "";

        if (root._requested === "")
          return;
        // hyprpaper answers with symlinks resolved, so a path given by name
        // still counts as taken.
        const asked = root._requested.split("/").pop();
        if (root.current.endsWith(`/${asked}`))
          Config.Config.setWallpaper(root.current);
        else
          Core.Logger.w("Wallpaper", `hyprpaper did not take ${root._requested}`);
        root._requested = "";
      }
    }
  }

  Process {
    id: _restart

    command: ["systemctl", "--user", "restart", "hyprpaper"]
    onExited: _settle.restart()
  }

  // hyprpaper binds its socket a moment after the unit reports started.
  Timer {
    id: _settle

    interval: 1500
    onTriggered: _active.running = true
  }
}
