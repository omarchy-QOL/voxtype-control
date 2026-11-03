pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons
import qs.Ui
import "../panel" as PanelUi
import "../../../logic/TranscriptHistory.js" as HistoryLogic

PanelKeyCatcher {
  id: root

  required property var service
  property color foreground: Color.foreground
  property color dim: Qt.darker(foreground, 1.55)
  property color urgent: Color.urgent
  property color ready: Color.accent
  property color warningColor: Color.urgent
  property string fontFamily: Style.font.family
  property string selectedId: ""
  property string copyingId: ""
  property string copiedId: ""
  property string confirming: ""
  property int confirmChoice: 1
  readonly property bool confirmingClose: confirming === "close"
  readonly property int selectedIndex: HistoryLogic.indexForId(service.entries, selectedId)
  readonly property string searchText: search.text
  readonly property var selectedEntry: selectedIndex >= 0 ? service.entries[selectedIndex] : null
  onSelectedIdChanged: transcriptPreview.transcriptFlick.contentY = 0
  implicitWidth: Style.space(440)
  implicitHeight: mainContent.implicitHeight
  blocked: search.activeFocus && confirming === ""

  signal backRequested
  signal panelCloseRequested

  function activate() {
    root.confirming = ""
    root.selectedId = ""
    root.service.refresh(search.text)
    Qt.callLater(root.focusSearch)
  }

  function restartSearch() {
    searchTimer.restart()
  }

  function focusSearch() {
    search.forceActiveFocus()
  }

  function synchronizeSelection() {
    root.selectedId = HistoryLogic.retainedId(root.service.entries, root.selectedId)
    if (root.selectedIndex >= 0) Qt.callLater(function() {
      transcriptList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
    })
  }

  function moveSelection(direction) {
    if (!root.service.entries.length) return
    var index = root.selectedIndex < 0 ? 0 : root.selectedIndex
    index = (index + direction + root.service.entries.length) % root.service.entries.length
    root.selectedId = root.service.entries[index].id
    Qt.callLater(function() { transcriptList.positionViewAtIndex(index, ListView.Contain) })
  }

  function copyTranscript(transcriptId) {
    if (!transcriptId || root.service.busy) return
    root.selectedId = transcriptId
    root.copyingId = transcriptId
    root.copiedId = ""
    root.service.copy(transcriptId)
  }

  function copySelected() {
    root.copyTranscript(root.selectedId)
  }

  function copyTextSelection(text) {
    if (text && !root.service.busy) root.service.copySelection(String(text))
  }

  function requestConfirmation(action) {
    if (action === "delete" && !root.selectedId) return
    root.confirming = action
    root.confirmChoice = action === "close" ? 0 : 1
    root.forceActiveFocus()
  }

  function confirm() {
    var action = root.confirming
    var accepted = root.confirmChoice === 0
    root.confirming = ""
    if (!accepted) { root.focusSearch(); return }
    if (action === "close") { root.panelCloseRequested(); return }
    if (action === "delete") root.service.remove(root.selectedId)
    else if (action === "clear") root.service.clear()
    Qt.callLater(root.focusSearch)
  }

  function activateCurrent() {
    if (root.confirming) { root.confirm(); return }
    root.copySelected()
  }

  onMoveRequested: function(dx, dy) {
    if (root.confirming)
      root.confirmChoice = (root.confirmChoice + (dx || dy) + 2) % 2
    else if (dy)
      root.moveSelection(dy)
  }
  onActivateRequested: root.activateCurrent()
  onCloseRequested: {
    if (root.confirming) { root.confirming = ""; root.focusSearch() }
    else root.backRequested()
  }
  onTabRequested: function(direction) {
    if (root.confirming) root.confirmChoice = (root.confirmChoice + direction + 2) % 2
    else root.focusSearch()
  }
  onTextKey: function(text) {
    if (root.confirming) return
    root.focusSearch()
    search.text += text
    searchTimer.restart()
  }

  property Connections historyConnections: Connections {
    target: root.service
    function onEntriesChanged() { root.synchronizeSelection() }
    function onCopied(transcriptId) {
      root.copyingId = ""
      root.copiedId = transcriptId
      copiedTimer.restart()
    }
    function onErrorChanged() {
      if (root.service.error) root.copyingId = ""
    }
  }

  Timer {
    id: copiedTimer
    interval: 250
    onTriggered: {
      root.copiedId = ""
      root.requestConfirmation("close")
    }
  }

  Timer {
    interval: 3000
    running: root.visible
    repeat: true
    onTriggered: if (!root.service.busy) root.service.refresh(search.text)
  }

  Timer {
    id: searchTimer
    interval: 180
    onTriggered: root.service.refresh(search.text)
  }

  Column {
    id: mainContent
    objectName: "transcriptHistoryContent"
    width: parent.width
    enabled: root.confirming === ""
    spacing: Style.space(8)

    Text {
      text: "Transcripts"
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.title
      font.bold: true
    }

    TranscriptSearchField {
      id: search
      history: root
    }

    PanelUi.NoticeSection {
      width: parent.width
      message: root.service.error || root.service.warning
      warning: !root.service.error
      warningColor: root.warningColor
      fontFamily: root.fontFamily
    }

    Text {
      visible: root.copyingId !== "" || root.service.notice !== ""
      text: root.copyingId ? "Copying transcript..." : root.service.notice
      textFormat: Text.PlainText
      color: root.copyingId ? root.warningColor : root.ready
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
    }

    Row {
      width: parent.width
      height: Style.space(250)
      spacing: Style.space(8)

      TranscriptList {
        id: transcriptList
        width: (parent.width - parent.spacing) * 0.43
        height: parent.height
        history: root
      }

      TranscriptPreview {
        id: transcriptPreview
        width: parent.width - transcriptList.width - parent.spacing
        height: parent.height
        history: root
      }
    }

    TranscriptHints {
      history: root
    }
  }

  TranscriptConfirmDialog {
    history: root
  }
}
