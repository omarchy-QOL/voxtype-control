import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  property string polledState: "unavailable"
  property string followerState: "unknown"
  property bool followerHealthy: false
  readonly property string dictationState: followerHealthy ? followerState : polledState
  property string modelId: ""
  property string language: ""
  property string hardwareLabel: "GPU unavailable"
  property var modelOptions: []
  readonly property var localModels: modelOptions.filter(function(model) { return model.installed === true })
  property bool endpointReady: false
  property bool loaded: false
  property bool processesActive: false
  property bool operationBusy: false
  property bool downloadBusy: false
  property string operation: ""
  property string reloadState: ""
  readonly property bool reloading: reloadState !== ""
  readonly property bool readyFlash: readyTimer.running && loaded && endpointReady
    && !busy && statusError === ""
  property string error: ""
  property string errorOperation: ""
  property string warning: ""
  property string warningKind: ""
  property string statusError: ""
  property string catalogError: ""
  property int revision: 0
  readonly property string controlPath: Quickshell.env("HOME") + "/.local/bin/voxtype-control"
  readonly property bool busy: applyProcess.running || operationBusy || downloadBusy
  readonly property bool dictating: ["recording", "transcribing", "streaming", "eager_recording"].indexOf(dictationState) !== -1
  readonly property bool available: statusError === "" && modelOptions.length > 0
  readonly property bool controlAvailable: available && catalogError === ""
  readonly property string modelLabel: !loaded ? "No model" : modelFor(modelId) ? modelFor(modelId).label : "Unknown model"
  readonly property string message: statusError || catalogError || error || warning
  readonly property bool messageIsWarning: !statusError && !catalogError && !error && warning !== ""
  readonly property string stateLabel: busy ? (downloadBusy || (applyProcess.running && operation === "download") ? "Installing" : "Switching")
    : dictationState === "recording" ? "Listening"
    : dictationState === "transcribing" ? "Transcribing"
    : dictationState === "streaming" ? "Streaming"
    : !processesActive ? "Unloaded"
    : endpointReady ? "Ready" : "Unavailable"

  signal metadataUpdated()
  signal actionFinished(string action, bool success)

  function cleanError(raw) {
    return String(raw || "").trim().replace(/^(?:(?:Error|voxtype-control):\s*)+/i, "")
  }

  function clearWarning() {
    warning = ""
    warningKind = ""
    warningTimer.stop()
  }

  function warn(text, kind) {
    warning = text
    warningKind = kind || ""
    warningTimer.restart()
  }

  function reportFailure(raw, action) {
    var text = cleanError(raw) || "Operation failed"
    if (text === "Finish dictation before switching models")
      warn("Stop dictation before applying changes.", "dictation")
    else if (text === "Voxtype is busy switching or recording")
      warn("Voxtype is busy. Try again when it is ready.", "busy")
    else { error = text; errorOperation = action || operation }
  }

  function resolveFailure(action) {
    var runtimeActions = ["apply", "unload"]
    if (errorOperation === action || (runtimeActions.indexOf(action) !== -1
        && runtimeActions.indexOf(errorOperation) !== -1)) {
      error = ""
      errorOperation = ""
    }
  }

  function finishAction(success, raw) {
    revision++
    if (operation === "apply") reloadState = success ? "checking" : ""
    if (!success) reportFailure(raw, operation)
    else {
      resolveFailure(operation)
      clearWarning()
    }
    actionFinished(operation, success)
  }

  onDictatingChanged: if (!dictating && warningKind === "dictation") clearWarning()

  property Timer warningTimer: Timer {
    interval: 10000
    onTriggered: root.clearWarning()
  }

  property Timer readyTimer: Timer { interval: 1000 }

  function modelFor(identity) {
    for (var i = 0; i < modelOptions.length; i++)
      if (modelOptions[i].value === identity) return modelOptions[i]
    return null
  }

  function languageOptionsFor(identity) {
    var entry = modelFor(identity)
    return entry ? entry.codes.map(function(code) {
      return { value: code, label: code === "auto" ? "Automatic"
        : code === "en" ? "English" : code === "de" ? "German" : code.toUpperCase() }
    }) : []
  }

  function defaultLanguageFor(identity) {
    var entry = modelFor(identity)
    if (!entry) return ""
    if (identity === modelId && entry.codes.indexOf(language) !== -1) return language
    return entry.codes.length === 1 ? entry.codes[0]
      : entry.codes.indexOf("auto") !== -1 ? "auto" : ""
  }

  function updateStatus(raw) {
    var data = JSON.parse(String(raw))
    if (data.schema !== 4) throw new Error("Install the current Voxtype helper")
    modelId = String(data.model_id || "")
    language = String(data.language || "")
    polledState = String(data.state || "unknown")
    endpointReady = data.endpoint_ready === true
    loaded = data.loaded === true
    processesActive = data.processes_active === true
    operationBusy = data.busy === true
    var wasDownloading = downloadBusy
    downloadBusy = data.download_busy === true
    if (wasDownloading && !downloadBusy) refreshMetadata()
    statusError = ""
    if (reloading && !busy) {
      if (reloadState === "checking" && loaded && endpointReady) readyTimer.restart()
      reloadState = ""
    }
    metadataUpdated()
  }

  function refreshStatus() {
    if (statusProcess.running) return
    statusProcess.epoch = revision
    statusProcess.running = true
  }

  function updateFollower(raw) {
    try {
      var state = JSON.parse(String(raw)).alt
      followerHealthy = typeof state === "string" && state !== ""
      followerState = followerHealthy ? state : "unknown"
    } catch (error) { followerHealthy = false }
  }

  function refreshMetadata() {
    if (!catalogProcess.running) catalogProcess.running = true
    if (!hardwareProcess.running) hardwareProcess.running = true
    refreshStatus()
  }

  function updateHardware(raw) {
    var data = JSON.parse(String(raw))
    if (data.schema !== 4 || !Array.isArray(data.gpus)
        || data.gpus.some(function(name) { return typeof name !== "string" || !name.trim() })
        || typeof data.preferred_gpu !== "string")
      throw new Error("Invalid GPU inventory")
    var match = data.preferred_gpu.trim().toLowerCase()
    var matches = match ? data.gpus.filter(function(name) {
      return name.toLowerCase().indexOf(match) !== -1
    }) : data.gpus
    hardwareLabel = matches.length === 1 ? matches[0]
      : data.gpus.length === 0 ? "No GPU detected"
      : match && matches.length === 0 ? "Configured GPU not found"
      : data.gpus.length + " GPUs (selection unclear)"
  }

  function request(argv) {
    if (busy) { warn("Voxtype is busy. Try again when it is ready.", "busy"); return }
    if (dictating && ["apply", "unload"].indexOf(argv[0]) !== -1) {
      warn("Stop dictation before applying changes.", "dictation")
      return
    }
    revision++
    clearWarning()
    operation = argv[0]
    readyTimer.stop()
    reloadState = operation === "apply" ? "loading" : ""
    applyProcess.command = [controlPath].concat(argv)
    applyProcess.running = true
  }

  function applySelection(identity, language) { request(["apply", identity, language]) }
  function unload() { request(["unload"]) }

  property Timer poll: Timer {
    interval: root.busy ? 500 : 5000
    running: true
    repeat: true
    onTriggered: {
      root.refreshStatus()
      if (root.catalogError && !root.catalogProcess.running) root.catalogProcess.running = true
      if (!root.follower.running) root.follower.running = true
    }
  }
  property Process follower: Process {
    command: ["omarchy-voxtype-status"]
    running: true
    stdout: SplitParser {
      onRead: function(line) { root.updateFollower(line) }
    }
    onExited: root.followerHealthy = false
  }
  property Process statusProcess: Process {
    property int epoch: 0
    command: [root.controlPath, "status"]
    stdout: StdioCollector { id: statusOutput; waitForEnd: true }
    stderr: StdioCollector { id: statusErrors; waitForEnd: true }
    onExited: function(code) {
      // Completion needs a fresh observation, not an in-flight loading poll.
      if (epoch !== root.revision) { root.refreshStatus(); return }
      try {
        if (code !== 0) throw new Error(String(statusErrors.text).trim())
        root.updateStatus(statusOutput.text)
      } catch (failure) {
        root.statusError = root.cleanError(failure)
        if (!root.busy) root.reloadState = ""
      }
    }
  }
  property Process catalogProcess: Process {
    command: [root.controlPath, "list"]
    stdout: StdioCollector { id: catalogOutput; waitForEnd: true }
    stderr: StdioCollector { id: catalogErrors; waitForEnd: true }
    onExited: function(code) {
      try {
        if (code !== 0) throw new Error(String(catalogErrors.text).trim())
        var entries = JSON.parse(String(catalogOutput.text))
        if (!(entries instanceof Array)) throw new Error("Invalid model catalog")
        root.modelOptions = entries
        root.catalogError = ""
        root.metadataUpdated()
      } catch (failure) { root.catalogError = root.cleanError(failure) }
    }
  }
  property Process hardwareProcess: Process {
    command: [root.controlPath, "hardware"]
    stdout: StdioCollector { id: hardwareOutput; waitForEnd: true }
    stderr: StdioCollector { id: hardwareErrors; waitForEnd: true }
    onExited: function(code) {
      try {
        if (code !== 0) throw new Error(String(hardwareErrors.text).trim())
        root.updateHardware(hardwareOutput.text)
      } catch (failure) {
        root.hardwareLabel = "GPU unavailable"
        console.warn("Voxtype hardware:", root.cleanError(failure))
      }
    }
  }
  property Process applyProcess: Process {
    stderr: StdioCollector { id: applyErrors; waitForEnd: true }
    onExited: function(code) {
      root.operationBusy = false
      root.downloadBusy = false
      root.finishAction(code === 0, applyErrors.text)
      if (root.operation === "download") {
        root.refreshMetadata()
      } else root.refreshStatus()
    }
  }

  Component.onCompleted: refreshMetadata()
}
