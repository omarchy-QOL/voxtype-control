pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons
import qs.Ui
import "../components" as Components
import "../logic/TranscriptHistory.js" as HistoryLogic

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
  property int actionIndex: 0
  property bool actionsFocused: false
  property string confirming: ""
  property int confirmChoice: 1
  readonly property int selectedIndex: HistoryLogic.indexForId(service.entries, selectedId)
  readonly property var selectedEntry: selectedIndex >= 0 ? service.entries[selectedIndex] : null
  readonly property var actionButtons: [copyButton, deleteButton, clearButton, backButton]
  implicitWidth: Style.space(440)
  implicitHeight: root.confirming ? confirmContent.implicitHeight
    : mainContent.implicitHeight
  blocked: search.activeFocus && confirming === ""

  signal backRequested

  function activate() {
    root.confirming = ""
    root.actionsFocused = false
    root.selectedId = ""
    root.service.refresh(search.text)
    Qt.callLater(root.focusSearch)
  }

  function focusSearch() {
    root.actionsFocused = false
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

  function copySelected() {
    if (root.selectedId && !root.service.busy) root.service.copy(root.selectedId)
  }

  function requestConfirmation(action) {
    if (action === "delete" && !root.selectedId) return
    root.confirming = action
    root.confirmChoice = 1
    root.forceActiveFocus()
  }

  function confirm() {
    if (root.confirmChoice === 1) { root.confirming = ""; root.focusSearch(); return }
    var action = root.confirming
    root.confirming = ""
    if (action === "delete") root.service.remove(root.selectedId)
    else if (action === "clear") root.service.clear()
  }

  function activateCurrent() {
    if (root.confirming) { root.confirm(); return }
    if (!root.actionsFocused) { root.copySelected(); return }
    var button = root.actionButtons[root.actionIndex]
    if (button.enabled) button.clicked()
  }

  onMoveRequested: function(dx, dy) {
    if (root.confirming) {
      root.confirmChoice = (root.confirmChoice + (dx || dy) + 2) % 2
    } else if (dy) {
      root.actionsFocused = false
      root.moveSelection(dy)
    } else {
      root.actionsFocused = true
      root.actionIndex = (root.actionIndex + dx + root.actionButtons.length)
        % root.actionButtons.length
    }
  }
  onActivateRequested: root.activateCurrent()
  onCloseRequested: {
    if (root.confirming) { root.confirming = ""; root.focusSearch() }
    else root.backRequested()
  }
  onDeleteRequested: if (!root.confirming) root.requestConfirmation("delete")
  onTabRequested: function(direction) {
    if (root.confirming) root.confirmChoice = (root.confirmChoice + direction + 2) % 2
    else {
      root.actionsFocused = true
      root.actionIndex = (root.actionIndex + direction + root.actionButtons.length)
        % root.actionButtons.length
    }
  }
  onTextKey: function(text) {
    if (root.confirming) return
    root.focusSearch()
    search.text += text
  }

  property Connections historyConnections: Connections {
    target: root.service
    function onEntriesChanged() { root.synchronizeSelection() }
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
    visible: root.confirming === ""
    width: parent.width
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
        if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
          root.moveSelection(event.key === Qt.Key_Down ? 1 : -1)
          event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          root.copySelected(); event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
          if (search.text) { search.clear(); root.service.refresh("") }
          else root.backRequested()
          event.accepted = true
        } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
          root.actionsFocused = true
          root.actionIndex = event.key === Qt.Key_Backtab ? root.actionButtons.length - 1 : 0
          root.forceActiveFocus()
          event.accepted = true
        }
      }
    }

    Components.NoticeSection {
      width: parent.width
      message: root.service.error || root.service.warning
      warning: !root.service.error
      warningColor: root.warningColor
      fontFamily: root.fontFamily
    }

    Text {
      visible: root.service.notice !== ""
      text: root.service.notice
      textFormat: Text.PlainText
      color: root.ready
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
          required property int index
          required property var modelData
          width: ListView.view.width
          height: Style.space(52)
          radius: Style.cornerRadius
          color: root.selectedId === modelData.id
            ? Style.controlFill(false, true, root.foreground, Color.accent) : "transparent"

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
              text: HistoryLogic.displayTime(transcriptRow.modelData.created_at)
              textFormat: Text.PlainText
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              elide: Text.ElideRight
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.selectedId = transcriptRow.modelData.id
            onClicked: root.selectedId = transcriptRow.modelData.id
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
            width: parent.width
            height: parent.height - parent.spacing - metadataText.height
            contentHeight: transcriptText.paintedHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            TextEdit {
              id: transcriptText
              width: parent.width
              text: root.selectedEntry ? root.selectedEntry.text : "Select a transcript"
              textFormat: TextEdit.PlainText
              readOnly: true
              selectByMouse: true
              wrapMode: TextEdit.Wrap
              color: root.selectedEntry ? root.foreground : root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
            }
          }
        }
      }
    }

    Row {
      width: parent.width
      spacing: Style.space(6)
      Button {
        id: copyButton
        width: (parent.width - 3 * parent.spacing) / 4
        text: "Copy"
        bordered: true
        enabled: !!root.selectedId && !root.service.busy
        hasCursor: root.actionsFocused && root.actionIndex === 0
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.copySelected()
      }
      Button {
        id: deleteButton
        width: copyButton.width
        text: "Delete"
        bordered: true
        enabled: !!root.selectedId && !root.service.busy
        hasCursor: root.actionsFocused && root.actionIndex === 1
        foreground: root.urgent
        fontFamily: root.fontFamily
        onClicked: root.requestConfirmation("delete")
      }
      Button {
        id: clearButton
        width: copyButton.width
        text: "Clear all"
        bordered: true
        enabled: root.service.entries.length > 0 && !root.service.busy
        hasCursor: root.actionsFocused && root.actionIndex === 2
        foreground: root.urgent
        fontFamily: root.fontFamily
        onClicked: root.requestConfirmation("clear")
      }
      Button {
        id: backButton
        width: copyButton.width
        text: "Back"
        bordered: true
        hasCursor: root.actionsFocused && root.actionIndex === 3
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.backRequested()
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: "Enter: copy  Tab: actions  Esc: back"
      textFormat: Text.PlainText
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
    }
  }

  Column {
    id: confirmContent
    visible: root.confirming !== ""
    width: parent.width
    spacing: Style.space(12)
    Text {
      width: parent.width
      text: root.confirming === "clear" ? "Delete all transcript history?"
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
        text: "Delete"
        bordered: true
        hasCursor: root.confirmChoice === 0
        foreground: root.urgent
        fontFamily: root.fontFamily
        onClicked: { root.confirmChoice = 0; root.confirm() }
      }
      Button {
        width: (parent.width - parent.spacing) / 2
        text: "Cancel"
        bordered: true
        hasCursor: root.confirmChoice === 1
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: { root.confirmChoice = 1; root.confirm() }
      }
    }
  }
}
