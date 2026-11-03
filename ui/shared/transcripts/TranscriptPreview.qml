import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "../../../logic/TranscriptHistory.js" as HistoryLogic

BorderSurface {
  id: root
  required property var history
  property alias transcriptFlick: transcriptFlick
  color: "transparent"
  borderSpec: Border.controlSpec("normal", root.history.foreground, Color.accent)
  radius: Style.cornerRadius

  Column {
    anchors.fill: parent
    anchors.margins: Style.space(8)
    spacing: Style.space(5)
    Text {
      id: metadataText
      width: parent.width
      text: HistoryLogic.metadata(root.history.selectedEntry)
      textFormat: Text.PlainText
      color: root.history.dim
      font.family: root.history.fontFamily
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
    }
    Flickable {
      id: transcriptFlick
      objectName: "transcriptHistoryTextScroll"
      width: parent.width
      height: parent.height - parent.spacing - metadataText.height
      contentWidth: width
      contentHeight: transcriptText.paintedHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      flickableDirection: Flickable.VerticalFlick
      interactive: contentHeight > height
      ScrollBar.vertical: ScrollBar {
        id: transcriptScrollBar
        objectName: "transcriptHistoryScrollBar"
        policy: ScrollBar.AsNeeded
      }

      TextEdit {
        id: transcriptText
        width: parent.width - (transcriptScrollBar.visible
          ? transcriptScrollBar.width + Style.space(2) : 0)
        text: root.history.selectedEntry ? root.history.selectedEntry.text : "Select a transcript"
        textFormat: TextEdit.PlainText
        readOnly: true
        selectByMouse: true
        wrapMode: TextEdit.Wrap
        color: root.history.selectedEntry ? root.history.foreground : root.history.dim
        font.family: root.history.fontFamily
        font.pixelSize: Style.font.body

        PointHandler {
          id: selectionPointer
          acceptedButtons: Qt.LeftButton
          property string selectionAtPress: ""
          onActiveChanged: {
            if (active)
              selectionAtPress = transcriptText.selectedText
            else if (transcriptText.selectedText
                && transcriptText.selectedText !== selectionAtPress)
              root.history.copyTextSelection(transcriptText.selectedText)
          }
        }
      }
    }
  }
}
