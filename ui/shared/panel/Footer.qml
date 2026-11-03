pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons

// Shortcuts that leave the main controls.
Row {
    id: root

    required property var panel
    property alias configureShortcut: configureShortcut
    property alias settingsShortcut: settingsShortcut
    property alias replacementsShortcut: replacementsShortcut
    property alias historyShortcut: historyShortcut

    objectName: "voxtypeShortcutFooter"
    spacing: Style.space(12)

    FooterShortcut {
        id: configureShortcut
        shortcut: root.panel.backendUi.toolShortcut
        suffix: root.panel.backendUi.toolSuffix
        shortcutColor: root.panel.warning
        foreground: root.panel.dim
        fontFamily: root.panel.fontFamily
        hasCursor: root.panel.panelOwner.opened && root.panel.actionIndex === root.panel.actions.indexOf(configureShortcut)
        enabled: root.panel.voxtype && root.panel.voxtype.controlAvailable && !root.panel.voxtype.busy
        onHovered: function (hovered) {
            if (hovered)
                root.panel.actionIndex = root.panel.actions.indexOf(configureShortcut);
        }
        onClicked: root.panel.configureRequested()
    }

    FooterShortcut {
        id: settingsShortcut
        shortcut: "s"
        suffix: "ettings"
        shortcutColor: root.panel.warning
        foreground: root.panel.dim
        fontFamily: root.panel.fontFamily
        hasCursor: root.panel.panelOwner.opened && root.panel.actionIndex === root.panel.actions.indexOf(settingsShortcut)
        enabled: root.panel.voxtype !== null
        onHovered: function (hovered) {
            if (hovered)
                root.panel.actionIndex = root.panel.actions.indexOf(settingsShortcut);
        }
        onClicked: root.panel.configFileRequested()
    }

    FooterShortcut {
        id: replacementsShortcut
        shortcut: "r"
        suffix: "eplacements"
        shortcutColor: root.panel.warning
        foreground: root.panel.dim
        fontFamily: root.panel.fontFamily
        hasCursor: root.panel.panelOwner.opened && root.panel.actionIndex === root.panel.actions.indexOf(replacementsShortcut)
        enabled: root.panel.voxtype && root.panel.voxtype.controlAvailable && !root.panel.voxtype.busy
        onHovered: function (hovered) {
            if (hovered)
                root.panel.actionIndex = root.panel.actions.indexOf(replacementsShortcut);
        }
        onClicked: root.panel.replacementsRequested()
    }

    FooterShortcut {
        id: historyShortcut
        shortcut: "t"
        suffix: "ranscripts"
        shortcutColor: root.panel.warning
        foreground: root.panel.dim
        fontFamily: root.panel.fontFamily
        hasCursor: root.panel.panelOwner.opened && root.panel.actionIndex === root.panel.actions.indexOf(historyShortcut)
        enabled: root.panel.voxtype && root.panel.voxtype.history
        onHovered: function (hovered) {
            if (hovered)
                root.panel.actionIndex = root.panel.actions.indexOf(historyShortcut);
        }
        onClicked: root.panel.openHistory()
    }
}
