import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  required property var service
  property color foreground: Color.foreground
  property color dim: Qt.darker(foreground, 1.55)
  property color ready: Color.accent
  property color urgent: Color.urgent
  property color warning: Color.urgent
  readonly property color stateColor:
    service && service.stateLabel === "Ready" ? ready : foreground
  readonly property color statusColor:
    service && service.dictationState === "recording" ? urgent
    : service && service.reloading ? warning
    : service && service.readyFlash ? ready
    : service && service.dictationState === "transcribing" ? warning
    : foreground
  property string statusIcon: "󰍬"
  property string fontFamily: Style.font.family
  implicitHeight: Math.max(titleBlock.implicitHeight, modelBox.implicitHeight)

  Row {
    id: titleBlock
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(14)

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.statusIcon
      color: root.statusColor
      font.family: root.fontFamily
      font.pixelSize: Style.font.display
    }

    Column {
      spacing: Style.space(2)
      Text {
        text: "Voxtype"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.title
        font.bold: true
      }
      Text {
        text: root.service ? root.service.stateLabel : "Unavailable"
        textFormat: Text.PlainText
        color: root.stateColor
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
      }
    }
  }

  BorderSurface {
    id: modelBox
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: Math.min(root.width * 0.65,
      Math.max(modelText.implicitWidth, hardwareText.implicitWidth) + Style.space(16))
    implicitHeight: statusColumn.implicitHeight + Style.space(10)
    color: "transparent"
    borderSpec: Border.controlSpec("normal", root.foreground, Color.accent)
    radius: Style.cornerRadius

    Column {
      id: statusColumn
      anchors.centerIn: parent
      width: parent.width - Style.space(16)
      spacing: Style.space(2)
      Text {
        id: modelText
        width: parent.width
        text: root.service ? root.service.modelLabel : "No model"
        textFormat: Text.PlainText
        elide: Text.ElideRight
        color: root.service && root.service.loaded ? root.foreground : root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
      }
      Text {
        id: hardwareText
        width: parent.width
        text: root.service ? root.service.hardwareLabel : "GPU unavailable"
        textFormat: Text.PlainText
        elide: Text.ElideRight
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
      }
    }
  }
}
