import QtQuick

// What the shared panel shows and launches for Hex.
QtObject {
  readonly property string toolShortcut: "m"
  readonly property string toolSuffix: "odel picker"
  readonly property string toolHint: "R-click: Models"

  function toolCommand(controlPath) {
    return [controlPath, "configure"]
  }
}
