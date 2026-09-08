pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "components" as Components

Panel {
    id: root

    moduleName: "io.github.ilyazar.voxtype-control"
    ipcTarget: root.QsWindow.window && root.QsWindow.window.screen ? moduleName + ".editor." + root.QsWindow.window.screen.name : ""

    property bool editingReplacements: false
    readonly property var voxtype: bar && bar.shell ? bar.shell.serviceFor(moduleName) : null
    readonly property color foreground:
        bar && bar.barForeground ? bar.barForeground : Color.foreground
    readonly property color dim: Qt.darker(foreground, 1.55)
    readonly property color urgent: bar && bar.urgent ? bar.urgent : Color.urgent
    readonly property color ready: stateColors.ready
    readonly property color warning: stateColors.warning
    readonly property color statusColor: voxtype && voxtype.dictationState === "recording" ? urgent : voxtype && voxtype.reloading ? warning : voxtype && voxtype.readyFlash ? ready : voxtype && voxtype.dictationState === "transcribing" ? warning : voxtype && voxtype.available ? foreground : dim
    readonly property string statusIcon: voxtype && !voxtype.reloading && voxtype.dictationState === "transcribing" ? "󰔟" : "󰍬"
    readonly property color stateColor: voxtype && voxtype.stateLabel === "Ready" ? ready : foreground

    function launchConfiguration() {
        close();
        if (voxtype)
            Quickshell.execDetached(["omarchy-launch-terminal", "-e", voxtype.controlPath, "configure"]);
    }

    function launchConfigFile() {
        close();
        if (voxtype)
            Quickshell.execDetached([voxtype.controlPath, "edit-config"]);
    }

    function launchReplacements() {
        if (!voxtype || editingReplacements || editorLauncher.running)
            return;
        editingReplacements = true;
        editorLauncher.command = ["omarchy-launch-terminal", "-e", voxtype.controlPath, "edit-replacements", ipcTarget];
        editorLauncher.running = true;
    }

    function open() {
        editingReplacements = false;
        controller.show();
        controlPanel.prepareOpen();
    }

    onOpenedChanged: if (opened)
        controlPanel.prepareOpen()

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    StateColors {
        id: stateColors
    }

    Process {
        id: editorLauncher
        stderr: StdioCollector {
            id: editorErrors
            waitForEnd: true
        }
        onExited: function (code) {
            if (code === 0) {
                if (root.voxtype)
                    root.voxtype.resolveFailure("editor");
                return;
            }
            if (root.voxtype)
                root.voxtype.reportFailure(editorErrors.text || "Could not open replacements editor", "editor");
            root.open();
        }
    }

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
        onPressed: function (mouseButton) {
            hoverTooltip.dismiss();
            if (mouseButton === Qt.RightButton)
                root.launchConfiguration();
            else if (mouseButton === Qt.LeftButton)
                root.toggle();
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

    Components.ControlPanel {
        id: controlPanel
        anchorItem: button
        panelOwner: root
        bar: root.bar
        voxtype: root.voxtype
        editingReplacements: root.editingReplacements
        foreground: root.foreground
        dim: root.dim
        urgent: root.urgent
        ready: root.ready
        warning: root.warning
        statusColor: root.statusColor
        statusIcon: root.statusIcon
        fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
        onCloseRequested: root.close()
        onConfigureRequested: root.launchConfiguration()
        onConfigFileRequested: root.launchConfigFile()
        onReplacementsRequested: root.launchReplacements()
    }
}
