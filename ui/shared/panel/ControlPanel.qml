pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons
import qs.Ui
import "../transcripts" as Transcripts

KeyboardPanel {
    id: root

    required property var panelOwner
    required property var voxtype
    required property var backendUi
    property bool editingReplacements: false
    property color foreground: Color.foreground
    property color dim: Qt.darker(foreground, 1.55)
    property color urgent: Color.urgent
    property color ready: Color.accent
    property color warning: Color.urgent
    property string statusIcon: "󰍬"
    property string fontFamily: Style.font.family
    property string draftModelId: ""
    property string draftLanguage: ""
    property bool draftTouched: false
    property int actionIndex: 0
    property bool unloadingModel: false
    property bool showingHistory: false
    property bool showLastCopyNotice: false
    readonly property alias backendSwitcher: header.backendSwitcher
    readonly property alias modelDropdown: body.modelDropdown
    readonly property alias unloadButton: body.unloadButton
    readonly property alias languageDropdown: body.languageDropdown
    readonly property alias applyButton: body.applyButton
    readonly property alias copyLastButton: body.copyLastButton
    readonly property alias configureShortcut: footer.configureShortcut
    readonly property alias settingsShortcut: footer.settingsShortcut
    readonly property alias replacementsShortcut: footer.replacementsShortcut
    readonly property alias historyShortcut: footer.historyShortcut
    readonly property var historyService: voxtype && voxtype.history ? voxtype.history : null
    readonly property var controlRows: [[backendSwitcher], [modelDropdown, unloadButton], [languageDropdown], [applyButton, copyLastButton], [configureShortcut, settingsShortcut, replacementsShortcut, historyShortcut]]
    readonly property real horizontalInset: root.padding * 2 + Border.left(root.borderSpec) + Border.right(root.borderSpec)
    readonly property real preferredControlsWidth: Math.max(Style.space(360), footer.implicitWidth + root.horizontalInset, body.primaryActions.naturalWidth + root.horizontalInset)
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

    function copyLastTranscript() {
        if (!root.historyService || root.historyService.busy)
            return;
        root.showLastCopyNotice = true;
        // Resolve the newest stored entry, not a stale or search-filtered row.
        root.historyService.copy("latest");
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
        root.showLastCopyNotice = false;
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
        root.actionIndex = root.actions.indexOf(historyShortcut);
        Qt.callLater(root.focusControls);
    }

    function moveControl(direction) {
        backendSwitcher.close();
        modelDropdown.close();
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
        var actions = {
            c: copyLastButton,
            s: settingsShortcut,
            r: replacementsShortcut,
            t: historyShortcut
        };
        actions[root.backendUi.toolShortcut] = configureShortcut;
        var action = actions[text.toLowerCase()];
        if (action && action.enabled)
            action.clicked();
    }

    function activateAction() {
        var action = root.actions[root.actionIndex];
        if (!action || !action.enabled)
            return;
        if (action === backendSwitcher || action === modelDropdown || action === languageDropdown)
            action.toggle();
        else
            action.clicked();
    }

    function focusControls() {
        if (!backendSwitcher.popupOpen && !modelDropdown.popupOpen && !languageDropdown.popupOpen && !root.unloadingModel && !root.showingHistory && !root.editingReplacements)
            keyCatcher.forceActiveFocus();
    }

    property Connections modelConnections: Connections {
        target: root.voxtype
        function onMetadataUpdated() {
            root.syncDrafts();
        }
        function onBackendChanged() {
            root.draftTouched = false;
            root.draftModelId = "";
            root.draftLanguage = "";
        }
    }

    owner: root.panelOwner
    open: root.panelOwner.opened && !root.editingReplacements
    focusTarget: keyCatcher
    contentWidth: root.fittedContentWidth(root.showingHistory ? Style.space(440) : root.unloadingModel && unloadLoader.item ? unloadLoader.item.implicitWidth + root.horizontalInset : root.preferredControlsWidth)
    contentHeight: root.fittedContentHeight(root.showingHistory && historyLoader.item ? historyLoader.item.implicitHeight : root.unloadingModel && unloadLoader.item ? unloadLoader.item.implicitHeight : content.implicitHeight)

    Loader {
        id: historyLoader
        width: parent.width
        active: root.open && root.showingHistory
        visible: active
        sourceComponent: Component {
            Transcripts.TranscriptHistory {
                width: historyLoader.width
                service: root.voxtype.history
                foreground: root.foreground
                dim: root.dim
                urgent: root.urgent
                ready: root.ready
                warningColor: root.warning
                fontFamily: root.fontFamily
                onBackRequested: root.returnFromHistory()
                onPanelCloseRequested: root.closeRequested()
            }
        }
    }

    PanelKeyCatcher {
        id: keyCatcher
        anchors.fill: parent
        visible: !root.showingHistory
        blocked: root.unloadingModel || root.backendSwitcher.popupOpen || root.modelDropdown.popupOpen || root.languageDropdown.popupOpen
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

            Header {
                id: header
                width: parent.width
                panel: root
                service: root.voxtype
                foreground: root.foreground
                ready: root.ready
                urgent: root.urgent
                warning: root.warning
                statusIcon: root.statusIcon
                fontFamily: root.fontFamily
            }

            PanelSeparator {
                foreground: root.foreground
            }

            Body {
                id: body
                width: parent.width
                panel: root
            }

            PanelSeparator {
                objectName: "voxtypeFooterSeparator"
                foreground: root.foreground
            }

            Footer {
                id: footer
                anchors.horizontalCenter: parent.horizontalCenter
                panel: root
            }
        }
    }
}
