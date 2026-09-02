import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  property string dictationState: "unavailable"
  property string backend: "unknown"
  property string model: ""
  property string precision: ""
  property string device: ""
  property string language: "auto"
  property var rollbackModels: []
  property bool available: false
  property bool endpointReady: false
  property bool controlAvailable: false
  property bool followerHealthy: false
  property bool metadataReady: false
  property bool busy: false
  property string error: ""

  signal operationFinished(bool success)

  readonly property string controlPath: Quickshell.env("HOME")
    + "/.local/bin/voxtype-control"
  readonly property string configurePath: Quickshell.env("HOME")
    + "/.local/bin/voxtype-configure-launcher"
  readonly property var backendOptions: [
    {
      value: "parakeet",
      label: "Parakeet TDT v3",
      description: "Multilingual local NeMo Speech sidecar"
    },
    {
      value: "canary",
      label: "Canary 1B Flash Q8",
      description: "Automatic or explicit English/German"
    }
  ]
  readonly property string stateLabel:
    dictationState === "recording" ? "Listening"
    : dictationState === "transcribing" ? "Transcribing"
    : dictationState === "idle" ? "Ready"
    : dictationState === "stopped" ? "Stopped"
    : "Unavailable"
  readonly property string backendLabel:
    backend === "parakeet" ? "Parakeet"
    : backend === "canary" ? "Canary"
    : "Unknown backend"
  readonly property string modelLabel: model !== "" ? model : "No model"
  readonly property string tooltip: error !== "" ? error
    : stateLabel + " | " + backendLabel
      + (language !== "" ? " | " + languageLabel(language) : "")
      + "\n" + modelLabel
      + "\nLeft click: controls | Right click: configuration"

  function languageLabel(code) {
    var labels = {
      auto: "Automatic",
      bg: "Bulgarian",
      hr: "Croatian",
      cs: "Czech",
      da: "Danish",
      nl: "Dutch",
      en: "English",
      et: "Estonian",
      fi: "Finnish",
      fr: "French",
      de: "German",
      el: "Greek",
      hu: "Hungarian",
      it: "Italian",
      lv: "Latvian",
      lt: "Lithuanian",
      mt: "Maltese",
      pl: "Polish",
      pt: "Portuguese",
      ro: "Romanian",
      ru: "Russian",
      sk: "Slovak",
      sl: "Slovenian",
      es: "Spanish",
      sv: "Swedish",
      uk: "Ukrainian"
    }
    return labels[String(code)] || String(code).toUpperCase()
  }

  function languageCodesFor(backendName) {
    if (backendName === "canary") return ["auto", "en", "de"]
    if (backendName === "parakeet") return [
      "auto", "en", "de", "ru", "bg", "hr", "cs", "da", "nl",
      "et", "fi", "fr", "el", "hu", "it", "lv", "lt", "mt",
      "pl", "pt", "ro", "sk", "sl", "es", "sv", "uk"
    ]
    return ["auto"]
  }

  function languageOptionsFor(backendName) {
    var codes = languageCodesFor(backendName)
    var options = []
    for (var i = 0; i < codes.length; i++) {
      var code = codes[i]
      var detail = code === "auto"
        ? (backendName === "canary"
          ? "Detect English or German"
          : "Use the model's automatic routing")
        : code.toUpperCase()
      options.push({
        value: code,
        label: languageLabel(code),
        description: detail
      })
    }
    return options
  }

  function updateFollower(raw) {
    try {
      var data = JSON.parse(String(raw || "{}"))
      var next = String(data.alt || data.class || "idle")
      if (["idle", "recording", "transcribing", "stopped"]
          .indexOf(next) === -1)
        next = "idle"
      dictationState = next
      followerHealthy = true
      if (String(data.model || "") !== "") model = String(data.model)
      if (String(data.device || "") !== "") device = String(data.device)
    } catch (parseError) {
      error = "Voxtype returned invalid status data."
    }
  }

  function updateMetadata(raw) {
    var data
    try {
      data = JSON.parse(String(raw || "{}"))
    } catch (parseError) {
      error = "Voxtype control returned invalid metadata."
      metadataReady = false
      return false
    }

    available = data.available === true
    endpointReady = data.endpoint_ready === true
    controlAvailable = data.control_available === true
    backend = String(data.backend || "unknown")
    model = String(data.model || "")
    precision = String(data.precision || "")
    device = String(data.device || "")
    language = String(data.language || "auto")
    rollbackModels = data.rollback_models instanceof Array
      ? data.rollback_models : []
    if (!followerHealthy)
      dictationState = String(data.state || (available ? "stopped" : "unavailable"))
    metadataReady = true
    error = String(data.error || "")
    return true
  }

  function refreshMetadata() {
    if (metadataProcess.running) return
    metadataProcess.command = [controlPath, "status"]
    metadataProcess.running = true
  }

  function applySelection(nextBackend, nextLanguage) {
    if (busy) return false
    busy = true
    error = ""
    applyProcess.command = [
      controlPath, "apply", String(nextBackend), String(nextLanguage)
    ]
    applyProcess.running = true
    return true
  }

  function record(action) {
    if (recordProcess.running || busy) return false
    error = ""
    recordProcess.command = [controlPath, "record", String(action)]
    recordProcess.running = true
    return true
  }

  property Process followerProcess: Process {
    command: ["omarchy-voxtype-status"]
    running: true
    stdout: SplitParser {
      onRead: function(line) { root.updateFollower(line) }
    }
    onExited: function() {
      root.followerHealthy = false
      root.refreshMetadata()
      followerRestart.restart()
    }
  }

  property Timer followerRestart: Timer {
    interval: 5000
    onTriggered: if (!followerProcess.running) followerProcess.running = true
  }

  property Process metadataProcess: Process {
    stdout: StdioCollector {
      id: metadataStdout
      waitForEnd: true
    }
    stderr: StdioCollector {
      id: metadataStderr
      waitForEnd: true
    }
    onExited: function(exitCode) {
      if (exitCode === 0 && root.updateMetadata(metadataStdout.text)) return
      root.metadataReady = false
      root.controlAvailable = false
      root.error = String(metadataStderr.text || "").trim()
        || "Voxtype control is unavailable."
    }
  }

  property Process applyProcess: Process {
    stdout: StdioCollector {
      id: applyStdout
      waitForEnd: true
    }
    stderr: StdioCollector {
      id: applyStderr
      waitForEnd: true
    }
    onExited: function(exitCode) {
      root.busy = false
      if (exitCode === 0 && root.updateMetadata(applyStdout.text)) {
        root.operationFinished(true)
        return
      }
      root.error = String(applyStderr.text || "").trim()
        || "Could not apply the Voxtype selection."
      root.operationFinished(false)
      root.refreshMetadata()
    }
  }

  property Process recordProcess: Process {
    stderr: StdioCollector {
      id: recordStderr
      waitForEnd: true
    }
    onExited: function(exitCode) {
      if (exitCode !== 0)
        root.error = String(recordStderr.text || "").trim()
          || "Could not control recording."
      root.refreshMetadata()
    }
  }

  Component.onCompleted: refreshMetadata()
}
