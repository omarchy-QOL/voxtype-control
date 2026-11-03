import QtQuick
import QtQuick.Controls
import qs.Ui

TextField {
  id: root
  required property var history
  objectName: "transcriptHistorySearch"
  width: parent.width
  placeholderText: "Search all transcript text..."
  foreground: root.history.foreground
  onTextEdited: root.history.restartSearch()
  Keys.priority: Keys.BeforeItem
  Keys.onPressed: function(event) {
    if ((event.modifiers & Qt.ControlModifier)
        && (event.modifiers & Qt.ShiftModifier) && event.key === Qt.Key_D) {
      root.history.requestConfirmation("clear"); event.accepted = true
    } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_D) {
      root.history.requestConfirmation("delete"); event.accepted = true
    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
      root.history.moveSelection(event.key === Qt.Key_Down ? 1 : -1)
      event.accepted = true
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      root.history.copySelected(); event.accepted = true
    } else if (event.key === Qt.Key_Escape) {
      if (root.text) { root.clear(); root.history.service.refresh("") }
      else root.history.backRequested()
      event.accepted = true
    } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
      root.history.forceActiveFocus()
      event.accepted = true
    }
  }
}
