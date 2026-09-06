import QtQuick
import Quickshell.Io
import qs.Commons

QtObject {
  id: root
  property var palette: ({})
  readonly property color ready: palette.green || palette.color2 || Color.accent
  readonly property color warning: palette.yellow || palette.color3 || Color.urgent

  function load(raw) {
    var colors = {}
    String(raw).split("\n").forEach(function(line) {
      var match = line.match(/^\s*(green|yellow|color2|color3)\s*=\s*["'](#[0-9a-fA-F]{6})["']/)
      if (match) colors[match[1]] = match[2]
    })
    palette = colors
  }

  property FileView theme: FileView {
    path: Color.currentThemePath + "/colors.toml"
    watchChanges: true
    printErrors: false
    onLoaded: root.load(text())
    onFileChanged: reload()
    onLoadFailed: root.load("")
  }
}
