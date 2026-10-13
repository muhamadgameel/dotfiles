pragma Singleton

import QtQuick
import Quickshell

import "../config" as Config
import "../core" as Core

/**
* Recorder - screen recording with gpu-screen-recorder
*
* The recorder runs in a systemd unit of its own, so a reload or a restart of
* the shell does not end a recording, and whether one is running is asked of
* systemd, not remembered here. Stopping the unit sends SIGINT, which is how the
* recorder is told to finish its file; the unit then says where the file is.
*
* The capture is taken below the compositor, so Hyprland's no_screen_share rule
* does not apply: a window it keeps out of screen sharing is recorded.
*/
Singleton {
  id: root

  readonly property string unit: "quickshell-recorder"
  readonly property string directoryExpr: '"$(xdg-user-dir PICTURES)/Recordings"'

  // In step with the unit: asked after every start and stop, and while it runs.
  property bool recording: false

  /**
  * Start a recording, or stop the one that is running.
  * @param mode - "screen" for the focused monitor, "region" to drag one
  */
  function toggle(mode) {
    if (_toggle.running)
      return;

    const lines = ["set -e", "exec </dev/null"];
    lines.push(`if systemctl --user is-active --quiet ${root.unit}; then exec systemctl --user stop ${root.unit}; fi`);

    if (mode === "region") {
      // Cancelling the selection is a normal outcome, not a failure.
      lines.push("geom=$(slurp -f '%wx%h+%x+%y') || exit 0");
      lines.push('[ -n "$geom" ] || exit 0');
      lines.push('set -- -w region -region "$geom"');
    } else {
      lines.push(`set -- -w "$(hyprctl -j activeworkspace | jq -r '.monitor')"`);
    }

    // Desktop audio always; the microphone only when the setting asks for it.
    const audio = Config.Config.recordMicrophone ? "default_output|default_input" : "default_output";
    lines.push(`mkdir -p ${root.directoryExpr}`);
    lines.push(`f=${root.directoryExpr}/"$(date +%Y-%m-%d_%H-%M-%S)".mp4`);
    lines.push(`systemd-run --user --quiet --collect --unit=${root.unit} -p KillSignal=SIGINT sh -c '${root._inUnit}' "$f" "$@" -a "${audio}" -o "$f"`);

    _toggle.command = ["sh", "-c", lines.join("\n")];
    _toggle.running = true;
  }

  function stop() {
    _stop.running = true;
  }

  // What runs in the unit; the file's path is its $0. The trap keeps this shell
  // alive through the SIGINT that stops the recorder, to send the notification.
  readonly property string _inUnit: 'trap : INT; if gpu-screen-recorder "$@"; then notify-send -a "Screen recorder" "Recording saved" "$0"; else notify-send -a "Screen recorder" -u critical "Recording failed" "journalctl --user -u quickshell-recorder says why"; fi'

  Component.onCompleted: _check.running = true

  Core.Command {
    id: _toggle
    tag: "Recorder"

    onDone: _check.running = true
  }

  Core.Command {
    id: _stop
    tag: "Recorder"

    command: ["systemctl", "--user", "stop", root.unit]
    onDone: _check.running = true
  }

  Core.Command {
    id: _check

    command: ["systemctl", "--user", "is-active", "--quiet", root.unit]
    onDone: code => root.recording = code === 0
  }

  // A recording can also end by itself.
  Timer {
    interval: 2000
    repeat: true
    running: root.recording
    onTriggered: _check.running = true
  }
}
