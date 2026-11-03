import QtQuick
import qs.Commons
import qs.Ui

Rectangle {
  id: root
  required property var history
  objectName: "transcriptHistoryConfirmOverlay"
  anchors.fill: parent
  visible: root.history.confirming !== ""
  z: 10
  color: Util.alpha(Color.background, 0.72)

  MouseArea {
    anchors.fill: parent
    // Keep the decision modal until it is answered from the card or keyboard.
    onClicked: {}
  }

  BorderSurface {
    id: confirmCard
    width: Math.min(parent.width - Style.space(32), Style.space(330))
    height: confirmContent.implicitHeight + Style.space(32)
    anchors.centerIn: parent
    color: Color.background
    borderSpec: Border.flat(Color.accent, Style.normalBorderWidth)
    radius: Style.cornerRadius

    MouseArea { anchors.fill: parent; onClicked: {} }

    Column {
      id: confirmContent
      anchors.fill: parent
      anchors.margins: Style.space(16)
      spacing: Style.space(12)

      Text {
        width: parent.width
        text: root.history.confirmingClose ? "Transcript copied. Close Voxtype Control?"
          : root.history.confirming === "clear" ? "Delete all transcript history?"
          : "Delete the selected transcript?"
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
        color: root.history.foreground
        font.family: root.history.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
      }

      Row {
        width: parent.width
        spacing: Style.space(8)
        Button {
          width: (parent.width - parent.spacing) / 2
          text: root.history.confirmingClose ? "Yes" : "Delete"
          bordered: true
          hasCursor: root.history.confirmChoice === 0
          foreground: root.history.confirmingClose ? root.history.foreground : root.history.urgent
          fontFamily: root.history.fontFamily
          onClicked: { root.history.confirmChoice = 0; root.history.confirm() }
        }
        Button {
          width: (parent.width - parent.spacing) / 2
          text: root.history.confirmingClose ? "No" : "Cancel"
          bordered: true
          hasCursor: root.history.confirmChoice === 1
          foreground: root.history.foreground
          fontFamily: root.history.fontFamily
          onClicked: { root.history.confirmChoice = 1; root.history.confirm() }
        }
      }
    }
  }
}
