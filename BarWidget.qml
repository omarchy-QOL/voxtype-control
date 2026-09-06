pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "io.github.ilyazar.voxtype-control"
  ipcTarget: root.QsWindow.window && root.QsWindow.window.screen
    ? moduleName + ".editor." + root.QsWindow.window.screen.name : ""

  property string draftModelId: ""
  property string draftLanguage: ""
  property bool draftTouched: false
  property int actionIndex: 0
  property bool unloadingModel: false
  property bool editingReplacements: false
  readonly property var controlRows: [[backendDropdown, unloadButton], [languageDropdown],
    [applyButton], [configureButton, configFileButton, replacementsButton]]
  readonly property var actions: [].concat.apply([], controlRows)

  readonly property var voxtype: bar && bar.shell
    ? bar.shell.serviceFor(moduleName) : null
  readonly property color foreground: bar ? bar.barForeground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color ready: stateColors.ready
  readonly property color warning: stateColors.warning
  readonly property color statusColor:
    voxtype && voxtype.dictationState === "recording" ? urgent
    : voxtype && voxtype.reloading ? warning
    : voxtype && voxtype.readyFlash ? ready
    : voxtype && voxtype.dictationState === "transcribing" ? warning
    : voxtype && voxtype.available ? foreground : dim
  readonly property string statusIcon:
    voxtype && !voxtype.reloading && voxtype.dictationState === "transcribing" ? "󰔟" : "󰍬"
  readonly property color stateColor:
    voxtype && voxtype.stateLabel === "Ready" ? ready
    : voxtype && voxtype.stateLabel === "Listening" ? urgent
    : warning
  readonly property var languageOptions: voxtype
    ? voxtype.languageOptionsFor(draftModelId) : []
  readonly property var selectedModel: voxtype ? voxtype.modelFor(draftModelId) : null
  readonly property bool canApply: voxtype && voxtype.controlAvailable && !voxtype.busy
    && !voxtype.dictating
    && selectedModel && !selectedModel.reason && selectedModel.codes.indexOf(draftLanguage) !== -1
    && (!voxtype.loaded || !voxtype.endpointReady || voxtype.errorOperation === "apply"
      || draftModelId !== voxtype.modelId || draftLanguage !== voxtype.language)

  function applyDraft() {
    if (!canApply) return
    voxtype.applySelection(draftModelId, draftLanguage)
  }

  function syncDrafts() {
    if (!voxtype || draftTouched) return
    draftModelId = voxtype.modelId
    draftLanguage = voxtype.language
    if (!draftLanguage) draftLanguage = voxtype.defaultLanguageFor(draftModelId)
  }

  function launchConfiguration() {
    close()
    if (voxtype)
      Quickshell.execDetached(["omarchy-launch-terminal", "-e", voxtype.controlPath, "configure"])
  }

  function launchConfigFile() {
    close()
    if (voxtype)
      Quickshell.execDetached([voxtype.controlPath, "edit-config"])
  }

  function launchReplacements() {
    if (!voxtype || editingReplacements || editorLauncher.running) return
    editingReplacements = true
    editorLauncher.command = ["omarchy-launch-terminal", "-e", voxtype.controlPath,
      "edit-replacements", ipcTarget]
    editorLauncher.running = true
  }

  function open() {
    editingReplacements = false
    controller.show()
    Qt.callLater(root.focusControls)
  }

  Process {
    id: editorLauncher
    stderr: StdioCollector { id: editorErrors; waitForEnd: true }
    onExited: function(code) {
      if (code === 0) {
        if (root.voxtype) root.voxtype.resolveFailure("editor")
        return
      }
      if (root.voxtype) root.voxtype.reportFailure(editorErrors.text || "Could not open replacements editor", "editor")
      root.open()
    }
  }

  function moveControl(direction) {
    backendDropdown.close()
    languageDropdown.close()
    actionIndex = (actionIndex + direction + actions.length) % actions.length
    focusControls()
  }

  function moveCursor(dx, dy) {
    for (var row = 0; row < controlRows.length; row++) {
      var column = controlRows[row].indexOf(actions[actionIndex])
      if (column === -1) continue
      if (dy) {
        row = (row + dy + controlRows.length) % controlRows.length
        column = Math.min(column, controlRows[row].length - 1)
      } else column = (column + dx + controlRows[row].length) % controlRows[row].length
      actionIndex = actions.indexOf(controlRows[row][column])
      focusControls()
      return
    }
  }

  function activateShortcut(text) {
    if (text.toLowerCase() === "q") { root.close(); return }
    var action = ({v: configureButton, s: configFileButton, r: replacementsButton})[text.toLowerCase()]
    if (action && action.enabled) action.clicked()
  }

  function activateAction() {
    var action = root.actions[root.actionIndex]
    if (!action || !action.enabled) return
    if (action === backendDropdown || action === languageDropdown) action.toggle()
    else action.clicked()
  }

  function focusControls() {
    if (!backendDropdown.popupOpen && !languageDropdown.popupOpen
        && !unloadingModel && !editingReplacements) keyCatcher.forceActiveFocus()
  }

  onOpenedChanged: if (opened) {
    unloadingModel = false
    actionIndex = 0
    draftTouched = false
    syncDrafts()
    if (voxtype) voxtype.refreshMetadata()
    Qt.callLater(root.focusControls)
  }

  Connections {
    target: root.voxtype
    function onMetadataUpdated() { root.syncDrafts() }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  StateColors { id: stateColors }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.statusIcon
    foreground: root.statusColor
    iconComponent: Component {
      ReloadIcon {
        text: root.statusIcon
        color: root.statusColor
        fontFamily: button.fontFamily
        fontSize: button.fontSize
        pulsing: root.voxtype && root.voxtype.reloading
      }
    }
    useActiveColor: false
    active: root.opened
    onPressed: function(mouseButton) {
      hoverTooltip.dismiss()
      if (mouseButton === Qt.RightButton) root.launchConfiguration()
      else if (mouseButton === Qt.LeftButton) root.toggle()
    }
  }

  StatusTooltip {
    id: hoverTooltip
    anchorItem: button
    bar: root.bar
    model: root.voxtype ? root.voxtype.modelLabel : "No selected model"
    stateLabel: root.voxtype ? root.voxtype.stateLabel : "Unavailable"
    stateColor: root.stateColor
    fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
    hovered: button.tooltipHovered && !root.opened && !(root.bar && root.bar.activePopout)
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened && !root.editingReplacements
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(root.unloadingModel && unloadLoader.item
      ? unloadLoader.item.implicitWidth + panel.padding * 2
        + Border.left(panel.borderSpec) + Border.right(panel.borderSpec) : Style.space(440))
    contentHeight: panel.fittedContentHeight(root.unloadingModel && unloadLoader.item
      ? unloadLoader.item.implicitHeight : content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: root.unloadingModel || backendDropdown.popupOpen || languageDropdown.popupOpen
      onMoveRequested: function(dx, dy) {
        root.moveCursor(dx, dy)
      }
      onActivateRequested: root.activateAction()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.moveControl(direction) }
      onTextKey: function(text) { root.activateShortcut(text) }

      Shortcut {
        sequence: "Tab"
        context: Qt.ApplicationShortcut
        enabled: root.opened && !root.unloadingModel
        onActivated: root.moveControl(1)
      }

      Shortcut {
        sequence: "Backtab"
        context: Qt.ApplicationShortcut
        enabled: root.opened && !root.unloadingModel
        onActivated: root.moveControl(-1)
      }

      Loader {
        id: unloadLoader
        width: parent.width
        active: root.opened && root.unloadingModel
        visible: active
        sourceComponent: Component {
          UnloadModel {
            width: unloadLoader.width
            service: root.voxtype
            foreground: root.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            onCancelled: {
              root.unloadingModel = false
              Qt.callLater(root.focusControls)
            }
          }
        }
      }

      Column {
        id: content
        visible: !root.unloadingModel
        width: parent.width
        spacing: Style.space(10)

        Item {
          width: parent.width
          implicitHeight: Math.max(titleBlock.implicitHeight, modelBox.implicitHeight)

          Row {
            id: titleBlock
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(14)

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: root.statusIcon
              color: root.statusColor
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.display
            }

            Column {
              spacing: Style.space(2)

              Text {
                text: "Voxtype"
                color: root.foreground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.title
                font.bold: true
              }

              Text {
                text: root.voxtype ? root.voxtype.stateLabel : "Unavailable"
                textFormat: Text.PlainText
                color: root.stateColor
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.body
                font.bold: true
              }
            }
          }

            BorderSurface {
              id: modelBox
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              implicitWidth: Math.min(content.width * 0.65, Math.max(
                modelText.implicitWidth, hardwareText.implicitWidth) + Style.space(16))
              implicitHeight: statusColumn.implicitHeight + Style.space(10)
              color: "transparent"
              borderSpec: Border.controlSpec(
                "normal", root.foreground, Color.accent)
              radius: Style.cornerRadius

              Column {
                id: statusColumn
                anchors.centerIn: parent
                width: parent.width - Style.space(16)
                spacing: Style.space(2)

                Text {
                  id: modelText
                  width: parent.width
                  text: root.voxtype ? root.voxtype.modelLabel : "No model"
                  textFormat: Text.PlainText
                  elide: Text.ElideRight
                  color: root.voxtype && root.voxtype.loaded ? root.foreground : root.dim
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.body
                  font.bold: true
                }

                Text {
                  id: hardwareText
                  width: parent.width
                  text: root.voxtype ? root.voxtype.hardwareLabel : "GPU unavailable"
                  textFormat: Text.PlainText
                  elide: Text.ElideRight
                  color: root.foreground
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.body
                }

              }
            }
        }

        PanelSeparator { foreground: root.foreground }

        NoticeSection {
          width: parent.width
          message: root.voxtype && root.voxtype.message ? root.voxtype.message
            : root.selectedModel ? root.selectedModel.reason : ""
          warning: root.voxtype && root.voxtype.message !== "" && root.voxtype.messageIsWarning
          warningColor: root.warning
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
        }

        Row {
          width: parent.width
          spacing: Style.space(6)

        GuardedSearchableDropdown {
          id: backendDropdown
          width: parent.width - unloadButton.width - parent.spacing
          label: "Speech model"
          placeholderText: "Choose an installed model..."
          selectedValue: root.draftModelId
          options: root.voxtype ? root.voxtype.localModels : []
          foreground: root.foreground
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          enabled: root.voxtype && root.voxtype.controlAvailable
            && !root.voxtype.busy
          hasCursor: root.opened && root.actionIndex === 0
          onHovered: function(hovered) {
            if (hovered) root.actionIndex = 0
          }
          onChanged: function(value) {
            root.draftTouched = true
            root.draftModelId = value
            root.draftLanguage = root.voxtype.defaultLanguageFor(value)
          }
          onPopupOpenChanged: if (!popupOpen) Qt.callLater(root.focusControls)
        }

        PanelActionButton {
          id: unloadButton
          size: backendDropdown.rowHeight
          fontSize: Style.font.body
          anchors.bottom: parent.bottom
          iconText: "×"
          tooltipText: "Unload current model; keep its files"
          Accessible.name: "Unload current model"
          foreground: root.urgent
          bordered: true
          enabled: root.voxtype && root.voxtype.loaded && !root.voxtype.busy && !root.voxtype.dictating
          focusable: false
          hasCursor: root.opened && root.actionIndex === 1
          onHovered: function(hovered) { if (hovered) root.actionIndex = 1 }
          onClicked: root.unloadingModel = true
        }
        }

        GuardedSearchableDropdown {
          id: languageDropdown
          width: parent.width
          label: "Spoken language (enabled)"
          placeholderText: "Choose a spoken language..."
          selectedValue: root.draftLanguage
          options: root.languageOptions
          foreground: root.foreground
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          enabled: root.voxtype && root.voxtype.controlAvailable
            && !root.voxtype.busy && root.selectedModel
            && root.selectedModel.codes.length > 1
          hasCursor: root.opened && root.actionIndex === 2
          onHovered: function(hovered) {
            if (hovered) root.actionIndex = 2
          }
          onChanged: function(value) {
            root.draftTouched = true
            root.draftLanguage = value
          }
          onPopupOpenChanged: if (!popupOpen) Qt.callLater(root.focusControls)
        }

        ApplySelectionButton {
          id: applyButton
          width: parent.width
          label: root.voxtype && root.voxtype.busy
            ? root.voxtype.stateLabel
            : root.selectedModel && root.selectedModel.codes.indexOf(root.draftLanguage) === -1
              ? "Choose a spoken language first" : "Load STT model / Apply language selection"
          spinning: root.voxtype && root.voxtype.busy
          checkColor: root.ready
          busyColor: root.warning
          enabled: root.canApply
          opacity: enabled || spinning ? 1 : 0.45
          bordered: true
          hasCursor: root.opened && root.actionIndex === 3
          onHovered: function(hovered) { if (hovered) root.actionIndex = 3 }
          foreground: root.foreground
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          onClicked: root.applyDraft()
        }

        Row {
          width: parent.width
          spacing: Style.space(6)

          Button {
            id: configureButton
            width: (parent.width - 2 * parent.spacing) / 3
            text: "Voxtype TUI"
            hasCursor: root.opened && root.actionIndex === 4
            onHovered: function(hovered) { if (hovered) root.actionIndex = 4 }
            iconText: "󰒓"
            enabled: root.voxtype && root.voxtype.controlAvailable && !root.voxtype.busy
            bordered: true
            foreground: root.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            onClicked: root.launchConfiguration()
          }

          Button {
            id: configFileButton
            width: (parent.width - 2 * parent.spacing) / 3
            text: "Settings"
            hasCursor: root.opened && root.actionIndex === 5
            onHovered: function(hovered) { if (hovered) root.actionIndex = 5 }
            iconText: "󰷈"
            enabled: root.voxtype !== null
            bordered: true
            foreground: root.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            onClicked: root.launchConfigFile()
          }

          Button {
            id: replacementsButton
            width: (parent.width - 2 * parent.spacing) / 3
            text: "Replacements"
            hasCursor: root.opened && root.actionIndex === 6
            onHovered: function(hovered) { if (hovered) root.actionIndex = 6 }
            iconText: "󰛔"
            enabled: root.voxtype && root.voxtype.controlAvailable && !root.voxtype.busy
            bordered: true
            foreground: root.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            onClicked: root.launchReplacements()
          }
        }

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: Style.space(16)
          Text {
            text: "h/j/k/l: move"
            color: root.dim
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }
          Text {
          text: "[v]oxtype  [s]ettings  [r]eplacements"
          textFormat: Text.PlainText
          color: root.dim
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
          font.letterSpacing: 0.8
          }
        }
      }
    }
  }
}
