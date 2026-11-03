import QtQuick
import qs.Commons

Column {
  id: root
  required property var history
  objectName: "transcriptHistoryFooter"
  width: parent.width
  spacing: Style.space(2)

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    text: "[" + String.fromCharCode(0x2190) + "/"
      + String.fromCharCode(0x2192) + "] move  [Enter] copy  [Esc] back"
    textFormat: Text.PlainText
    color: root.history.dim
    font.family: root.history.fontFamily
    font.pixelSize: Style.font.caption
    font.bold: true
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    text: "[Ctrl+D] delete  [Ctrl+Shift+D] delete all"
    textFormat: Text.PlainText
    color: root.history.dim
    font.family: root.history.fontFamily
    font.pixelSize: Style.font.caption
    font.bold: true
  }
}
