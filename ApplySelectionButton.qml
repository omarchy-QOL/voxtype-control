import QtQuick
import qs.Commons
import qs.Ui

Button {
  id: root
  property string label: ""
  property color checkColor: Color.accent
  property bool spinning: false
  Accessible.name: label
  implicitHeight: Math.max(Style.spacing.controlHeight, contents.implicitHeight
    + verticalPadding * 2 + Border.top(borderSpec) + Border.bottom(borderSpec))

  Row {
    id: contents
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: root.leftPadding + Border.left(root.borderSpec)
    anchors.rightMargin: root.rightPadding + Border.right(root.borderSpec)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.spacing.controlGap

    Text {
      id: check
      anchors.verticalCenter: parent.verticalCenter
      text: root.spinning ? "󰑓" : "󰄬"
      color: root.enabled && !root.spinning ? root.checkColor : root.foreground
      font.family: root.fontFamily
      font.pixelSize: root.iconSize
      RotationAnimation on rotation {
        from: 0; to: 360; duration: 900; loops: Animation.Infinite
        running: root.spinning
        onStopped: check.rotation = 0
      }
    }
    Text {
      width: parent.width - check.width - parent.spacing
      anchors.verticalCenter: parent.verticalCenter
      text: root.label
      textFormat: Text.PlainText
      horizontalAlignment: Text.AlignLeft
      elide: Text.ElideRight
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: root.fontSize
    }
  }
}
