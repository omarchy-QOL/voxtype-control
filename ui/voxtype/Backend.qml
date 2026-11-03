import QtQuick

// What the shared panel shows and launches for Voxtype.
QtObject {
  readonly property string label: "Voxtype"
  readonly property string toolShortcut: "v"
  readonly property string toolSuffix: "oxtype tui"
  readonly property string toolHint: "R-click:  TUI"

  function toolCommand(controlPath) {
    return ["omarchy-launch-terminal", "-e", controlPath, "configure"]
  }

  function settingsCommand(controlPath) {
    return [controlPath, "edit-config"]
  }
}
