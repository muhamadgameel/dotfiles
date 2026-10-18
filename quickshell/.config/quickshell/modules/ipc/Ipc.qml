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
*   qs ipc call network backend native
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
    * Close it at once, with no slide. hypridle calls this before it locks.
    */
    function closeNow(): string {
      const was = Services.Panels.retainedPanel;
      Services.Panels.closeNow();
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
    target: "network"

    /**
    * Pick how the shell talks to NetworkManager.
    * @param name - "nmcli" or "native"
    */
    function backend(name: string): string {
      if (name !== "nmcli" && name !== "native")
        return `unknown backend "${name}"; known: nmcli, native`;
      Config.Config.setNetworkBackend(name);
      return `network backend: ${name}`;
    }

    function status(): string {
      const n = Services.Network;
      const signal = n.wifiConnected ? ` ${n.wifiSignal}%` : "";
      return `${n.backendName}: wifi ${n.wifiEnabled ? "on" : "off"}, ${n.connectionStatusText}${signal}, internet ${n.connectivityStatus}`;
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
    target: "wallpaper"

    /**
    * Set the wallpaper on every output and keep it across restarts.
    * @param path - an image file
    */
    function set(path: string): string {
      return Services.Wallpaper.set(path) ? `set ${path}` : `refused ${path}`;
    }

    /**
    * Unpin the wallpaper; the hourly changes start from the one on screen.
    */
    function shuffle(): string {
      Services.Wallpaper.shuffle();
      return "rotating";
    }

    function list(): string {
      return Services.Wallpaper.wallpapers.join("\n");
    }

    function status(): string {
      const w = Services.Wallpaper;
      return `${w.current || "unknown"}\n${w.shuffling ? "rotating" : "pinned"}, ${w.wallpapers.length} available in ${w.directory}`;
    }
  }

  IpcHandler {
    target: "recorder"

    /**
    * Start a recording, or stop the one that is running.
    * @param mode - screen or region
    */
    function toggle(mode: string): string {
      if (mode !== "screen" && mode !== "region")
        return `unknown mode "${mode}"; known: screen, region`;
      const was = Services.Recorder.recording;
      Services.Recorder.toggle(mode);
      return was ? "stopping" : `recording the ${mode}`;
    }

    function stop(): string {
      Services.Recorder.stop();
      return "stopping";
    }

    function status(): string {
      return Services.Recorder.recording ? "recording" : "idle";
    }
  }

  IpcHandler {
    target: "weather"

    /**
    * Set the city to show the weather for. Its name goes to open-meteo.com
    * once, to find its coordinates.
    */
    function city(name: string): string {
      Services.Weather.setCity(name);
      return `looking up ${name}`;
    }

    function status(): string {
      return Services.Weather.statusText;
    }
  }

  IpcHandler {
    target: "updates"

    /**
    * Ask pacman and the AUR again.
    */
    function check(): string {
      Services.Updates.check();
      return "checking";
    }

    function status(): string {
      const updates = Services.Updates;
      if (updates.checkedAt === 0)
        return updates.checking ? "checking" : "not checked yet";
      return `${updates.count} waiting, checked at ${Qt.formatTime(new Date(updates.checkedAt), "HH:mm")}${updates.checking ? ", checking again" : ""}`;
    }
  }

  IpcHandler {
    target: "nightlight"

    function toggle(): string {
      Services.NightLight.toggle();
      return Services.NightLight.statusText;
    }

    function set(enabled: bool): string {
      Services.NightLight.setEnabled(enabled);
      return Services.NightLight.statusText;
    }

    /**
    * @param kelvin - 2500 (warmest) to 6500 (daylight); clamped
    */
    function temperature(kelvin: int): string {
      Services.NightLight.setTemperature(kelvin);
      return Services.NightLight.statusText;
    }

    /**
    * Follow the schedule in the nightLightStart/nightLightEnd settings.
    */
    function schedule(enabled: bool): string {
      Services.NightLight.setSchedule(enabled);
      return Services.NightLight.statusText;
    }

    function status(): string {
      return Services.NightLight.statusText;
    }
  }

  IpcHandler {
    target: "screenshot"

    /**
    * @param mode - region | window | output | screen | text
    */
    function capture(mode: string): string {
      return Services.Screenshot.capture(mode, false, 0) || `capturing ${mode}`;
    }

    function copy(mode: string): string {
      return Services.Screenshot.capture(mode, true, 0) || `capturing ${mode} to clipboard`;
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
    target: "display"

    function status(): string {
      const d = Services.Display;
      return `${d.output}: ${d.currentRate} Hz (full ${d.fullRate}, battery rate ${Config.Config.batteryRefreshRate}), on ${d.onBattery ? "battery" : "mains"}, follow ${d.enabled}`;
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
      return `${Math.round(Services.Brightness.requestedBrightness * 100)}%`;
    }

    function up(): string {
      Services.Brightness.increase();
      return `${Math.round(Services.Brightness.requestedBrightness * 100)}%`;
    }

    function down(): string {
      Services.Brightness.decrease();
      return `${Math.round(Services.Brightness.requestedBrightness * 100)}%`;
    }
  }
}
