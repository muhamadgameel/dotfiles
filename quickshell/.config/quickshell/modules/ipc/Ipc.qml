import QtQuick
import Quickshell
import Quickshell.Io

import "../../config" as Config
import "../../core" as Core
import "../../services" as Services

/**
* Ipc - external control surface
*
* Everything here is reachable from a shell:
*
*   qs ipc call panel toggle audio
*   qs ipc call panel close
*   qs ipc call notifications toggleDnd
*   qs ipc call media playPause
*   qs ipc call idle toggle
*   qs ipc call gamemode toggle
*
* `qs ipc show` lists the handlers and their signatures.
*
* Before this the shell was mouse-only: nothing outside the bar could open a
* panel or flip do-not-disturb.
*/
Scope {
  id: root

  IpcHandler {
    target: "panel"

    /**
    * Toggle a panel on the focused screen.
    * @param name - one of Services.Panels.ids
    */
    function toggle(name: string): string {
      if (!Services.Panels.ids.includes(name))
        return `unknown panel "${name}"; known: ${Services.Panels.ids.join(", ")}`;

      Services.Panels.toggle(name, Targets.focusedScreen);
      return Services.Panels.openPanel === name ? `opened ${name}` : `closed ${name}`;
    }

    /**
    * Open a panel on the focused screen, whether or not it is already open.
    */
    function open(name: string): string {
      if (!Services.Panels.open(name, Targets.focusedScreen))
        return `unknown panel "${name}"; known: ${Services.Panels.ids.join(", ")}`;
      return `opened ${name}`;
    }

    /**
    * Close whichever panel is open.
    */
    function close(): string {
      const was = Services.Panels.openPanel;
      Services.Panels.close();
      return was === "" ? "nothing was open" : `closed ${was}`;
    }

    /**
    * Report which panel is open, if any.
    */
    function status(): string {
      return Services.Panels.openPanel === "" ? "none" : Services.Panels.openPanel;
    }

    /**
    * List the panel names toggle()/open() accept.
    */
    function list(): string {
      return Services.Panels.ids.join(", ");
    }
  }

  IpcHandler {
    target: "workspace"

    /**
    * Switch to a workspace on the focused monitor.
    *
    * Goes through the same path the bar's workspace buttons use, so this also
    * exercises the Lua/plain dispatch split (Hyprland.usingLua).
    */
    function focus(id: int): string {
      Targets.focusWorkspace(id);
      return `workspace ${id}`;
    }

    /**
    * Move the focused window to a workspace without following it.
    */
    function move(id: int): string {
      Targets.moveToWorkspace(id);
      return `moved to ${id}`;
    }

    function usingLua(): bool {
      return Targets.usingLua;
    }
  }

  IpcHandler {
    target: "notifications"

    function toggleDnd(): string {
      return Config.Config.toggleDoNotDisturb() ? "dnd on" : "dnd off";
    }

    function setDnd(enabled: bool): string {
      Config.Config.setDoNotDisturb(enabled);
      return enabled ? "dnd on" : "dnd off";
    }

    function clear(): string {
      const n = Services.Notification.historyList.count;
      Services.Notification.clearHistory();
      return `cleared ${n}`;
    }

    function unread(): int {
      return Services.Notification.unreadCount;
    }
  }

  IpcHandler {
    target: "audio"

    function toggleMute(): string {
      Services.Audio.toggleMute();
      return Services.Audio.muted ? "muted" : "unmuted";
    }

    function toggleMicMute(): string {
      Services.Audio.toggleMicMute();
      return Services.Audio.micMuted ? "mic muted" : "mic unmuted";
    }

    function setVolume(percent: int): string {
      Services.Audio.setVolume(percent / 100);
      return `${Math.round(Services.Audio.volume * 100)}%`;
    }
  }

  IpcHandler {
    target: "media"

    function playPause(): string {
      Services.Media.playPause();
      return Services.Media.isPlaying ? "playing" : "paused";
    }

    function next(): string {
      Services.Media.next();
      return Services.Media.summary;
    }

    function previous(): string {
      Services.Media.previous();
      return Services.Media.summary;
    }

    function status(): string {
      return Services.Media.hasPlayer ? `${Services.Media.isPlaying ? "playing" : "paused"}: ${Services.Media.summary}` : "no player";
    }
  }

  IpcHandler {
    target: "idle"

    function toggle(): string {
      Services.Idle.toggle();
      return Services.Idle.inhibited ? "inhibited" : "released";
    }

    function status(): string {
      return Services.Idle.inhibited ? "inhibited" : "released";
    }
  }

  // `enter` and `exit` are what gamemode.ini's [custom] hooks call; `toggle`
  // is the manual switch.
  IpcHandler {
    target: "gamemode"

    function enter(): string {
      Services.GameMode.enter();
      return Services.GameMode.reason;
    }

    function exit(): string {
      Services.GameMode.exit();
      return Services.GameMode.reason;
    }

    function toggle(): string {
      Services.GameMode.toggle();
      return Services.GameMode.reason;
    }

    function status(): string {
      return Services.GameMode.reason;
    }
  }

  IpcHandler {
    target: "screenshot"

    /**
    * @param mode - region | window | output | screen
    */
    function capture(mode: string): string {
      Services.Screenshot.capture(mode, false, 0);
      return `capturing ${mode}`;
    }

    function copy(mode: string): string {
      Services.Screenshot.capture(mode, true, 0);
      return `capturing ${mode} to clipboard`;
    }
  }

  IpcHandler {
    target: "power"

    /**
    * @param action - lock | logout | suspend | reboot | poweroff
    */
    function run(action: string): string {
      return Services.Power.run(action) ? `running ${action}` : `unknown action "${action}"`;
    }
  }

  IpcHandler {
    target: "theme"

    function set(name: string): string {
      if (!Core.Themes.has(name))
        return `unknown theme "${name}"; known: ${Core.Themes.names.join(", ")}`;
      Config.Config.setTheme(name);
      return `theme: ${name}`;
    }

    function get(): string {
      return Config.Config.theme;
    }

    function list(): string {
      return Core.Themes.names.join(", ");
    }

    function scale(factor: real): string {
      Config.Config.setUiScale(factor);
      return `scale: ${Config.Config.uiScale}`;
    }
  }

  IpcHandler {
    target: "brightness"

    function set(percent: int): string {
      Services.Brightness.setPercent(percent);
      return `${Math.round(Services.Brightness.brightness * 100)}%`;
    }

    function up(): string {
      Services.Brightness.increase();
      return `${Math.round(Services.Brightness.brightness * 100)}%`;
    }

    function down(): string {
      Services.Brightness.decrease();
      return `${Math.round(Services.Brightness.brightness * 100)}%`;
    }
  }
}
