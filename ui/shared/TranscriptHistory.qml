pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "../../logic/TranscriptHistory.js" as HistoryLogic

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
  readonly property var selectedEntry: selectedIndex >= 0 ? service.entries[selectedIndex] : null
  onSelectedIdChanged: transcriptFlick.contentY = 0
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

    TextField {
      id: search
      objectName: "transcriptHistorySearch"
      width: parent.width
      placeholderText: "Search all transcript text..."
      foreground: root.foreground
      onTextEdited: searchTimer.restart()
      Keys.priority: Keys.BeforeItem
      Keys.onPressed: function(event) {
        if ((event.modifiers & Qt.ControlModifier)
            && (event.modifiers & Qt.ShiftModifier) && event.key === Qt.Key_D) {
          root.requestConfirmation("clear"); event.accepted = true
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_D) {
          root.requestConfirmation("delete"); event.accepted = true
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
          root.moveSelection(event.key === Qt.Key_Down ? 1 : -1)
          event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          root.copySelected(); event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
          if (search.text) { search.clear(); root.service.refresh("") }
          else root.backRequested()
          event.accepted = true
        } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
          root.forceActiveFocus()
          event.accepted = true
        }
      }
    }

    NoticeSection {
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

      ListView {
        id: transcriptList
        width: (parent.width - parent.spacing) * 0.43
        height: parent.height
        model: root.service.entries
        clip: true
        spacing: Style.space(3)
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
          id: transcriptRow
          objectName: "transcriptRow-" + modelData.id
          required property int index
          required property var modelData
          readonly property bool copying: root.copyingId === modelData.id
          readonly property bool copied: root.copiedId === modelData.id
          width: ListView.view.width
          height: Style.space(52)
          radius: Style.cornerRadius
          color: copied ? root.warningColor
            : root.selectedId === modelData.id
              ? Style.controlFill(false, true, root.foreground, Color.accent) : "transparent"

          Behavior on color { ColorAnimation { duration: 120 } }

          Column {
            anchors.fill: parent
            anchors.margins: Style.space(6)
            Text {
              width: parent.width
              text: transcriptRow.modelData.preview || "(empty)"
              textFormat: Text.PlainText
              color: root.foreground
              font.family: root.fontFamily
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
                ? root.foreground : root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: transcriptRow.copying || transcriptRow.copied
              elide: Text.ElideRight
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.selectedId = transcriptRow.modelData.id
            onClicked: root.copyTranscript(transcriptRow.modelData.id)
          }
        }

        Text {
          anchors.centerIn: parent
          visible: !root.service.busy && root.service.entries.length === 0
          text: search.text ? "No matches" : "No transcripts yet"
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
        }
      }

      BorderSurface {
        width: parent.width - transcriptList.width - parent.spacing
        height: parent.height
        color: "transparent"
        borderSpec: Border.controlSpec("normal", root.foreground, Color.accent)
        radius: Style.cornerRadius

        Column {
          anchors.fill: parent
          anchors.margins: Style.space(8)
          spacing: Style.space(5)
          Text {
            id: metadataText
            width: parent.width
            text: HistoryLogic.metadata(root.selectedEntry)
            textFormat: Text.PlainText
            color: root.dim
            font.family: root.fontFamily
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
              text: root.selectedEntry ? root.selectedEntry.text : "Select a transcript"
              textFormat: TextEdit.PlainText
              readOnly: true
              selectByMouse: true
              wrapMode: TextEdit.Wrap
              color: root.selectedEntry ? root.foreground : root.dim
              font.family: root.fontFamily
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
                    root.copyTextSelection(transcriptText.selectedText)
                }
              }
            }
          }
        }
      }
    }

    Column {
      objectName: "transcriptHistoryFooter"
      width: parent.width
      spacing: Style.space(2)

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "[" + String.fromCharCode(0x2190) + "/"
          + String.fromCharCode(0x2192) + "] move  [Enter] copy  [Esc] back"
        textFormat: Text.PlainText
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "[Ctrl+D] delete  [Ctrl+Shift+D] delete all"
        textFormat: Text.PlainText
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
      }
    }
  }

  Rectangle {
    id: confirmOverlay
    objectName: "transcriptHistoryConfirmOverlay"
    anchors.fill: parent
    visible: root.confirming !== ""
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
          text: root.confirmingClose ? "Transcript copied. Close Voxtype Control?"
            : root.confirming === "clear" ? "Delete all transcript history?"
            : "Delete the selected transcript?"
          textFormat: Text.PlainText
          wrapMode: Text.WordWrap
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          font.bold: true
        }

        Row {
          width: parent.width
          spacing: Style.space(8)
          Button {
            width: (parent.width - parent.spacing) / 2
            text: root.confirmingClose ? "Yes" : "Delete"
            bordered: true
            hasCursor: root.confirmChoice === 0
            foreground: root.confirmingClose ? root.foreground : root.urgent
            fontFamily: root.fontFamily
            onClicked: { root.confirmChoice = 0; root.confirm() }
          }
          Button {
            width: (parent.width - parent.spacing) / 2
            text: root.confirmingClose ? "No" : "Cancel"
            bordered: true
            hasCursor: root.confirmChoice === 1
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: { root.confirmChoice = 1; root.confirm() }
          }
        }
      }
    }
  }
}
