pragma Singleton

import QtQuick
import Quickshell

import "../config" as Config
import "../core" as Core

/**
* Wallpaper - which image is on the screen, and what else is available
*
* awww-daemon draws the image and shows the last one again at login; this
* chooses it. While nothing is pinned, the timer here picks another every hour.
*/
Singleton {
  id: root

  readonly property string directory: Config.Config.wallpaperDirectory

  // Paths in `directory`, sorted by name.
  property var wallpapers: []

  // What awww says is on screen.
  property string current: ""

  // The chosen one, or "" while the hourly timer picks.
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
    if (!root.busy)
      _active.running = true;
    _list.running = true;
  }

  function set(path) {
    if (!path)
      return false;
    root._requested = path;
    root._send(path);
    return true;
  }

  function shuffle() {
    Config.Config.setWallpaper("");
    Core.Logger.i("Wallpaper", "rotating every hour");
    root._next();
  }

  // awww shows the last image again by itself, so only a pin it never saw is sent.
  function apply() {
    root._checkPin = true;
    root.refresh();
  }

  // Set only once awww shows it, so a file that has since been moved or
  // deleted is not saved and retried at every startup.
  property string _requested: ""
  property bool _checkPin: false
  property bool _retried: false

  function _send(path) {
    root.busy = true;
    root._retried = false;
    _set.command = ["awww", "img", "--transition-type", "fade", "--transition-duration", "1", path];
    _set.running = true;
  }

  function _next() {
    const others = root.wallpapers.filter(p => p !== root.current);
    if (others.length > 0)
      root._send(others[Math.floor(Math.random() * others.length)]);
  }

  Core.Command {
    id: _list
    tag: "Wallpaper"

    command: ["find", root.directory, "-maxdepth", "1", "-type", "f"]

    onDone: (code, out) => {
      const found = out.split("\n").filter(p => /\.(jpe?g|png|webp|bmp)$/i.test(p));
      found.sort((a, b) => a.localeCompare(b));

      // Assigning an equal array still rebuilds every delegate in the grid,
      // which re-decodes all 42 thumbnails on each panel open.
      const same = found.length === root.wallpapers.length && found.every((p, i) => p === root.wallpapers[i]);
      if (!same)
        root.wallpapers = found;
    }
  }

  Core.Command {
    id: _set

    onDone: (code, out, err) => {
      // At login the shell can ask before the daemon has its socket.
      if (code !== 0 && !root._retried) {
        root._retried = true;
        _retry.restart();
        return;
      }
      if (code !== 0)
        Core.Logger.w("Wallpaper", err.trim());
      _active.running = true;
    }
  }

  Timer {
    id: _retry

    interval: 1500
    onTriggered: _set.running = true
  }

  Core.Command {
    id: _active

    command: ["awww", "query", "--json"]

    onDone: (code, out) => {
      root.busy = false;
      const outputs = [].concat(...Object.values(Core.Utils.parseJson(out, {})));
      root.current = outputs.map(o => o.displaying?.image).find(Boolean) ?? "";

      if (root._requested !== "") {
        if (root.current === root._requested)
          Config.Config.setWallpaper(root.current);
        else
          Core.Logger.w("Wallpaper", `awww did not take ${root._requested}`);
        root._requested = "";
      }

      if (root._checkPin) {
        root._checkPin = false;
        if (root.pinned !== "" && root.current !== root.pinned)
          root._send(root.pinned);
      }
    }
  }

  Timer {
    interval: 3600 * 1000
    repeat: true
    running: root.shuffling
    onTriggered: root._next()
  }
}
