pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import "../../components" as Components
import "../../core" as Core
import "../../services" as Services

/**
* WallpaperPanel - choose the desktop wallpaper
*
* The cell size comes from the tokens the panel is built from rather than from
* the grid's measured width: a thumbnail whose sourceSize is read before layout
* has run decodes at full size, and these are 4K files.
*/
Components.SlidingPanel {
  id: root

  panelId: "wallpaper"
  panelWidth: Core.Style.panelWidthWide

  headerIcon: "image"
  headerIconColor: Core.Theme.accent
  headerTitle: "Wallpaper"
  headerSubtitle: Services.Wallpaper.shuffling ? "Cycling the folder" : Services.Wallpaper.name(Services.Wallpaper.current)

  onOpened: Services.Wallpaper.refresh()

  readonly property int columns: 3
  readonly property int _bodyWidth: root.panelWidth - Core.Style.spaceS * 2 - Core.Style.panelPadding * 2
  readonly property int _cellWidth: Math.floor((root._bodyWidth - Core.Style.spaceS * (root.columns - 1)) / root.columns)
  // Match the screen, so the thumbnail shows the crop fit_mode = cover will make.
  readonly property real _aspect: root.screen && root.screen.height > 0 ? root.screen.width / root.screen.height : 1.6
  readonly property int _cellHeight: Math.round(root._cellWidth / root._aspect)

  Components.EmptyState {
    Layout.fillWidth: true
    visible: Services.Wallpaper.wallpapers.length === 0
    icon: "image"
    message: "No wallpapers"
    hint: Services.Wallpaper.directory
  }

  Flow {
    Layout.fillWidth: true
    spacing: Core.Style.spaceS

    Repeater {
      model: Services.Wallpaper.wallpapers

      delegate: Components.Card {
        id: cell

        required property string modelData

        readonly property bool isCurrent: Services.Wallpaper.current === cell.modelData

        width: root._cellWidth
        height: root._cellHeight
        radius: Core.Style.radiusS
        interactive: true
        borderColor: cell.isCurrent ? Core.Theme.accent : Core.Theme.transparent
        borderWidth: cell.isCurrent ? Core.Style.borderThin * 2 : 0

        onClicked: Services.Wallpaper.set(cell.modelData)

        Components.RoundedImage {
          anchors.fill: parent
          radius: Core.Style.radiusS
          source: Services.Wallpaper.url(cell.modelData)
          sourceSize: Qt.size(root._cellWidth, root._cellHeight)
        }

        Components.Icon {
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.margins: Core.Style.spaceXS
          visible: cell.isCurrent
          icon: "check"
          size: Core.Style.fontM
          color: Core.Theme.accent
        }
      }
    }
  }

  // Only while a choice is standing: hyprpaper stops cycling the folder the
  // moment one is set, and only a restart puts it back.
  Components.Button {
    Layout.fillWidth: true
    visible: !Services.Wallpaper.shuffling
    variant: "secondary"
    icon: "refresh"
    text: "Resume cycling"
    tooltipText: "Restart hyprpaper so it cycles the folder again"
    onClicked: Services.Wallpaper.shuffle()
  }
}
