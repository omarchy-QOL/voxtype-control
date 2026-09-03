import QtQuick
import qs.Ui as Ui

Ui.SearchableDropdown {
  id: root

  property double lastClosedAt: 0
  property int reopenGuardMs: 150

  onPopupOpenChanged: if (!popupOpen) lastClosedAt = Date.now()

  MouseArea {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: root.rowHeight
    z: 10
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onEntered: root.hasCursor = true
    onExited: root.hasCursor = false
    onPressed: function(mouse) {
      if (root.popupOpen) root.close()
      mouse.accepted = true
    }
    onClicked: function(mouse) {
      if (root.popupOpen) root.close()
      else if (Date.now() - root.lastClosedAt > root.reopenGuardMs)
        root.open()
      mouse.accepted = true
    }
  }
}
