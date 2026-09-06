import QtQuick
import qs.Commons

Row {
  id: root
  property string model: ""
  property string stateLabel: ""
  property color stateColor: Color.foreground
  property string fontFamily: Style.font.family
  spacing: Style.space(24)

  Column {
    Text {
      text: root.model
      textFormat: Text.PlainText
      color: Color.tooltip.text
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
    }
    Text {
      text: root.stateLabel
      textFormat: Text.PlainText
      color: root.stateColor
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      font.bold: true
    }
  }

  Text {
    text: "L-click: Menu\nR-click:  TUI"
    textFormat: Text.PlainText
    horizontalAlignment: Text.AlignRight
    color: Color.tooltip.text
    font.family: root.fontFamily
    font.pixelSize: Style.font.body
  }
}
