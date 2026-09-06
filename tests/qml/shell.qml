import QtQuick
import Quickshell

ShellRoot {
  FloatingWindow {
    visible: true
    implicitWidth: 360
    implicitHeight: 160
    Loader { anchors.fill: parent; source: "tests/qml/tst_dropdown.qml" }
  }
}
