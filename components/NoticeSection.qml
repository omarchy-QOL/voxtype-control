import QtQuick
import qs.Commons
import qs.Ui

Column {
  id: root
  property string message: ""
  property bool warning: false
  property color warningColor: Color.accent
  property string fontFamily: Style.font.family
  readonly property color noticeColor: warning ? warningColor : Color.urgent
  visible: message !== ""
  spacing: Style.space(5)

  Text {
    text: root.warning ? "Warning" : "Error"
    color: root.noticeColor
    font.family: root.fontFamily
    font.pixelSize: Style.font.body
    font.bold: true
  }
  Text {
    width: parent.width
    text: root.message
    textFormat: Text.PlainText
    wrapMode: Text.WordWrap
    color: root.noticeColor
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
  }
  PanelSeparator { foreground: Color.foreground }
}
