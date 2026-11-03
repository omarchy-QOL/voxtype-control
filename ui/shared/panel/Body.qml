pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons
import qs.Ui

// Model, language and the primary actions.
Column {
    id: root

    required property var panel
    property alias backendDropdown: backendDropdown
    property alias unloadButton: unloadButton
    property alias languageDropdown: languageDropdown
    property alias primaryActions: primaryActions
    property alias applyButton: applyButton
    property alias copyLastButton: copyLastButton

    spacing: Style.space(10)

    NoticeSection {
        width: parent.width
        message: root.panel.voxtype && root.panel.voxtype.message ? root.panel.voxtype.message : root.panel.selectedModel ? root.panel.selectedModel.reason : ""
        warning: root.panel.voxtype && root.panel.voxtype.message !== "" && root.panel.voxtype.messageIsWarning
        warningColor: root.panel.warning
        fontFamily: root.panel.bar ? root.panel.bar.fontFamily : Style.font.family
    }

    Row {
        width: parent.width
        spacing: Style.space(6)

        GuardedSearchableDropdown {
            id: backendDropdown
            width: parent.width - unloadButton.width - parent.spacing
            label: "Speech model"
            placeholderText: "Choose an installed model..."
            selectedValue: root.panel.draftModelId
            options: root.panel.voxtype ? root.panel.voxtype.localModels : []
            foreground: root.panel.foreground
            fontFamily: root.panel.bar ? root.panel.bar.fontFamily : Style.font.family
            enabled: root.panel.voxtype && root.panel.voxtype.controlAvailable && !root.panel.voxtype.busy
            hasCursor: root.panel.panelOwner.opened && root.panel.actionIndex === 0
            onHovered: function (hovered) {
                if (hovered)
                    root.panel.actionIndex = 0;
            }
            onChanged: function (value) {
                root.panel.draftTouched = true;
                root.panel.draftModelId = value;
                root.panel.draftLanguage = root.panel.voxtype.defaultLanguageFor(value);
            }
            onPopupOpenChanged: if (!popupOpen)
                Qt.callLater(root.panel.focusControls)
        }

        PanelActionButton {
            id: unloadButton
            size: backendDropdown.rowHeight
            fontSize: Style.font.icon
            anchors.bottom: parent.bottom
            iconText: "\uf052"
            tooltipText: "Unload current model; keep its files"
            Accessible.name: "Unload current model"
            foreground: root.panel.urgent
            bordered: true
            enabled: root.panel.voxtype && root.panel.voxtype.loaded && !root.panel.voxtype.busy && !root.panel.voxtype.dictating
            focusable: false
            hasCursor: root.panel.panelOwner.opened && root.panel.actionIndex === 1
            onHovered: function (hovered) {
                if (hovered)
                    root.panel.actionIndex = 1;
            }
            onClicked: root.panel.unloadingModel = true
        }
    }

    GuardedSearchableDropdown {
        id: languageDropdown
        width: parent.width
        label: "Spoken language (enabled)"
        placeholderText: "Choose a spoken language..."
        selectedValue: root.panel.draftLanguage
        options: root.panel.languageOptions
        foreground: root.panel.foreground
        fontFamily: root.panel.bar ? root.panel.bar.fontFamily : Style.font.family
        enabled: root.panel.voxtype && root.panel.voxtype.controlAvailable && !root.panel.voxtype.busy && root.panel.selectedModel && root.panel.selectedModel.codes.length > 1
        hasCursor: root.panel.panelOwner.opened && root.panel.actionIndex === 2
        onHovered: function (hovered) {
            if (hovered)
                root.panel.actionIndex = 2;
        }
        onChanged: function (value) {
            root.panel.draftTouched = true;
            root.panel.draftLanguage = value;
        }
        onPopupOpenChanged: if (!popupOpen)
            Qt.callLater(root.panel.focusControls)
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
            label: root.panel.voxtype && root.panel.voxtype.busy ? root.panel.voxtype.stateLabel : "Apply model/language"
            spinning: root.panel.voxtype && root.panel.voxtype.busy
            checkColor: root.panel.ready
            busyColor: root.panel.warning
            enabled: root.panel.canApply
            opacity: enabled || spinning ? 1 : 0.45
            bordered: true
            hasCursor: root.panel.panelOwner.opened && root.panel.actionIndex === 3
            onHovered: function (hovered) {
                if (hovered)
                    root.panel.actionIndex = 3;
            }
            foreground: root.panel.foreground
            fontFamily: root.panel.fontFamily
            onClicked: root.panel.applyDraft()
        }

        CopyLastTranscriptButton {
            id: copyLastButton
            width: parent.width - applyButton.width - parent.spacing
            height: parent.height
            shortcutColor: root.panel.warning
            foreground: root.panel.foreground
            fontFamily: root.panel.fontFamily
            bordered: true
            enabled: root.panel.historyService && !root.panel.historyService.busy
            opacity: enabled ? 1 : 0.45
            hasCursor: root.panel.panelOwner.opened && root.panel.actionIndex === root.panel.actions.indexOf(copyLastButton)
            onHovered: function (hovered) {
                if (hovered)
                    root.panel.actionIndex = root.panel.actions.indexOf(copyLastButton);
            }
            onClicked: root.panel.copyLastTranscript()
        }
    }

    Text {
        objectName: "voxtypeLastCopyNotice"
        width: parent.width
        visible: root.panel.showLastCopyNotice && text !== ""
        text: root.panel.historyService ? root.panel.historyService.error || root.panel.historyService.notice : ""
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
        color: root.panel.historyService && root.panel.historyService.error ? root.panel.urgent : root.panel.ready
        font.family: root.panel.fontFamily
        font.pixelSize: Style.font.caption
    }
}
