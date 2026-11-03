import QtQuick
import qs.Commons
import qs.Ui

Button {
  id: root
  property color shortcutColor: Color.accent
  Accessible.name: "Copy last transcript"
  tooltipText: "Copy last transcript\nrecorded to clipboard"
  implicitWidth: shortcut.implicitWidth + caption.implicitWidth
    + leftPadding + rightPadding + _reservedBorderLeft + _reservedBorderRight
  implicitHeight: Math.max(Style.spacing.controlHeight, contents.implicitHeight
    + verticalPadding * 2 + _reservedBorderTop + _reservedBorderBottom)

  Row {
    id: contents
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: root.leftPadding + root._reservedBorderLeft
    anchors.rightMargin: root.rightPadding + root._reservedBorderRight
    anchors.verticalCenter: parent.verticalCenter

    Text {
      id: shortcut
      objectName: "copyLastTranscriptKey"
      text: "[C]"
      color: root.shortcutColor
      font.family: root.fontFamily
      font.pixelSize: root.fontSize
    }
    Text {
      id: caption
      width: parent.width - shortcut.width
      text: "opy last transcript"
      textFormat: Text.PlainText
      elide: Text.ElideRight
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: root.fontSize
    }
  }
}
