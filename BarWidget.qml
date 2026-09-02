import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "io.github.ilyazar.voxtype-control"

  property string draftBackend: "unknown"
  property string draftLanguage: "auto"
  property bool draftTouched: false
  property int actionIndex: 0

  readonly property var voxtype: bar && bar.shell
    ? bar.shell.serviceFor(moduleName) : null
  readonly property color foreground: bar ? bar.barForeground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color statusColor:
    voxtype && voxtype.dictationState === "recording" ? urgent
    : voxtype && voxtype.dictationState === "transcribing" ? "#e5c07b"
    : voxtype && voxtype.available ? foreground : dim
  readonly property string statusIcon:
    voxtype && voxtype.dictationState === "transcribing" ? "󰔟" : "󰍬"
  readonly property var languageOptions: voxtype
    ? voxtype.languageOptionsFor(draftBackend) : []
  readonly property bool selectionChanged: voxtype
    && (draftBackend !== voxtype.backend
      || draftLanguage !== voxtype.language)
  readonly property bool canApply: voxtype && voxtype.controlAvailable
    && voxtype.available && !voxtype.busy && selectionChanged

  function optionContains(options, value) {
    for (var i = 0; i < options.length; i++)
      if (String(options[i].value) === String(value)) return true
    return false
  }

  function syncDrafts() {
    if (!voxtype || draftTouched) return
    draftBackend = voxtype.backend
    draftLanguage = voxtype.language
    if (!optionContains(voxtype.languageOptionsFor(draftBackend),
        draftLanguage))
      draftLanguage = "auto"
  }

  function openControls() {
    draftTouched = false
    syncDrafts()
    if (voxtype) voxtype.refreshMetadata()
    toggle()
  }

  function launchConfiguration() {
    close()
    if (voxtype)
      Quickshell.execDetached([voxtype.configurePath])
  }

  function close() {
    controller.hide()
  }

  function activateAction() {
    if (!voxtype) return
    if (actionIndex === 0) backendDropdown.toggle()
    else if (actionIndex === 1) languageDropdown.toggle()
    else if (actionIndex === 2 && canApply)
      voxtype.applySelection(draftBackend, draftLanguage)
    else if (actionIndex === 3 && voxtype.available)
      voxtype.record("toggle")
    else if (actionIndex === 4
        && (voxtype.dictationState === "recording"
          || voxtype.dictationState === "transcribing"))
      voxtype.record("cancel")
    else if (actionIndex === 5 && voxtype.controlAvailable)
      launchConfiguration()
  }

  onOpenedChanged: if (opened) {
    actionIndex = 0
    draftTouched = false
    syncDrafts()
    if (voxtype) voxtype.refreshMetadata()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  Connections {
    target: root.voxtype
    function onBackendChanged() { root.syncDrafts() }
    function onLanguageChanged() { root.syncDrafts() }
    function onOperationFinished(success) {
      if (!success) return
      root.draftTouched = false
      root.syncDrafts()
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.statusIcon
    foreground: root.statusColor
    useActiveColor: false
    active: root.opened
    slotSize: Style.bar.statusSlot
    fontSize: Style.font.caption
    tooltipText: root.voxtype ? root.voxtype.tooltip : "Voxtype unavailable"
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.RightButton) root.launchConfiguration()
      else if (mouseButton === Qt.LeftButton) root.openControls()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: backendDropdown.popupOpen || languageDropdown.popupOpen
      onMoveRequested: function(dx, dy) {
        if (dy === 0) return
        root.actionIndex = (root.actionIndex + dy + 6) % 6
      }
      onActivateRequested: root.activateAction()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(10)

        PanelHero {
          width: parent.width
          title: "Voxtype"
          meta: root.voxtype ? root.voxtype.backendLabel : "Unavailable"
          detail: root.voxtype
            ? root.voxtype.stateLabel + " | " + root.voxtype.modelLabel
            : "Control service unavailable"
          foreground: root.foreground
          fontFamily: bar ? bar.fontFamily : Style.font.family
          iconComponent: Component {
            Text {
              text: root.statusIcon
              color: root.statusColor
              font.family: bar ? bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.display
            }
          }
        }

        Text {
          width: parent.width
          text: root.voxtype
            ? "Device: " + (root.voxtype.device || "unknown")
              + (root.voxtype.precision
                ? " | Precision: " + root.voxtype.precision : "")
              + "\nPause/Break or Ctrl+Delete toggles dictation"
            : "Voxtype metadata is unavailable"
          color: root.dim
          font.family: bar ? bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        Text {
          visible: root.voxtype && root.voxtype.rollbackModels.length > 0
          width: parent.width
          text: root.voxtype
            ? "Whisper rollback: " + root.voxtype.rollbackModels.join(", ")
            : ""
          color: root.dim
          font.family: bar ? bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        PanelSeparator { foreground: root.foreground }

        Dropdown {
          id: backendDropdown
          width: parent.width
          label: "ASR backend"
          value: root.draftBackend
          options: root.voxtype ? root.voxtype.backendOptions : []
          foreground: root.foreground
          fontFamily: bar ? bar.fontFamily : Style.font.family
          enabled: root.voxtype && root.voxtype.controlAvailable
            && !root.voxtype.busy
          hasCursor: root.opened && root.actionIndex === 0
          onHovered: function(hovered) {
            if (hovered) root.actionIndex = 0
          }
          onChanged: function(value) {
            root.draftTouched = true
            root.draftBackend = value
            var options = root.voxtype.languageOptionsFor(value)
            if (!root.optionContains(options, root.draftLanguage))
              root.draftLanguage = "auto"
          }
        }

        SearchableDropdown {
          id: languageDropdown
          width: parent.width
          label: "Language"
          placeholderText: "Search supported languages..."
          value: root.draftLanguage
          options: root.languageOptions
          foreground: root.foreground
          fontFamily: bar ? bar.fontFamily : Style.font.family
          enabled: root.voxtype && root.voxtype.controlAvailable
            && !root.voxtype.busy
          hasCursor: root.opened && root.actionIndex === 1
          onHovered: function(hovered) {
            if (hovered) root.actionIndex = 1
          }
          onChanged: function(value) {
            root.draftTouched = true
            root.draftLanguage = value
          }
        }

        Text {
          visible: root.voxtype && root.voxtype.error !== ""
          width: parent.width
          text: root.voxtype ? root.voxtype.error : ""
          color: root.urgent
          font.family: bar ? bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        Button {
          id: applyButton
          width: parent.width
          text: root.voxtype && root.voxtype.busy
            ? "Applying selection..." : "Apply backend and language"
          iconText: root.voxtype && root.voxtype.busy ? "󰑓" : "󰄬"
          iconSpinning: root.voxtype && root.voxtype.busy
          enabled: root.canApply
          opacity: enabled ? 1 : 0.45
          bordered: true
          hasCursor: root.opened && root.actionIndex === 2
          foreground: root.foreground
          fontFamily: bar ? bar.fontFamily : Style.font.family
          onClicked: if (root.voxtype)
            root.voxtype.applySelection(
              root.draftBackend, root.draftLanguage)
        }

        Row {
          width: parent.width
          spacing: Style.space(6)

          Button {
            id: toggleButton
            width: (parent.width - parent.spacing) / 2
            text: root.voxtype
              && root.voxtype.dictationState === "recording"
              ? "Stop and transcribe" : "Toggle dictation"
            iconText: "󰍬"
            enabled: root.voxtype && root.voxtype.available
              && !root.voxtype.busy
            bordered: true
            hasCursor: root.opened && root.actionIndex === 3
            foreground: root.foreground
            fontFamily: bar ? bar.fontFamily : Style.font.family
            onClicked: if (root.voxtype) root.voxtype.record("toggle")
          }

          Button {
            id: cancelButton
            width: (parent.width - parent.spacing) / 2
            text: "Cancel"
            iconText: "󰜺"
            enabled: root.voxtype
              && (root.voxtype.dictationState === "recording"
                || root.voxtype.dictationState === "transcribing")
            bordered: true
            hasCursor: root.opened && root.actionIndex === 4
            foreground: root.foreground
            fontFamily: bar ? bar.fontFamily : Style.font.family
            onClicked: if (root.voxtype) root.voxtype.record("cancel")
          }
        }

        Button {
          id: configureButton
          width: parent.width
          text: "Open full Voxtype configuration"
          iconText: "󰒓"
          enabled: root.voxtype && root.voxtype.controlAvailable
          bordered: true
          hasCursor: root.opened && root.actionIndex === 5
          foreground: root.foreground
          fontFamily: bar ? bar.fontFamily : Style.font.family
          onClicked: root.launchConfiguration()
        }
      }
    }
  }
}
