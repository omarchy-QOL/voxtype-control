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
  readonly property color ready: "#a3be8c"
  readonly property color warning: "#ebcb8b"
  readonly property color statusColor:
    voxtype && voxtype.dictationState === "recording" ? urgent
    : voxtype && voxtype.dictationState === "transcribing" ? "#e5c07b"
    : voxtype && voxtype.available ? foreground : dim
  readonly property string statusIcon:
    voxtype && voxtype.dictationState === "transcribing" ? "󰔟" : "󰍬"
  readonly property color stateColor:
    voxtype && voxtype.dictationState === "idle"
      && voxtype.endpointReady ? ready
    : voxtype && voxtype.dictationState === "recording" ? urgent
    : warning
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

  function launchConfigFile() {
    close()
    if (voxtype)
      Quickshell.execDetached([
        "omarchy-launch-config-editor", voxtype.configPath
      ])
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
    else if (actionIndex === 3 && voxtype.controlAvailable)
      launchConfiguration()
    else if (actionIndex === 4) launchConfigFile()
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
        root.actionIndex = (root.actionIndex + dy + 5) % 5
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
          trailingControl: Component {
            BorderSurface {
              implicitWidth: statusRow.implicitWidth + Style.space(10)
              implicitHeight: statusRow.implicitHeight + Style.space(4)
              color: "transparent"
              borderSpec: Border.controlSpec(
                "normal", root.foreground, Color.accent)
              radius: Style.cornerRadius

              Row {
                id: statusRow
                anchors.centerIn: parent
                spacing: Style.space(4)

                Text {
                  text: root.voxtype
                    ? root.voxtype.stateLabel : "Unavailable"
                  color: root.stateColor
                  font.family: bar ? bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.body
                  font.bold: true
                }

                Text {
                  text: "| " + (root.voxtype
                    ? root.voxtype.modelLabel : "No model")
                  color: root.dim
                  font.family: bar ? bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.body
                  font.bold: true
                }
              }
            }
          }
        }

        Text {
          width: parent.width
          text: root.voxtype
            ? "Device: " + (root.voxtype.device || "unknown")
              + (root.voxtype.precision
                ? " | Precision: " + root.voxtype.precision : "")
            : "Voxtype metadata is unavailable"
          color: root.dim
          font.family: bar ? bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        PanelSeparator { foreground: root.foreground }

        Dropdown {
          id: backendDropdown
          width: parent.width
          label: "Local ASR model"
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
            Qt.callLater(function() { backendDropdown.close() })
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
            Qt.callLater(function() { languageDropdown.close() })
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
            ? "Applying selection..." : "Apply model and language"
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
            id: configureButton
            width: (parent.width - parent.spacing) / 2
            text: "Open Voxtype TUI"
            iconText: "󰒓"
            enabled: root.voxtype && root.voxtype.controlAvailable
            bordered: true
            hasCursor: root.opened && root.actionIndex === 3
            foreground: root.foreground
            fontFamily: bar ? bar.fontFamily : Style.font.family
            onClicked: root.launchConfiguration()
          }

          Button {
            id: configFileButton
            width: (parent.width - parent.spacing) / 2
            text: "Open config file"
            iconText: "󰷈"
            enabled: root.voxtype !== null
            bordered: true
            hasCursor: root.opened && root.actionIndex === 4
            foreground: root.foreground
            fontFamily: bar ? bar.fontFamily : Style.font.family
            onClicked: root.launchConfigFile()
          }
        }
      }
    }
  }
}
