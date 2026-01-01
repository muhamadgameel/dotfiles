import QtQuick
import Quickshell

import "../../config" as Config
import "../../core" as Core
import "../../services" as Services

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

      implicitWidth: Core.Style.osdWidth
      implicitHeight: Core.Style.osdHeight
      visible: content.visible

      function show() {
        hideTimer.stop();
        if (!content.visible) {
          content.visible = true;
          animator.show();
        }
        hideTimer.restart();
      }

      Core.PopAnimator {
        id: animator
        target: content
        showDuration: Core.Style.animNormal
        hideDuration: Core.Style.animNormal
        showEasing: Easing.OutQuad
        hideEasing: Easing.InQuad
        showOvershoot: 1.0
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

        Rectangle {
          anchors.fill: parent
          anchors.margins: Core.Style.spaceXS
          radius: Core.Style.radiusL
          color: Config.Theme.alpha(Config.Theme.bg, 0.95)
          border.color: Config.Theme.surfaceHover
          border.width: 1

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
