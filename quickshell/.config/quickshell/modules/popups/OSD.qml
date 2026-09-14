pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import "../../components" as Components
import "../../config" as Config
import "../../core" as Core
import "../../services" as Services

/**
* OSD - the transient volume/brightness overlay
*
* One Loader per screen, all listening to the same service. The loader stays
* inactive until something is shown and is torn down again once the hide
* animation finishes, so an idle session carries no OSD windows at all.
*
* It draws the payload the caller passed to Services.OSD.show(). Every field
* is read with a default, so a caller that omits one gets a sane value.
*/
Variants {
  id: root

  model: Quickshell.screens

  delegate: Loader {
    id: osdLoader

    required property var modelData
    property var screen: modelData

    active: false

    Connections {
      target: Services.OSD

      function onShowRequested() {
        if (!osdLoader.active)
          osdLoader.active = true;

        Qt.callLater(function () {
          if (osdLoader.item)
            osdLoader.item.show();
        });
      }
    }

    sourceComponent: Components.PositionedPanelWindow {
      id: osdWindow

      screen: osdLoader.screen
      namespace: "quickshell-osd"

      // Position configuration
      location: Config.Config.osdPosition
      margin: Core.Style.osdMargin
      topExtra: Core.Style.barHeight

      readonly property int shadowRoom: Math.max(Core.Style.spaceXS, Core.Style.elevationRoom(2))

      implicitWidth: Core.Style.osdWidth + (shadowRoom - Core.Style.spaceXS) * 2
      implicitHeight: Core.Style.osdHeight + (shadowRoom - Core.Style.spaceXS) * 2
      visible: content.visible

      function show() {
        hideTimer.stop();
        if (!content.visible) {
          content.visible = true;
          animator.show();
        } else {
          // A fresh update must cancel a fade-out before it unloads the window.
          // Do not replay the entry animation for every volume/brightness step.
          animator.setVisible();
        }
        hideTimer.restart();
      }

      Core.ShowHideAnimator {
        id: animator
        target: content
        slideFrom: "none"
        hiddenScale: Core.Style.popHiddenScale
        // A larger surface than a tooltip, so it settles rather than overshoots.
        showDuration: Core.Style.duration(Core.Style.animNormal)
        hideDuration: Core.Style.duration(Core.Style.animNormal)
        showEasing: Core.Style.easeStandard
        hideEasing: Core.Style.easeExit
        onHideFinished: {
          content.visible = false;
          osdLoader.active = false;
        }
      }

      Timer {
        id: hideTimer
        interval: Config.Config.osdDuration
        onTriggered: animator.hide()
      }

      Item {
        id: content
        anchors.fill: parent
        visible: false

        Components.Elevation {
          surface: osdBody
          level: 2
          radius: osdBody.radius
        }

        Rectangle {
          id: osdBody

          anchors.fill: parent
          anchors.margins: osdWindow.shadowRoom
          radius: Core.Style.radiusL
          color: Core.Theme.panelBg
          border.color: Core.Theme.surfaceHover
          border.width: Core.Style.borderThin

          Components.ProgressRow {
            anchors.fill: parent
            anchors.margins: Core.Style.spaceM
            icon: Services.OSD.payload.icon ?? ""
            iconColor: Services.OSD.payload.iconColor ?? Core.Theme.text
            value: Services.OSD.payload.value ?? 0
            maxValue: Services.OSD.payload.maxValue ?? 1
            progressColor: Services.OSD.payload.progressColor ?? Core.Theme.accent
            valueText: Services.OSD.payload.valueText ?? ""
          }
        }
      }
    }
  }
}
