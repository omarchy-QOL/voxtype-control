pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons
import "../../../logic/TranscriptHistory.js" as HistoryLogic

ListView {
  id: transcriptList
  required property var history
  model: transcriptList.history.service.entries
  clip: true
  spacing: Style.space(3)
  boundsBehavior: Flickable.StopAtBounds

  delegate: Rectangle {
    id: transcriptRow
    objectName: "transcriptRow-" + modelData.id
    required property int index
    required property var modelData
    readonly property bool copying: transcriptList.history.copyingId === modelData.id
    readonly property bool copied: transcriptList.history.copiedId === modelData.id
    width: ListView.view.width
    height: Style.space(52)
    radius: Style.cornerRadius
    color: copied ? transcriptList.history.warningColor
      : transcriptList.history.selectedId === modelData.id
        ? Style.controlFill(false, true, transcriptList.history.foreground, Color.accent) : "transparent"

    Behavior on color { ColorAnimation { duration: 120 } }

    Column {
      anchors.fill: parent
      anchors.margins: Style.space(6)
      Text {
        width: parent.width
        text: transcriptRow.modelData.preview || "(empty)"
        textFormat: Text.PlainText
        color: transcriptList.history.foreground
        font.family: transcriptList.history.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }
      Text {
        width: parent.width
        text: transcriptRow.copied ? "Copied to clipboard"
          : transcriptRow.copying ? "Copying..."
          : HistoryLogic.displayTime(transcriptRow.modelData.created_at)
        textFormat: Text.PlainText
        color: transcriptRow.copying || transcriptRow.copied
          ? transcriptList.history.foreground : transcriptList.history.dim
        font.family: transcriptList.history.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: transcriptRow.copying || transcriptRow.copied
        elide: Text.ElideRight
      }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: transcriptList.history.selectedId = transcriptRow.modelData.id
      onClicked: transcriptList.history.copyTranscript(transcriptRow.modelData.id)
    }
  }

  Text {
    anchors.centerIn: parent
    visible: !transcriptList.history.service.busy && transcriptList.history.service.entries.length === 0
    text: transcriptList.history.searchText ? "No matches" : "No transcripts yet"
    color: transcriptList.history.dim
    font.family: transcriptList.history.fontFamily
    font.pixelSize: Style.font.body
  }
}
