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
        labelVariants: root.panel.backendTools
        shortcutColor: root.panel.warning
        foreground: root.panel.dim
        fontFamily: root.panel.fontFamily
        hasCursor: root.panel.cursorOn(configureShortcut)
        enabled: root.panel.voxtype && root.panel.voxtype.controlAvailable && !root.panel.voxtype.busy
        onHovered: hovered => root.panel.trackHover(configureShortcut, hovered)
        onClicked: root.panel.configureRequested()
    }

    FooterShortcut {
        id: settingsShortcut
        shortcut: "s"
        suffix: "ettings"
        shortcutColor: root.panel.warning
        foreground: root.panel.dim
        fontFamily: root.panel.fontFamily
        hasCursor: root.panel.cursorOn(settingsShortcut)
        enabled: root.panel.voxtype !== null
        onHovered: hovered => root.panel.trackHover(settingsShortcut, hovered)
        onClicked: root.panel.configFileRequested()
    }

    FooterShortcut {
        id: replacementsShortcut
        shortcut: "r"
        suffix: "eplacements"
        shortcutColor: root.panel.warning
        foreground: root.panel.dim
        fontFamily: root.panel.fontFamily
        hasCursor: root.panel.cursorOn(replacementsShortcut)
        enabled: root.panel.voxtype && root.panel.voxtype.controlAvailable && !root.panel.voxtype.busy
        onHovered: hovered => root.panel.trackHover(replacementsShortcut, hovered)
        onClicked: root.panel.replacementsRequested()
    }

    FooterShortcut {
        id: historyShortcut
        shortcut: "t"
        suffix: "ranscripts"
        shortcutColor: root.panel.warning
        foreground: root.panel.dim
        fontFamily: root.panel.fontFamily
        hasCursor: root.panel.cursorOn(historyShortcut)
        enabled: root.panel.voxtype && root.panel.voxtype.history
        onHovered: hovered => root.panel.trackHover(historyShortcut, hovered)
        onClicked: root.panel.openHistory()
    }
}
