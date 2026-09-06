import QtQuick
import qs.Ui

OpticalGlyph {
  id: root
  property bool pulsing: false

  SequentialAnimation {
    running: root.pulsing
    loops: Animation.Infinite
    onStopped: {
      root.opacity = 1
      root.scale = 1
    }
    ParallelAnimation {
      NumberAnimation {
        target: root
        property: "opacity"
        from: 0.65; to: 1
        duration: 650
        easing.type: Easing.InOutSine
      }
      SequentialAnimation {
        NumberAnimation {
          target: root
          property: "scale"
          from: 1; to: 1.16
          duration: 325
          easing.type: Easing.InOutSine
        }
        NumberAnimation {
          target: root
          property: "scale"
          from: 1.16; to: 1
          duration: 325
          easing.type: Easing.InOutSine
        }
      }
    }
  }
}
