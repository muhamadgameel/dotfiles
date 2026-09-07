pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core
import "../../services" as Services

/**
* MediaPanel - full transport for the active MPRIS player
*/
Components.SlidingPanel {
  id: root

  panelId: "media"
  namespace: "quickshell-media-panel"

  headerIcon: "music"
  headerIconColor: Services.Media.isPlaying ? Config.Theme.accent : Config.Theme.textDim
  headerTitle: "Media"
  headerSubtitle: Services.Media.identity || "Nothing playing"

  // Position only refreshes while something is watching it.
  onOpened: Services.Media.positionWatched = true
  onClosed: Services.Media.positionWatched = false

  Components.EmptyState {
    Layout.fillWidth: true
    visible: !Services.Media.hasPlayer
    icon: "music"
    message: "Nothing playing"
    hint: "Start a player and it will appear here"
  }

  // === Album art ===
  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: width * 0.6
    visible: Services.Media.hasPlayer

    Rectangle {
      anchors.fill: parent
      radius: Core.Style.radiusL
      color: Config.Theme.surface
      clip: true

      Image {
        id: art

        anchors.fill: parent
        source: Services.Media.trackArtUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: status === Image.Ready
      }

      // Placeholder while there is no art (or it failed to load)
      Components.Icon {
        anchors.centerIn: parent
        visible: !art.visible
        icon: "music"
        size: Core.Style.fontXXXL
        color: Config.Theme.overlay
      }
    }
  }

  // === Track info ===
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Core.Style.spaceXXS
    visible: Services.Media.hasPlayer

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
      color: Config.Theme.textDim
      elide: Text.ElideRight
    }

    Components.Text {
      Layout.fillWidth: true
      visible: Services.Media.trackAlbum !== ""
      text: Services.Media.trackAlbum
      size: Core.Style.fontS
      color: Config.Theme.textMuted
      elide: Text.ElideRight
    }
  }

  // === Seek bar ===
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Core.Style.spaceXXS
    visible: Services.Media.hasPlayer && Services.Media.lengthSupported

    Components.Slider {
      Layout.fillWidth: true
      enabled: Services.Media.canSeek
      value: Services.Media.progress
      trackHeight: 6
      handleSize: 12
      onValueUpdated: v => Services.Media.seekFraction(v)
    }

    RowLayout {
      Layout.fillWidth: true

      Components.Text {
        text: Core.Utils.formatClock(Services.Media.position)
        size: Core.Style.fontXS
        color: Config.Theme.textMuted
      }

      Components.Spacer {}

      Components.Text {
        text: Core.Utils.formatClock(Services.Media.length)
        size: Core.Style.fontXS
        color: Config.Theme.textMuted
      }
    }
  }

  // === Transport ===
  RowLayout {
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignHCenter
    spacing: Core.Style.spaceM
    visible: Services.Media.hasPlayer

    Components.Button {
      icon: "shuffle"
      iconSize: Core.Style.fontM
      visible: Services.Media.shuffleSupported
      iconColor: Services.Media.active?.shuffle ? Config.Theme.accent : Config.Theme.textDim
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
      tooltipText: Services.Media.isPlaying ? "Pause" : "Play"
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
      iconColor: (Services.Media.active?.loopState ?? MprisLoopState.None) !== MprisLoopState.None ? Config.Theme.accent : Config.Theme.textDim
      tooltipText: "Repeat"
      onClicked: Services.Media.cycleLoop()
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
      iconColor: Services.Media.volumeMuted ? Config.Theme.error : Config.Theme.text
      tooltipText: Services.Media.volumeMuted ? "Unmute this player" : "Mute this player"
      enabled: Services.Media.stream !== null
      onClicked: Services.Media.toggleVolumeMute()
    }

    Components.Slider {
      Layout.fillWidth: true
      value: Services.Media.volume
      maxValue: 1.0
      progressColor: Services.Media.volumeMuted ? Config.Theme.error : Config.Theme.accent
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
        implicitHeight: 44
        interactive: true

        backgroundColor: isActive ? Config.Theme.alpha(Config.Theme.accent, 0.15) : Config.Theme.transparent
        borderColor: isActive ? Config.Theme.accent : Config.Theme.transparent
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
            color: playerCard.isActive ? Config.Theme.accent : Config.Theme.textDim
          }

          Components.Text {
            Layout.fillWidth: true
            text: playerCard.modelData.identity || playerCard.modelData.dbusName
            color: playerCard.isActive ? Config.Theme.accent : Config.Theme.text
            elide: Text.ElideRight
          }

          Components.Icon {
            visible: playerCard.isActive
            icon: "check"
            size: Core.Style.fontM
            color: Config.Theme.accent
          }
        }
      }
    }
  }
}
