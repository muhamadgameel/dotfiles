pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core
import "../../services" as Services

/**
* ScreenshotPanel - capture chooser, for pictures and recordings
*
* The panel closes before the capture runs, so it never ends up in the shot.
*/
Components.SlidingPanel {
  id: root

  panelId: "screenshot"

  headerIcon: "camera"
  headerIconColor: Core.Theme.accent
  headerTitle: "Screenshot"
  headerSubtitle: Services.Recorder.recording ? "Recording…" : Services.Screenshot.capturing ? "Capturing…" : "~/Pictures/Screenshots"

  // The last capture may have been moved or deleted since it was taken, so its
  // buttons are re-validated each time the panel comes up.
  onOpened: Services.Screenshot.verifyLastPath()

  property bool toClipboard: false
  property int delaySeconds: 0

  readonly property var modes: [
    {
      id: "region",
      label: "Select region",
      icon: "crop",
      hint: "Drag to choose an area"
    },
    {
      id: "window",
      label: "Pick a window",
      icon: "window",
      hint: "Click the window you want"
    },
    {
      id: "output",
      label: "This display",
      icon: "monitor",
      hint: "The whole current monitor"
    },
    {
      id: "screen",
      label: "Everything",
      icon: "layers",
      hint: "All displays"
    }
  ]

  function capture(mode) {
    // Close first: a visible panel would be captured along with everything else.
    // The service does the waiting - it holds the request until this window is
    // actually gone, rather than firing a frame later while it is still sliding
    // out. See services/Screenshot.qml.
    root.close();
    Services.Screenshot.capture(mode, root.toClipboard, root.delaySeconds);
  }

  // One row while a recording runs, to stop it.
  readonly property var recordings: Services.Recorder.recording ? [
    {
      id: "stop",
      label: "Stop recording",
      icon: "close",
      hint: "Finish the file in ~/Pictures/Recordings"
    }
  ] : [
    {
      id: "region",
      label: "Record a region",
      icon: "video",
      hint: "Drag to choose an area"
    },
    {
      id: "screen",
      label: "Record this display",
      icon: "video",
      hint: "The whole current monitor"
    }
  ]

  function record(mode) {
    // At once, with no slide: the recorder starts within a few frames.
    Services.Panels.closeNow();
    if (mode === "stop")
      Services.Recorder.stop();
    else
      Services.Recorder.toggle(mode);
  }

  component ModeRow: Components.ListRow {
    required property var modelData

    interactive: true
    hoverColor: Core.Theme.surfaceHover

    icon: modelData.icon
    iconColor: Core.Theme.accent
    title: modelData.label
    subtitle: modelData.hint
    trailingIcon: hovered ? "chevron-right" : ""
    trailingColor: Core.Theme.textDim
  }

  // === Options ===
  Components.FormRow {
    label: "Copy to clipboard"
    hasToggle: true
    toggleChecked: root.toClipboard
    onToggled: checked => root.toClipboard = checked
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Core.Style.spaceS

    Components.Text {
      Layout.fillWidth: true
      text: "Delay"
    }

    Repeater {
      model: [0, 3, 5, 10]

      delegate: Components.Button {
        required property int modelData

        variant: root.delaySeconds === modelData ? "primary" : "secondary"
        text: modelData === 0 ? "None" : `${modelData}s`
        textSize: Core.Style.fontS
        onClicked: root.delaySeconds = modelData
      }
    }
  }

  Components.Divider {}

  // === Modes ===
  Repeater {
    model: root.modes

    delegate: ModeRow {
      id: modeCard

      onClicked: root.capture(modeCard.modelData.id)
    }
  }

  // === Recording ===
  Components.Divider {}

  Components.FormRow {
    label: "Record the microphone too"
    hasToggle: true
    toggleChecked: Config.Config.recordMicrophone
    onToggled: checked => Config.Config.setFlag("recordMicrophone", checked)
  }

  Repeater {
    model: root.recordings

    delegate: ModeRow {
      id: recordCard

      iconColor: Core.Theme.error
      onClicked: root.record(recordCard.modelData.id)
    }
  }

  // === Last capture ===
  Components.Divider {
    visible: Services.Screenshot.lastPath !== ""
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Core.Style.spaceS
    visible: Services.Screenshot.lastPath !== ""

    Components.Text {
      Layout.fillWidth: true
      text: "Last capture"
      size: Core.Style.fontS
      color: Core.Theme.textDim
      weight: Core.Style.weightBold
    }

    Components.Text {
      Layout.fillWidth: true
      text: Services.Screenshot.lastPath
      size: Core.Style.fontXS
      color: Core.Theme.textMuted
      elide: Text.ElideLeft
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Core.Style.spaceS

      Components.Button {
        variant: "secondary"
        icon: "external-link"
        text: "Open"
        textSize: Core.Style.fontS
        tooltipText: "Open in the default image viewer"
        onClicked: {
          Services.Screenshot.openLast();
          root.close();
        }
      }

      Components.Button {
        variant: "secondary"
        icon: "edit"
        text: "Edit"
        textSize: Core.Style.fontS
        tooltipText: "Draw on it in swappy"
        onClicked: {
          Services.Screenshot.editLast();
          root.close();
        }
      }

      Components.Button {
        variant: "secondary"
        icon: "copy"
        text: "Copy image"
        textSize: Core.Style.fontS
        tooltipText: "Put the picture on the clipboard"
        onClicked: {
          Services.Screenshot.copyLast();
          root.close();
        }
      }
    }
  }
}
