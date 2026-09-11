import QtQuick
import QtQuick.Effects

import "../core" as Core

/**
* RoundedImage - an image clipped to rounded corners
*
* `clip` on a rounded Rectangle clips to its bounding box, not to its corners,
* so album art drew square corners over its rounded frame. This masks the image
* to the radius instead.
*
* The mask is a layer, so it costs one offscreen texture the size of the image,
* re-rendered only when the image or its size changes. Fine for album art; not
* for anything whose contents animate.
*
* Usage:
*   RoundedImage {
*       source: Services.Media.trackArtUrl
*       radius: Core.Style.radiusM
*   }
*/
Item {
  id: root

  property alias source: image.source
  property alias sourceSize: image.sourceSize
  property alias fillMode: image.fillMode
  readonly property alias status: image.status
  property real radius: Core.Style.radiusM

  Image {
    id: image

    anchors.fill: parent
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    visible: false
  }

  Rectangle {
    id: mask

    anchors.fill: parent
    radius: root.radius
    visible: false
    layer.enabled: true
    layer.smooth: true
  }

  MultiEffect {
    anchors.fill: parent
    visible: image.status === Image.Ready
    source: image
    maskEnabled: true
    maskSource: mask
    // Antialiases the mask edge instead of cutting it at a hard threshold.
    maskThresholdMin: 0.5
    maskSpreadAtMin: 1.0
  }
}
