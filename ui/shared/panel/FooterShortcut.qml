import QtQuick
import qs.Commons

Item {
    id: root

    required property string shortcut
    required property string suffix
    required property color shortcutColor
    property color foreground: Color.foreground
    property string fontFamily: Style.font.family
    property bool hasCursor: false
    property var labelVariants: []

    signal clicked
    signal hovered(bool hovered)

    implicitWidth: labelVariants.reduce(function (width, tool) {
        return Math.max(width, Math.ceil(metrics.advanceWidth("[" + tool.toolShortcut + "]"))
            + Math.ceil(metrics.advanceWidth(tool.toolSuffix)));
    }, label.implicitWidth)
    implicitHeight: label.implicitHeight
    opacity: enabled ? 1 : 0.45
    Accessible.role: Accessible.Link
    Accessible.name: shortcut + suffix
    Accessible.description: "Shortcut " + shortcut
    Accessible.onPressAction: if (root.enabled)
        root.clicked()

    FontMetrics {
        id: metrics
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
        font.letterSpacing: 0.8
    }

    Row {
        id: label
        anchors.centerIn: parent

        Text {
            objectName: "shortcutKey"
            text: "[" + root.shortcut + "]"
            textFormat: Text.PlainText
            color: root.shortcutColor
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 0.8
            font.underline: root.hasCursor || hover.hovered
        }

        Text {
            text: root.suffix
            textFormat: Text.PlainText
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 0.8
            font.underline: root.hasCursor || hover.hovered
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: root.hovered(hovered)
    }

    TapHandler {
        enabled: root.enabled
        onTapped: root.clicked()
    }
}
