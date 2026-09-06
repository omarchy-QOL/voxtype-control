import QtQuick
import qs.Commons

Item {
  id: root
  property bool pulsing: false
  property string text: ""
  property string fontFamily: Style.font.family
  property real fontSize: Style.bar.iconFont
  property color color: Color.foreground
  property real progress: 0

  opacity: pulsing ? 0.75 + 0.25 * progress : 1
  scale: 1 + 0.08 * progress

  TextMetrics {
    id: metrics
    font: glyph.font
    text: root.text
  }

  Text {
    id: glyph
    // Keep the host's optical centering without scaling native glyph bitmaps.
    anchors.centerIn: parent
    anchors.alignWhenCentered: false
    anchors.horizontalCenterOffset: glyph.implicitWidth / 2
      - (metrics.tightBoundingRect.x + metrics.tightBoundingRect.width / 2)
    text: root.text
    color: root.color
    font.family: root.fontFamily
    font.pixelSize: Math.max(1, Math.round(root.fontSize))
    renderType: Text.CurveRendering
  }

  SequentialAnimation {
    running: root.pulsing
    loops: Animation.Infinite
    onStopped: root.progress = 0
    NumberAnimation {
      target: root
      property: "progress"
      from: 0; to: 1
      duration: 250
      easing.type: Easing.InOutSine
    }
    NumberAnimation {
      target: root
      property: "progress"
      from: 1; to: 0
      duration: 250
      easing.type: Easing.InOutSine
    }
  }
}
