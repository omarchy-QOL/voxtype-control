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
    property string statusIcon: "󰍬"
    property string fontFamily: Style.font.family
    property string draftModelId: ""
    property string draftLanguage: ""
    property bool draftTouched: false
    property int actionIndex: 0
    property bool unloadingModel: false
    property bool showingHistory: false
    property bool showLastCopyNotice: false
    readonly property var historyService: voxtype && voxtype.history ? voxtype.history : null
    readonly property var controlRows: [[backendDropdown, unloadButton], [languageDropdown], [applyButton, copyLastButton], [configureShortcut, settingsShortcut, replacementsShortcut, historyShortcut]]
    readonly property real horizontalInset: root.padding * 2 + Border.left(root.borderSpec) + Border.right(root.borderSpec)
    readonly property real preferredControlsWidth: Math.max(Style.space(360), shortcutFooter.implicitWidth + root.horizontalInset, primaryActions.naturalWidth + root.horizontalInset)
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
                c: copyLastButton,
                v: configureShortcut,
                s: settingsShortcut,
                r: replacementsShortcut,
                t: historyShortcut
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
        if (!backendDropdown.popupOpen && !languageDropdown.popupOpen && !root.unloadingModel && !root.showingHistory && !root.editingReplacements)
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
    contentWidth: root.fittedContentWidth(root.showingHistory ? Style.space(440) : root.unloadingModel && unloadLoader.item ? unloadLoader.item.implicitWidth + root.horizontalInset : root.preferredControlsWidth)
    contentHeight: root.fittedContentHeight(root.showingHistory && historyLoader.item ? historyLoader.item.implicitHeight : root.unloadingModel && unloadLoader.item ? unloadLoader.item.implicitHeight : content.implicitHeight)

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
                onPanelCloseRequested: root.closeRequested()
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
                ready: root.ready
                urgent: root.urgent
                warning: root.warning
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
                    fontSize: Style.font.icon
                    anchors.bottom: parent.bottom
                    iconText: "\uf052"
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

            Row {
                id: primaryActions
                objectName: "voxtypePrimaryActions"
                readonly property real naturalWidth: applyButton.implicitWidth + copyLastButton.implicitWidth + spacing
                width: parent.width
                height: Math.max(applyButton.implicitHeight, copyLastButton.implicitHeight)
                spacing: Style.space(6)

                ApplySelectionButton {
                    id: applyButton
                    width: (parent.width - parent.spacing) * implicitWidth / (applyButton.implicitWidth + copyLastButton.implicitWidth)
                    height: parent.height
                    label: root.voxtype && root.voxtype.busy ? root.voxtype.stateLabel : "Apply model/language"
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
                    fontFamily: root.fontFamily
                    onClicked: root.applyDraft()
                }

                CopyLastTranscriptButton {
                    id: copyLastButton
                    width: parent.width - applyButton.width - parent.spacing
                    height: parent.height
                    shortcutColor: root.warning
                    foreground: root.foreground
                    fontFamily: root.fontFamily
                    bordered: true
                    enabled: root.historyService && !root.historyService.busy
                    opacity: enabled ? 1 : 0.45
                    hasCursor: root.panelOwner.opened && root.actionIndex === root.actions.indexOf(copyLastButton)
                    onHovered: function (hovered) {
                        if (hovered)
                            root.actionIndex = root.actions.indexOf(copyLastButton);
                    }
                    onClicked: root.copyLastTranscript()
                }
            }

            Text {
                objectName: "voxtypeLastCopyNotice"
                width: parent.width
                visible: root.showLastCopyNotice && text !== ""
                text: root.historyService ? root.historyService.error || root.historyService.notice : ""
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                color: root.historyService && root.historyService.error ? root.urgent : root.ready
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
            }

            PanelSeparator {
                objectName: "voxtypeFooterSeparator"
                foreground: root.foreground
            }

            Row {
                id: shortcutFooter
                objectName: "voxtypeShortcutFooter"
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Style.space(12)

                FooterShortcut {
                    id: configureShortcut
                    shortcut: "v"
                    suffix: "oxtype tui"
                    shortcutColor: root.warning
                    foreground: root.dim
                    fontFamily: root.fontFamily
                    hasCursor: root.panelOwner.opened && root.actionIndex === root.actions.indexOf(configureShortcut)
                    enabled: root.voxtype && root.voxtype.controlAvailable && !root.voxtype.busy
                    onHovered: function (hovered) {
                        if (hovered)
                            root.actionIndex = root.actions.indexOf(configureShortcut);
                    }
                    onClicked: root.configureRequested()
                }

                FooterShortcut {
                    id: settingsShortcut
                    shortcut: "s"
                    suffix: "ettings"
                    shortcutColor: root.warning
                    foreground: root.dim
                    fontFamily: root.fontFamily
                    hasCursor: root.panelOwner.opened && root.actionIndex === root.actions.indexOf(settingsShortcut)
                    enabled: root.voxtype !== null
                    onHovered: function (hovered) {
                        if (hovered)
                            root.actionIndex = root.actions.indexOf(settingsShortcut);
                    }
                    onClicked: root.configFileRequested()
                }

                FooterShortcut {
                    id: replacementsShortcut
                    shortcut: "r"
                    suffix: "eplacements"
                    shortcutColor: root.warning
                    foreground: root.dim
                    fontFamily: root.fontFamily
                    hasCursor: root.panelOwner.opened && root.actionIndex === root.actions.indexOf(replacementsShortcut)
                    enabled: root.voxtype && root.voxtype.controlAvailable && !root.voxtype.busy
                    onHovered: function (hovered) {
                        if (hovered)
                            root.actionIndex = root.actions.indexOf(replacementsShortcut);
                    }
                    onClicked: root.replacementsRequested()
                }

                FooterShortcut {
                    id: historyShortcut
                    shortcut: "t"
                    suffix: "ranscripts"
                    shortcutColor: root.warning
                    foreground: root.dim
                    fontFamily: root.fontFamily
                    hasCursor: root.panelOwner.opened && root.actionIndex === root.actions.indexOf(historyShortcut)
                    enabled: root.voxtype && root.voxtype.history
                    onHovered: function (hovered) {
                        if (hovered)
                            root.actionIndex = root.actions.indexOf(historyShortcut);
                    }
                    onClicked: root.openHistory()
                }
            }
        }
    }
}
