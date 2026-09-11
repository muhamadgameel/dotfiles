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
* What is drawn comes from OSDLayouts, keyed by the layout name the caller
* passed to Services.OSD.show().
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

    sourceComponent: Core.PositionedPanelWindow {
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

      Core.PopAnimator {
        id: animator
        target: content
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
          color: Config.Theme.panelBg
          border.color: Config.Theme.surfaceHover
          border.width: Core.Style.borderThin

          // Dynamic layout based on OSD type
          Loader {
            anchors.fill: parent
            anchors.margins: Core.Style.spaceM
            sourceComponent: layouts.getComponent(Services.OSD.currentType)
          }
        }
      }

      // Layout component definitions
      OSDLayouts {
        id: layouts
      }
    }
  }
}
