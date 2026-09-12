pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

import "../../components" as Components
import "../../core" as Core
import "../../services" as Services

/**
* MediaPanel - full transport for the active MPRIS player
*
* The now-playing card takes its colour from the album art: ColorQuantizer boils
* the cover down to a handful of colours, and the most vivid of them tints the
* card, the seek bar and the play button, cross-fading as tracks change. A cover
* with no usable colour (near-black, greyscale) falls back to the theme accent.
*/
Components.SlidingPanel {
  id: root

  panelId: "media"

  headerIcon: "music"
  headerIconColor: Services.Media.isPlaying ? root.tint : Core.Theme.textDim
  headerTitle: "Media"
  headerSubtitle: Services.Media.identity || "Nothing playing"

  // Position only refreshes while something is watching it.
  onOpened: Services.Media.positionWatched = true
  onClosed: Services.Media.positionWatched = false

  // === Album-art colour ===
  ColorQuantizer {
    id: artColors

    source: Services.Media.trackArtUrl
    depth: 3
    rescaleSize: 64
  }

  // The most vivid quantized colour, not the most common: that is often the
  // cover's near-black background, which would tint nothing.
  readonly property color artColor: {
    let best = Core.Theme.accent;
    let bestScore = 0;
    for (const c of artColors.colors) {
      const score = c.hsvSaturation * c.hsvValue;
      if (score > bestScore) {
        best = c;
        bestScore = score;
      }
    }
    return bestScore > 0.15 ? best : Core.Theme.accent;
  }

  property color tint: root.artColor

  Behavior on tint {
    ColorAnimation {
      duration: Core.Style.duration(Core.Style.animSlow)
      easing.type: Core.Style.easeStandard
    }
  }

  Components.EmptyState {
    Layout.fillWidth: true
    visible: !Services.Media.hasPlayer
    icon: "music"
    message: "Nothing playing"
    hint: "Start a player and it will appear here"
  }

  // === Now playing ===
  Rectangle {
    Layout.fillWidth: true
    visible: Services.Media.hasPlayer
    implicitHeight: heroColumn.implicitHeight + Core.Style.spaceM * 2

    radius: Core.Style.radiusL
    border.width: Core.Style.borderThin
    border.color: Core.Theme.alpha(root.tint, 0.3)

    gradient: Gradient {
      GradientStop {
        position: 0.0
        color: Core.Theme.alpha(root.tint, 0.3)
      }

      GradientStop {
        position: 1.0
        color: Core.Theme.alpha(root.tint, 0.05)
      }
    }

    ColumnLayout {
      id: heroColumn

      anchors {
        left: parent.left
        right: parent.right
        top: parent.top
        margins: Core.Style.spaceM
      }
      spacing: Core.Style.spaceM

      // --- Album art ---
      Item {
        Layout.fillWidth: true
        // Square, as covers are: the old 0.6 crop cut the top and bottom off.
        Layout.preferredHeight: width

        Rectangle {
          anchors.fill: parent
          radius: Core.Style.radiusM
          color: Core.Theme.surface
        }

        // Placeholder while there is no art (or it failed to load)
        Components.Icon {
          anchors.centerIn: parent
          opacity: art.opacity > 0 ? 0 : 1
          icon: "music"
          size: Core.Style.fontXXXL
          color: Core.Theme.overlay

          Behavior on opacity {
            NumberAnimation {
              duration: Core.Style.duration(Core.Style.animNormal)
              easing.type: Core.Style.easeStandard
            }
          }
        }

        Components.RoundedImage {
          id: art

          anchors.fill: parent
          radius: Core.Style.radiusM
          source: Services.Media.trackArtUrl
          // Album covers can be much larger than the panel; bound decoded size.
          sourceSize: Qt.size(root.panelWidth, root.panelWidth)

          // A new track's art fades in over the old frame instead of flashing
          // the placeholder between the two.
          opacity: status === Image.Ready ? 1 : 0

          Behavior on opacity {
            NumberAnimation {
              duration: Core.Style.duration(Core.Style.animNormal)
              easing.type: Core.Style.easeStandard
            }
          }
        }
      }

      // --- Track info ---
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Core.Style.spaceXXS

        Components.Text {
          Layout.fillWidth: true
          text: Services.Media.trackTitle || "Unknown track"
          size: Core.Style.fontL
          weight: Core.Style.weightBold
          elide: Text.ElideRight
        }

        Components.Text {
          Layout.fillWidth: true
          visible: Services.Media.trackArtist !== ""
          text: Services.Media.trackArtist
          size: Core.Style.fontM
          color: Core.Theme.textDim
          elide: Text.ElideRight
        }

        Components.Text {
          Layout.fillWidth: true
          visible: Services.Media.trackAlbum !== ""
          text: Services.Media.trackAlbum
          size: Core.Style.fontS
          color: Core.Theme.textMuted
          elide: Text.ElideRight
        }
      }

      // --- Seek bar ---
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Core.Style.spaceXXS
        visible: Services.Media.lengthSupported

        // Seeks once, on release. Seeking on every step of a drag sent a
        // SetPosition per pixel, and the position poll dragged the handle back
        // under the pointer between them.
        Components.Slider {
          id: seekBar

          Layout.fillWidth: true
          enabled: Services.Media.canSeek
          value: Services.Media.progress
          liveUpdate: false
          progressColor: root.tint
          handleDragColor: root.tint
          trackHeight: Core.Style.px(6)
          handleSize: Core.Style.px(12)
          onValueUpdated: v => Services.Media.seekFraction(v)
        }

        RowLayout {
          Layout.fillWidth: true

          // Follows the handle while dragging, so the time you will land on
          // shows before you let go.
          Components.Text {
            text: Core.Utils.formatClock(seekBar.displayValue * Services.Media.length)
            size: Core.Style.fontXS
            color: seekBar.dragging ? root.tint : Core.Theme.textMuted
          }

          Components.Spacer {}

          Components.Text {
            text: Core.Utils.formatClock(Services.Media.length)
            size: Core.Style.fontXS
            color: Core.Theme.textMuted
          }
        }
      }

      // --- Transport ---
      RowLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        spacing: Core.Style.spaceM

        Components.Button {
          icon: "shuffle"
          iconSize: Core.Style.fontM
          visible: Services.Media.shuffleSupported
          iconColor: Services.Media.active?.shuffle ? root.tint : Core.Theme.textDim
          tooltipText: "Shuffle"
          onClicked: Services.Media.toggleShuffle()
        }

        Components.Spacer {}

        Components.Button {
          icon: "skip-previous"
          iconSize: Core.Style.fontXL
          enabled: Services.Media.canGoPrevious
          tooltipText: "Previous"
          onClicked: Services.Media.previous()
        }

        Components.Button {
          variant: "primary"
          icon: Services.Media.statusIcon
          iconSize: Core.Style.fontXL
          padding: Core.Style.spaceM
          backgroundColor: root.tint
          hoverColor: Qt.lighter(root.tint, 1.15)
          tooltipText: Services.Media.isPlaying ? "Pause" : "Play"
          enabled: Services.Media.isPlaying ? Services.Media.canPause : Services.Media.canPlay
          onClicked: Services.Media.playPause()
        }

        Components.Button {
          icon: "skip-next"
          iconSize: Core.Style.fontXL
          enabled: Services.Media.canGoNext
          tooltipText: "Next"
          onClicked: Services.Media.next()
        }

        Components.Spacer {}

        Components.Button {
          icon: {
            if (!Services.Media.active)
              return "repeat";
            return Services.Media.active.loopState === MprisLoopState.Track ? "repeat-one" : "repeat";
          }
          iconSize: Core.Style.fontM
          visible: Services.Media.loopSupported
          iconColor: (Services.Media.active?.loopState ?? MprisLoopState.None) !== MprisLoopState.None ? root.tint : Core.Theme.textDim
          tooltipText: "Repeat"
          onClicked: Services.Media.cycleLoop()
        }
      }
    }
  }

  // === Player volume ===
  // A slider, not a read-out: this is the player's own PipeWire stream, so it
  // is the one volume control that works for a player that ignores MPRIS
  // Volume (see the note in services/Media.qml).
  RowLayout {
    Layout.fillWidth: true
    visible: Services.Media.hasPlayer && Services.Media.volumeSupported
    spacing: Core.Style.spaceS

    Components.Button {
      icon: Services.Media.volumeMuted ? "volume-mute" : "volume-high"
      iconSize: Core.Style.fontM
      iconColor: Services.Media.volumeMuted ? Core.Theme.error : Core.Theme.text
      tooltipText: Services.Media.volumeMuted ? "Unmute this player" : "Mute this player"
      enabled: Services.Media.stream !== null
      onClicked: Services.Media.toggleVolumeMute()
    }

    Components.Slider {
      Layout.fillWidth: true
      value: Services.Media.volume
      maxValue: 1.0
      progressColor: Services.Media.volumeMuted ? Core.Theme.error : root.tint
      onValueUpdated: newValue => Services.Media.setVolume(newValue)
    }
  }

  // === Player picker ===
  Components.Collapsible {
    Layout.fillWidth: true
    title: "Players"
    icon: "playlist"
    expanded: false
    visible: Services.Media.players.length > 1

    Repeater {
      model: Services.Media.players

      delegate: Components.Card {
        id: playerCard

        required property var modelData

        readonly property bool isActive: Services.Media.active?.uniqueId === modelData.uniqueId

        Layout.fillWidth: true
        implicitHeight: Core.Style.controlHeightM
        interactive: true

        backgroundColor: isActive ? Core.Theme.alpha(Core.Theme.accent, 0.15) : Core.Theme.transparent
        borderColor: isActive ? Core.Theme.accent : Core.Theme.transparent
        borderWidth: isActive ? 1 : 0

        onClicked: Services.Media.selectPlayer(playerCard.modelData.uniqueId)

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: Core.Style.spaceM
          anchors.rightMargin: Core.Style.spaceM
          spacing: Core.Style.spaceS

          Components.Icon {
            icon: playerCard.modelData.isPlaying ? "play" : "pause"
            size: Core.Style.fontM
            color: playerCard.isActive ? Core.Theme.accent : Core.Theme.textDim
          }

          Components.Text {
            Layout.fillWidth: true
            text: playerCard.modelData.identity || playerCard.modelData.dbusName
            color: playerCard.isActive ? Core.Theme.accent : Core.Theme.text
            elide: Text.ElideRight
          }

          Components.Icon {
            visible: playerCard.isActive
            icon: "check"
            size: Core.Style.fontM
            color: Core.Theme.accent
          }
        }
      }
    }
  }
}
