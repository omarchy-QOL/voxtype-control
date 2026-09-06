import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "." as Plugin

// Stage beside Service.qml and NoticeSection.qml, with the installed qs imports.
ShellRoot {
  Plugin.Service {
    id: service
    follower.running: false
    poll.running: false
    function refreshMetadata() {}
  }
  Plugin.StateColors { id: colors }

  FloatingWindow {
    visible: true
    title: "Voxtype notice test - simulated, no model changes"
    implicitWidth: 460
    implicitHeight: 300
    color: Color.popups.background
    Column {
      focus: true
      Keys.onEscapePressed: Qt.quit()
      anchors.fill: parent
      anchors.margins: 20
      spacing: 14
      Text {
        text: "Voxtype notice test"
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.title
        font.bold: true
      }
      Text {
        width: parent.width
        text: "Simulated failures. Your running model is untouched.\nWarning expires after 10 seconds; Error stays until Resolve."
        wrapMode: Text.WordWrap
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
      }
      PanelSeparator {}
      Plugin.NoticeSection {
        width: parent.width
        message: service.message
        warning: service.messageIsWarning
        warningColor: colors.warning
      }
      Row {
        spacing: 10
        Button {
          text: "Warning"
          bordered: true
          onClicked: {
            service.resolveFailure("apply")
            service.polledState = "recording"
            service.reportFailure("voxtype-control: Finish dictation before switching models", "apply")
          }
        }
        Button {
          text: "Error"
          bordered: true
          onClicked: {
            service.polledState = "idle"
            service.reportFailure("voxtype-control: voxtype-control: Model could not be loaded (test)", "apply")
          }
        }
        Button {
          text: "Resolve"
          bordered: true
          onClicked: {
            service.polledState = "idle"
            service.operation = "apply"
            service.finishAction(true, "")
          }
        }
        Button {
          text: "Close"
          bordered: true
          onClicked: Qt.quit()
        }
      }
    }
  }
}
