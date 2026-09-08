import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  readonly property string controlPath: Quickshell.env("HOME") + "/.local/bin/voxtype-control"
  property var entries: []
  property string query: ""
  property string error: ""
  property string warning: ""
  property string notice: ""
  readonly property bool busy: listProcess.running || actionProcess.running

  signal copied(string transcriptId)
  signal changed()

  function clean(raw) {
    return String(raw || "").trim().replace(/^(?:(?:Error|voxtype-control):\s*)+/i, "")
  }

  function refresh(filter) {
    root.query = String(filter || "")
    if (listProcess.running) return
    listProcess.requestedQuery = root.query
    listProcess.command = [root.controlPath, "history", "list", "--query",
      listProcess.requestedQuery, "--limit", "200"]
    listProcess.running = true
  }

  function updateList(raw) {
    var data = JSON.parse(String(raw))
    if (data.schema !== 1 || !Array.isArray(data.entries))
      throw new Error("Install the current Voxtype history helper")
    root.entries = data.entries
    root.warning = [data.capture_error || ""].concat(data.warnings || [])
      .filter(function(text) { return text }).join("\n")
    root.error = ""
  }

  function copy(transcriptId) { runAction("copy", transcriptId) }
  function remove(transcriptId) { runAction("delete", transcriptId) }
  function clear() { runAction("clear", "") }

  function runAction(action, transcriptId) {
    if (actionProcess.running || !action) return
    root.error = ""
    root.notice = ""
    actionProcess.action = action
    actionProcess.transcriptId = transcriptId
    actionProcess.command = [root.controlPath, "history", action]
      .concat(transcriptId ? [transcriptId] : [])
    actionProcess.running = true
  }

  property Timer noticeTimer: Timer {
    interval: 2500
    onTriggered: root.notice = ""
  }

  property Process listProcess: Process {
    property string requestedQuery: ""
    stdout: StdioCollector { id: listOutput; waitForEnd: true }
    stderr: StdioCollector { id: listErrors; waitForEnd: true }
    onExited: function(code) {
      if (requestedQuery !== root.query) {
        Qt.callLater(function() { root.refresh(root.query) })
        return
      }
      try {
        if (code !== 0) throw new Error(listErrors.text)
        root.updateList(listOutput.text)
      } catch (failure) {
        root.entries = []
        root.error = root.clean(failure) || "Transcript history is unavailable"
      }
    }
  }

  property Process actionProcess: Process {
    property string action: ""
    property string transcriptId: ""
    stdout: StdioCollector { waitForEnd: true }
    stderr: StdioCollector { id: actionErrors; waitForEnd: true }
    onExited: function(code) {
      if (code !== 0) {
        root.error = root.clean(actionErrors.text) || "Transcript action failed"
        return
      }
      if (action === "copy") {
        root.notice = "Transcript copied"
        root.noticeTimer.restart()
        root.copied(transcriptId)
      } else {
        root.notice = action === "delete" ? "Transcript deleted" : "History cleared"
        root.noticeTimer.restart()
        root.changed()
        root.refresh(root.query)
      }
    }
  }
}
