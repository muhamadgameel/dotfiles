import QtQuick
import QtQuick.Layouts

import "../../../components" as Components
import "../../../config" as Config
import "../../../core" as Core
import "../../../services" as Services

/**
* Media - now-playing indicator and transport
*
* - Left click:   open the media panel
* - Middle click: play/pause
* - Right click:  next track
* - Scroll:       volume, where the player supports it
*/
Item {
  id: root

  signal panelRequested

  // Cap the title so a long track name cannot push the rest of the bar around.
  readonly property int maxTextWidth: 220

  visible: Services.Media.hasPlayer
  implicitWidth: visible ? row.implicitWidth + Core.Style.spaceS * 2 : 0
  implicitHeight: Core.Style.widgetSize

  Rectangle {
    anchors.fill: parent
    radius: Core.Style.radiusS
    color: mouse.containsMouse ? Config.Theme.surfaceHover : Config.Theme.transparent

    Behavior on color {
      ColorAnimation {
        duration: Core.Style.duration(Core.Style.animFast)
      }
    }
  }

  RowLayout {
    id: row

    anchors.centerIn: parent
    spacing: Core.Style.spaceS

    Components.Icon {
      icon: Services.Media.statusIcon
      size: Core.Style.fontM
      color: Services.Media.isPlaying ? Config.Theme.accent : Config.Theme.textDim
    }

    Components.Text {
      Layout.maximumWidth: root.maxTextWidth
      text: Services.Media.summary
      size: Core.Style.fontS
      color: Services.Media.isPlaying ? Config.Theme.text : Config.Theme.textDim
      elide: Text.ElideRight
    }
  }

  MouseArea {
    id: mouse

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

    onEntered: {
      const m = Services.Media;
      const lines = [];

      if (m.trackTitle !== "")
        lines.push(m.trackTitle);
      if (m.trackArtist !== "")
        lines.push(m.trackArtist);
      if (m.trackAlbum !== "")
        lines.push(m.trackAlbum);
      if (m.identity !== "")
        lines.push(`— ${m.identity}`);

      lines.push("");
      lines.push("Left click: Open media panel");
      lines.push("Middle click: Play/pause");
      lines.push("Right click: Next track");
      if (Services.Media.volumeSupported)
        lines.push(`Scroll: Volume (${Math.round(Services.Media.volume * 100)}%)`);

      Services.Tooltip.show(root, lines.join("\n"), "bottom");
    }

    onExited: Services.Tooltip.hide()

    onClicked: mouseEvent => {
      if (mouseEvent.button === Qt.MiddleButton)
        Services.Media.playPause();
      else if (mouseEvent.button === Qt.RightButton)
        Services.Media.next();
      else
        root.panelRequested();
    }

    onWheel: wheelEvent => {
      if (!Services.Media.volumeSupported)
        return;
      const delta = wheelEvent.angleDelta.y > 0 ? 0.05 : -0.05;
      Services.Media.setVolume(Services.Media.volume + delta);
    }
  }

  Component.onDestruction: Services.Tooltip.forget(root)
}
