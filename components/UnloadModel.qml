pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons
import qs.Ui

PanelKeyCatcher {
  id: root
  required property var service
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  property int choice: 1
  readonly property bool canUnload: service.loaded && !service.busy && !service.dictating
  readonly property string prompt: service.loaded ? "Unload " + service.modelLabel + "?"
    : "No model is currently loaded."
  implicitWidth: Math.max(Style.space(160), Math.ceil(question.implicitWidth))
  implicitHeight: content.implicitHeight
  signal cancelled()

  function focusButtons() { root.forceActiveFocus() }
  function activateChoice() {
    if (choice === 0) { if (canUnload) service.unload() }
    else root.cancelled()
  }

  onMoveRequested: function(dx, dy) { choice = (choice + (dx || dy) + 2) % 2 }
  onTabRequested: function(direction) { choice = (choice + direction + 2) % 2 }
  onActivateRequested: root.activateChoice()
  onCloseRequested: root.cancelled()
  onTextKey: function(text) { if (text.toLowerCase() === "q") root.cancelled() }

  Column {
    id: content
    width: parent.width
    spacing: Style.space(12)
    Text {
      id: question
      width: parent.width
      text: root.prompt
      textFormat: Text.PlainText
      elide: Text.ElideRight
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
        text: "Yes"
        foreground: root.foreground
        fontFamily: root.fontFamily
        enabled: root.canUnload
        bordered: true
        hasCursor: root.choice === 0
        onHovered: function(hovered) { if (hovered) root.choice = 0 }
        onClicked: root.service.unload()
      }
      Button {
        width: (parent.width - parent.spacing) / 2
        text: "No"
        foreground: root.foreground
        fontFamily: root.fontFamily
        bordered: true
        hasCursor: root.choice === 1
        onHovered: function(hovered) { if (hovered) root.choice = 1 }
        onClicked: root.cancelled()
      }
    }
  }

  Connections {
    target: root.service
    function onActionFinished(action, success) {
      if (action === "unload") root.cancelled()
    }
  }
  Component.onCompleted: Qt.callLater(root.focusButtons)
}
