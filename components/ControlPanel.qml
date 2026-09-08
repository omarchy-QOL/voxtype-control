pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons
import qs.Ui
import "../history" as History

KeyboardPanel {
    id: root

    required property var panelOwner
    required property var voxtype
    property bool editingReplacements: false
    property color foreground: Color.foreground
    property color dim: Qt.darker(foreground, 1.55)
    property color urgent: Color.urgent
    property color ready: Color.accent
    property color warning: Color.urgent
    property color statusColor: foreground
    property string statusIcon: "󰍬"
    property string fontFamily: Style.font.family
    property string draftModelId: ""
    property string draftLanguage: ""
    property bool draftTouched: false
    property int actionIndex: 0
    property bool unloadingModel: false
    property bool showingHistory: false
    readonly property var controlRows: [[backendDropdown, unloadButton], [languageDropdown],
        [applyButton], [configureButton, configFileButton], [replacementsButton, historyButton]]
    readonly property var actions: [].concat.apply([], controlRows)
    readonly property var languageOptions: voxtype ? voxtype.languageOptionsFor(draftModelId) : []
    readonly property var selectedModel: voxtype ? voxtype.modelFor(draftModelId) : null
    readonly property bool canApply: voxtype && voxtype.controlAvailable && !voxtype.busy && !voxtype.dictating && selectedModel && !selectedModel.reason && selectedModel.codes.indexOf(draftLanguage) !== -1 && (!voxtype.loaded || !voxtype.endpointReady || voxtype.errorOperation === "apply" || draftModelId !== voxtype.modelId || draftLanguage !== voxtype.language)

    signal closeRequested
    signal configureRequested
    signal configFileRequested
    signal replacementsRequested

    function applyDraft() {
        if (root.canApply)
            root.voxtype.applySelection(root.draftModelId, root.draftLanguage);
    }

    function syncDrafts() {
        if (!root.voxtype || root.draftTouched)
            return;
        root.draftModelId = root.voxtype.modelId;
        root.draftLanguage = root.voxtype.language;
        if (!root.draftLanguage)
            root.draftLanguage = root.voxtype.defaultLanguageFor(root.draftModelId);
    }

    function prepareOpen() {
        root.unloadingModel = false;
        root.showingHistory = false;
        root.actionIndex = 0;
        root.draftTouched = false;
        root.syncDrafts();
        if (root.voxtype)
            root.voxtype.refreshMetadata();
        Qt.callLater(root.focusControls);
    }

    function openHistory() {
        if (!root.voxtype || !root.voxtype.history)
            return;
        root.showingHistory = true;
        Qt.callLater(function () {
            if (historyLoader.item)
                historyLoader.item.activate();
        });
    }

    function returnFromHistory() {
        root.showingHistory = false;
        root.actionIndex = root.actions.indexOf(historyButton);
        Qt.callLater(root.focusControls);
    }

    function moveControl(direction) {
        backendDropdown.close();
        languageDropdown.close();
        root.actionIndex = (root.actionIndex + direction + root.actions.length) % root.actions.length;
        root.focusControls();
    }

    function moveCursor(dx, dy) {
        for (var row = 0; row < root.controlRows.length; row++) {
            var column = root.controlRows[row].indexOf(root.actions[root.actionIndex]);
            if (column === -1)
                continue;
            if (dy) {
                row = (row + dy + root.controlRows.length) % root.controlRows.length;
                column = Math.min(column, root.controlRows[row].length - 1);
            } else
                column = (column + dx + root.controlRows[row].length) % root.controlRows[row].length;
            root.actionIndex = root.actions.indexOf(root.controlRows[row][column]);
            root.focusControls();
            return;
        }
    }

    function activateShortcut(text) {
        if (text.toLowerCase() === "q") {
            root.closeRequested();
            return;
        }
        var action = ({
                v: configureButton,
                s: configFileButton,
                r: replacementsButton,
                t: historyButton
            })[text.toLowerCase()];
        if (action && action.enabled)
            action.clicked();
    }

    function activateAction() {
        var action = root.actions[root.actionIndex];
        if (!action || !action.enabled)
            return;
        if (action === backendDropdown || action === languageDropdown)
            action.toggle();
        else
            action.clicked();
    }

    function focusControls() {
        if (!backendDropdown.popupOpen && !languageDropdown.popupOpen
            && !root.unloadingModel && !root.showingHistory && !root.editingReplacements)
            keyCatcher.forceActiveFocus();
    }

    property Connections modelConnections: Connections {
        target: root.voxtype
        function onMetadataUpdated() {
            root.syncDrafts();
        }
    }

    owner: root.panelOwner
    open: root.panelOwner.opened && !root.editingReplacements
    focusTarget: keyCatcher
    contentWidth: root.fittedContentWidth(root.unloadingModel && unloadLoader.item
        ? unloadLoader.item.implicitWidth + root.padding * 2 + Border.left(root.borderSpec)
          + Border.right(root.borderSpec) : Style.space(440))
    contentHeight: root.fittedContentHeight(root.showingHistory && historyLoader.item
        ? historyLoader.item.implicitHeight : root.unloadingModel && unloadLoader.item
          ? unloadLoader.item.implicitHeight : content.implicitHeight)

    Loader {
        id: historyLoader
        width: parent.width
        active: root.open && root.showingHistory
        visible: active
        sourceComponent: Component {
            History.TranscriptHistory {
                width: historyLoader.width
                service: root.voxtype.history
                foreground: root.foreground
                dim: root.dim
                urgent: root.urgent
                ready: root.ready
                warningColor: root.warning
                fontFamily: root.fontFamily
                onBackRequested: root.returnFromHistory()
            }
        }
    }

    PanelKeyCatcher {
        id: keyCatcher
        anchors.fill: parent
        visible: !root.showingHistory
        blocked: root.unloadingModel || backendDropdown.popupOpen || languageDropdown.popupOpen
        onMoveRequested: function (dx, dy) {
            root.moveCursor(dx, dy);
        }
        onActivateRequested: root.activateAction()
        onCloseRequested: root.closeRequested()
        onTabRequested: function (direction) {
            root.moveControl(direction);
        }
        onTextKey: function (text) {
            root.activateShortcut(text);
        }

        Shortcut {
            sequence: "Tab"
            context: Qt.ApplicationShortcut
            enabled: root.panelOwner.opened && !root.unloadingModel && !root.showingHistory
            onActivated: root.moveControl(1)
        }

        Shortcut {
            sequence: "Backtab"
            context: Qt.ApplicationShortcut
            enabled: root.panelOwner.opened && !root.unloadingModel && !root.showingHistory
            onActivated: root.moveControl(-1)
        }

        Loader {
            id: unloadLoader
            width: parent.width
            active: root.panelOwner.opened && root.unloadingModel
            visible: active
            sourceComponent: Component {
                UnloadModel {
                    width: unloadLoader.width
                    service: root.voxtype
                    foreground: root.foreground
                    fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                    onCancelled: {
                        root.unloadingModel = false;
                        Qt.callLater(root.focusControls);
                    }
                }
            }
        }

        Column {
            id: content
            visible: !root.unloadingModel && !root.showingHistory
            width: parent.width
            spacing: Style.space(10)

            StatusHeader {
                width: parent.width
                service: root.voxtype
                foreground: root.foreground
                dim: root.dim
                stateColor: root.stateColor
                statusColor: root.statusColor
                statusIcon: root.statusIcon
                fontFamily: root.fontFamily
            }

            PanelSeparator {
                foreground: root.foreground
            }

            NoticeSection {
                width: parent.width
                message: root.voxtype && root.voxtype.message ? root.voxtype.message : root.selectedModel ? root.selectedModel.reason : ""
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
                    enabled: root.voxtype && root.voxtype.controlAvailable && !root.voxtype.busy
                    hasCursor: root.panelOwner.opened && root.actionIndex === 0
                    onHovered: function (hovered) {
                        if (hovered)
                            root.actionIndex = 0;
                    }
                    onChanged: function (value) {
                        root.draftTouched = true;
                        root.draftModelId = value;
                        root.draftLanguage = root.voxtype.defaultLanguageFor(value);
                    }
                    onPopupOpenChanged: if (!popupOpen)
                        Qt.callLater(root.focusControls)
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
                    hasCursor: root.panelOwner.opened && root.actionIndex === 1
                    onHovered: function (hovered) {
                        if (hovered)
                            root.actionIndex = 1;
                    }
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
                enabled: root.voxtype && root.voxtype.controlAvailable && !root.voxtype.busy && root.selectedModel && root.selectedModel.codes.length > 1
                hasCursor: root.panelOwner.opened && root.actionIndex === 2
                onHovered: function (hovered) {
                    if (hovered)
                        root.actionIndex = 2;
                }
                onChanged: function (value) {
                    root.draftTouched = true;
                    root.draftLanguage = value;
                }
                onPopupOpenChanged: if (!popupOpen)
                    Qt.callLater(root.focusControls)
            }

            ApplySelectionButton {
                id: applyButton
                width: parent.width
                label: root.voxtype && root.voxtype.busy ? root.voxtype.stateLabel : root.selectedModel && root.selectedModel.codes.indexOf(root.draftLanguage) === -1 ? "Choose a spoken language first" : "Load STT model / Apply language selection"
                spinning: root.voxtype && root.voxtype.busy
                checkColor: root.ready
                busyColor: root.warning
                enabled: root.canApply
                opacity: enabled || spinning ? 1 : 0.45
                bordered: true
                hasCursor: root.panelOwner.opened && root.actionIndex === 3
                onHovered: function (hovered) {
                    if (hovered)
                        root.actionIndex = 3;
                }
                foreground: root.foreground
                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                onClicked: root.applyDraft()
            }

            Row {
                width: parent.width
                spacing: Style.space(6)

                Button {
                    id: configureButton
                    width: (parent.width - parent.spacing) / 2
                    text: "Voxtype TUI"
                    hasCursor: root.panelOwner.opened && root.actionIndex === root.actions.indexOf(configureButton)
                    onHovered: function (hovered) {
                        if (hovered)
                            root.actionIndex = root.actions.indexOf(configureButton);
                    }
                    iconText: "󰒓"
                    enabled: root.voxtype && root.voxtype.controlAvailable && !root.voxtype.busy
                    bordered: true
                    foreground: root.foreground
                    fontFamily: root.fontFamily
                    onClicked: root.configureRequested()
                }

                Button {
                    id: configFileButton
                    width: configureButton.width
                    text: "Settings"
                    hasCursor: root.panelOwner.opened && root.actionIndex === root.actions.indexOf(configFileButton)
                    onHovered: function (hovered) {
                        if (hovered)
                            root.actionIndex = root.actions.indexOf(configFileButton);
                    }
                    iconText: "󰷈"
                    enabled: root.voxtype !== null
                    bordered: true
                    foreground: root.foreground
                    fontFamily: root.fontFamily
                    onClicked: root.configFileRequested()
                }
            }

            Row {
                width: parent.width
                spacing: Style.space(6)

                Button {
                    id: replacementsButton
                    width: (parent.width - parent.spacing) / 2
                    text: "Replacements"
                    hasCursor: root.panelOwner.opened && root.actionIndex === root.actions.indexOf(replacementsButton)
                    onHovered: function (hovered) {
                        if (hovered)
                            root.actionIndex = root.actions.indexOf(replacementsButton);
                    }
                    iconText: "󰛔"
                    enabled: root.voxtype && root.voxtype.controlAvailable && !root.voxtype.busy
                    bordered: true
                    foreground: root.foreground
                    fontFamily: root.fontFamily
                    onClicked: root.replacementsRequested()
                }

                Button {
                    id: historyButton
                    width: replacementsButton.width
                    text: "Transcripts"
                    hasCursor: root.panelOwner.opened && root.actionIndex === root.actions.indexOf(historyButton)
                    onHovered: function (hovered) {
                        if (hovered)
                            root.actionIndex = root.actions.indexOf(historyButton);
                    }
                    iconText: "󰈙"
                    enabled: root.voxtype && root.voxtype.history
                    bordered: true
                    foreground: root.foreground
                    fontFamily: root.fontFamily
                    onClicked: root.openHistory()
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
                    text: "[v]oxtype  [s]ettings  [r]eplacements  [t]ranscripts"
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
