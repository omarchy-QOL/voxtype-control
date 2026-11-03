import QtQuick

// What the shared panel shows and launches for Hex.
QtObject {
  readonly property string label: "Hex"
  readonly property string toolShortcut: "m"
  readonly property string toolSuffix: "odels"
  readonly property string toolHint: "R-click: Models"

  function toolCommand(controlPath) {
    return [controlPath, "configure"]
  }

  function settingsCommand(controlPath) {
    return [controlPath, "edit-config"]
  }
}
