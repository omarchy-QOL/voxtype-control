import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

PopupWindow {
  id: root
  required property Item anchorItem
  required property var bar
  property alias model: content.model
  property alias stateLabel: content.stateLabel
  property alias stateColor: content.stateColor
  property alias fontFamily: content.fontFamily
  property bool hovered: false
  property bool ready: false
  property bool suppressed: false
  readonly property var anchorWindow: anchorItem.QsWindow.window

  function dismiss() { suppressed = true }
  onHoveredChanged: { ready = false; suppressed = false }
  visible: !!anchorWindow && hovered && ready && !suppressed
  color: "transparent"
  implicitWidth: content.implicitWidth + 2 * Style.space(10)
  implicitHeight: content.implicitHeight + 2 * Style.space(7)

  Timer {
    interval: 400
    running: root.hovered && !root.suppressed
    onTriggered: root.ready = true
  }

  // PopupAnchor is absent from the installed Quickshell type metadata.
  // qmllint disable missing-type unresolved-type
  anchor {
    window: root.anchorWindow
    adjustment: PopupAdjustment.Slide
    edges: Edges.Top | Edges.Left
    gravity: Edges.Bottom | Edges.Right
    rect.width: 1
    rect.height: 1
    onAnchoring: {
      if (!root.anchorWindow || !root.bar) return
      var target = root.anchorItem
      var x = target.width / 2 - root.implicitWidth / 2
      var y = target.height + Style.space(6)
      if (root.bar.position === "bottom") y = -root.implicitHeight - Style.space(6)
      else if (root.bar.position === "left") {
        x = target.width + Style.space(6)
        y = target.height / 2 - root.implicitHeight / 2
      } else if (root.bar.position === "right") {
        x = -root.implicitWidth - Style.space(6)
        y = target.height / 2 - root.implicitHeight / 2
      }
      var point = root.anchorWindow.contentItem.mapFromItem(target, x, y)
      root.anchor.rect.x = Math.round(point.x)
      root.anchor.rect.y = Math.round(point.y)
    }
  }
  // qmllint enable missing-type unresolved-type

  BorderSurface {
    anchors.fill: parent
    color: Color.tooltip.background
    borderSpec: Border.surfaceSpec("tooltip", "border", Color.tooltip.border, Style.normalBorderWidth)
    radius: Style.cornerRadius
  }

  TooltipContent {
    id: content
    x: Style.space(10)
    y: Style.space(7)
  }
}
