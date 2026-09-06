import QtQuick
import QtTest
import qs.Commons
import qs.Ui
import "../.." as Plugin

TestCase {
  id: test
  name: "DropdownBinding"
  when: true
  width: 360
  height: 160
  property bool keyboardCursor: false
  property string selection: ""
  property int passed: 0
  property int unloadCalls: 0
  property int underlyingActivations: 0
  property int statusRefreshes: 0
  property alias fixtureService: service
  property var controlRows: [[dropdown, notice], [tooltip]]
  readonly property var actions: [].concat.apply([], controlRows)

  Plugin.ApplySelectionButton {
    id: applyButton
    visible: false
    width: 400
    label: "Load STT model / Apply language selection"
    foreground: "#eeeeee"
    checkColor: "#00ff00"
    busyColor: colors.warning
  }

  Plugin.StateColors { id: colors; theme.path: "" }
  Plugin.ReloadIcon {
    id: reloadIcon
    width: 18
    height: 18
    text: "󰍬"
    pulsing: service.reloading
    color: service.reloading ? colors.warning
      : service.readyFlash ? colors.ready : "#eeeeee"
  }
  Plugin.TooltipContent {
    id: tooltip
    visible: false
    model: "Parakeet TDT v3 FP16"
    stateLabel: "Ready"
    stateColor: colors.ready
  }

  Plugin.Service {
    id: service
    follower.running: false
    poll.running: false
    function refreshMetadata() {}
    function refreshStatus() { test.statusRefreshes++ }
    function unload() { test.unloadCalls++ }
  }

  PanelKeyCatcher {
    width: 320
    blocked: unloadPicker.active
    onActivateRequested: test.underlyingActivations++
    Loader {
      id: unloadPicker
      active: false
      width: item ? Math.min(Style.space(440), item.implicitWidth) : 320
      sourceComponent: Component {
        Plugin.UnloadModel {
          service: test.fixtureService
          onCancelled: unloadPicker.active = false
        }
      }
    }
  }

  Plugin.NoticeSection {
    id: notice
    width: 320
    message: service.message
    warning: service.messageIsWarning
    warningColor: colors.warning
  }

  Plugin.GuardedSearchableDropdown {
    id: dropdown
    width: 300
    label: "Models"
    options: ["one", "two"]
    selectedValue: test.selection
    onChanged: function(value) { test.selection = value }
    hasCursor: test.keyboardCursor
  }


  function test_hover_preserves_keyboard_binding() {
    wait(50)
    keyboardCursor = false
    mouseMove(dropdown, 20, dropdown.height - 10)
    mouseMove(test, 340, 140)
    keyboardCursor = true
    compare(dropdown.hasCursor, true)
    keyboardCursor = false
    compare(dropdown.hasCursor, false)
    passed++
  }

  function test_follower_wins_over_older_poll() {
    service.updateFollower('{"alt":"recording"}')
    service.updateStatus('{"schema":4,"state":"idle"}')
    compare(service.dictationState, "recording")
    service.followerHealthy = false
    compare(service.dictationState, "idle")
    passed++
  }

  function test_open_focuses_search_for_typing_data() {
    return [
      {tag: "model", options: ["Parakeet", "Canary"], key: Qt.Key_C, match: "Canary"},
      {tag: "language", options: ["English", "German"], key: Qt.Key_R, match: "German"}
    ]
  }

  function test_open_focuses_search_for_typing(data) {
    dropdown.options = data.options
    dropdown.open()
    tryCompare(dropdown, "popupOpen", true)
    wait(0)
    keyClick(data.key)
    tryCompare(dropdown, "filtered", [data.match])
    keyClick(Qt.Key_Q)
    tryCompare(dropdown, "filtered", [])
    compare(dropdown.popupOpen, true)
    dropdown.close()
    tryCompare(dropdown, "popupOpen", false)
    wait(0)
    passed++
  }

  function cleanupTestCase() {
    if (passed === 19) console.log("VOXTYPE_QML_TESTS_PASSED")
    else console.error("VOXTYPE_QML_TESTS_FAILED: " + passed)
  }

  function test_selection_stays_bound_after_selecting_then_reopening_data() {
    return [
      {tag: "model", before: "Parakeet", after: "Canary", key: Qt.Key_C},
      {tag: "language", before: "Automatic", after: "German", key: Qt.Key_G}
    ]
  }

  function test_selection_stays_bound_after_selecting_then_reopening(data) {
    dropdown.options = [data.before, data.after]
    for (var i = 0; i < 3; i++) {
      selection = data.before
      dropdown.open()
      wait(0)
      keyClick(data.key)
      keyClick(Qt.Key_Return)
      compare(selection, data.after)
      selection = data.before
      compare(dropdown.value, data.before)
      selection = ""
      compare(dropdown.value, "")
      selection = data.after
      compare(dropdown.value, data.after)
    }
    passed++
  }

  function test_reload_feedback_waits_for_fresh_ready_and_expires() {
    service.readyTimer.stop()
    service.operation = "apply"
    service.operationBusy = true
    service.reloadState = "loading"
    service.followerHealthy = false
    service.updateStatus('{"schema":4,"loaded":true,"endpoint_ready":true,"busy":true}')
    verify(service.reloading)
    compare(reloadIcon.color, colors.warning)
    service.statusProcess.epoch = service.revision
    service.operationBusy = false
    service.finishAction(true, "")
    var refreshes = statusRefreshes
    service.statusProcess.exited(0, 0)
    compare(statusRefreshes, refreshes + 1)
    verify(service.reloading)
    verify(!service.readyFlash)
    service.updateStatus('{"schema":4,"state":"idle","loaded":true,"endpoint_ready":true,"processes_active":true}')
    verify(!service.reloading)
    verify(service.readyFlash)
    compare(reloadIcon.color, colors.ready)
    compare(service.stateLabel, "Ready")
    compare(service.busy, false)
    compare(service.controlAvailable, true)
    compare(service.readyTimer.interval, 1000)
    wait(250)
    verify(service.readyFlash)
    tryCompare(service, "readyFlash", false, 1500)
    compare(String(reloadIcon.color), "#eeeeee")
    passed++
  }

  function test_reload_failures_and_unload_do_not_flash_success() {
    service.readyTimer.stop()
    service.operation = "apply"
    service.reloadState = "loading"
    service.finishAction(false, "Load failed")
    compare(service.reloading, false)
    service.updateStatus('{"schema":4,"state":"idle","loaded":true,"endpoint_ready":true}')
    compare(service.readyFlash, false)
    service.resolveFailure("apply")
    service.reloadState = "loading"
    service.updateStatus('{"schema":4,"state":"idle","loaded":true,"endpoint_ready":true}')
    compare(service.readyFlash, false)
    service.reloadState = "loading"
    service.finishAction(true, "")
    service.updateStatus('{"schema":4,"state":"stopped","loaded":false,"endpoint_ready":false}')
    compare(service.reloading, false)
    compare(service.readyFlash, false)
    service.operation = "unload"
    service.finishAction(true, "")
    compare(service.readyFlash, false)
    passed++
  }

  function test_reload_pulse_repeats_and_resets_without_changing_glyph() {
    service.readyTimer.stop()
    for (var duration of [150, 750, 1200]) {
      service.reloadState = "loading"
      wait(duration)
      verify(reloadIcon.scale > 1 && reloadIcon.scale <= 1.08)
      verify(reloadIcon.opacity >= 0.75 && reloadIcon.opacity <= 1)
      compare(reloadIcon.text, "󰍬")
      service.reloadState = ""
      compare(reloadIcon.scale, 1)
      compare(reloadIcon.opacity, 1)
    }
    var glyph = reloadIcon.children[0]
    compare(glyph.renderType, Text.CurveRendering)
    passed++
  }

  TextMetrics {
    id: reloadMetrics
    text: reloadIcon.text
    font: reloadIcon.children[0].font
  }

  function test_reload_glyph_is_optically_centered_at_both_icon_sizes() {
    service.reloadState = ""
    var glyph = reloadIcon.children[0]
    for (var size of [10, 13]) {
      reloadIcon.fontSize = size
      wait(0)
      var center = glyph.x + reloadMetrics.tightBoundingRect.x
        + reloadMetrics.tightBoundingRect.width / 2
      verify(Math.abs(center - reloadIcon.width / 2) < 0.01)
    }
    reloadIcon.fontSize = 13
    passed++
  }

  function test_qml_navigation_array_and_object_identity() {
    compare(actions.length, 3)
    compare(actions[0], dropdown)
    compare(actions[1], notice)
    compare(controlRows[1].indexOf(actions[2]), 0)
    passed++
  }

  function test_apply_label_and_check_have_independent_colours() {
    var row = applyButton.children[applyButton.children.length - 1]
    compare(String(row.children[0].color), "#00ff00")
    compare(String(row.children[1].color), "#eeeeee")
    compare(row.children[1].horizontalAlignment, Text.AlignLeft)
    verify(row.x < applyButton.width / 4)
    applyButton.enabled = false
    compare(String(row.children[0].color), "#eeeeee")
    passed++
  }

  function test_busy_warning_survives_failed_process_exit() {
    service.operationBusy = true
    service.reportFailure("voxtype-control: Voxtype is busy switching or recording", "apply")
    service.operationBusy = false
    compare(service.warningKind, "busy")
    compare(service.messageIsWarning, true)
    service.clearWarning()
    passed++
  }

  function test_checkmark_resets_after_spinner_stops() {
    var row = applyButton.children[applyButton.children.length - 1]
    var icon = row.children[0]
    applyButton.visible = true
    for (var duration of [110, 230, 410]) {
      applyButton.spinning = true
      colors.load('yellow = "#abcdef"')
      compare(icon.color, colors.warning)
      colors.load('color3 = "#fedcba"')
      compare(icon.color, colors.warning)
      wait(duration)
      verify(icon.rotation > 0)
      applyButton.spinning = false
      compare(icon.rotation, 0)
      compare(icon.text, "󰄬")
      wait(50)
      compare(icon.rotation, 0)
    }
    applyButton.visible = false
    passed++
  }

  function test_confirmation_width_tracks_prompt_and_caps_long_names() {
    service.modelId = "sizing"
    service.loaded = true
    service.modelOptions = [{value: "sizing", label: "Q8"}]
    unloadPicker.active = true
    wait(0)
    var content = unloadPicker.item.children[0]
    var question = content.children[0]
    var buttons = content.children[1]
    compare(unloadPicker.width, Style.space(160))
    service.modelOptions = [{value: "sizing", label: "Parakeet TDT v3 FP16"}]
    wait(0)
    compare(unloadPicker.width, Math.ceil(question.implicitWidth))
    compare(buttons.width, Math.ceil(question.implicitWidth))
    compare(buttons.children[0].width, buttons.children[1].width)
    service.modelOptions = [{value: "sizing", label: "A very long model name ".repeat(8)}]
    wait(0)
    compare(unloadPicker.width, Style.space(440))
    compare(question.wrapMode, Text.NoWrap)
    compare(question.elide, Text.ElideRight)
    verify(question.height < question.font.pixelSize * 2)
    unloadPicker.active = false
    passed++
  }

  function test_unload_confirmation_uses_runtime_model() {
    service.modelOptions = [{value: "active", label: "Canary Q8"}]
    service.modelId = "active"
    service.loaded = true
    service.polledState = "idle"
    unloadPicker.active = true
    wait(0)
    compare(unloadPicker.item.prompt, "Unload Canary Q8?")
    compare(unloadPicker.item.choice, 1)
    keyClick(Qt.Key_Return)
    compare(unloadPicker.active, false)
    compare(unloadCalls, 0)
    compare(underlyingActivations, 0)
    unloadPicker.active = true
    wait(0)
    keyClick(Qt.Key_H)
    compare(unloadPicker.item.choice, 0)
    keyClick(Qt.Key_Return)
    compare(unloadCalls, 1)
    service.actionFinished("unload", true)
    compare(unloadPicker.active, false)
    unloadPicker.active = true
    wait(0)
    keyClick(Qt.Key_Q)
    compare(unloadPicker.active, false)
    passed++
  }

  function test_notice_lifecycle() {
    service.warningTimer.interval = 50
    service.followerHealthy = false
    service.polledState = "recording"
    service.request(["apply", "fixture", "auto"])
    compare(service.warningKind, "dictation")
    compare(service.applyProcess.running, false)
    compare(notice.warning, true)
    service.polledState = "idle"
    compare(service.warning, "")
    service.warn("Temporary warning", "")
    tryCompare(service, "warning", "")
    service.reportFailure("voxtype-control: voxtype-control: Missing model", "apply")
    compare(notice.message, "Missing model")
    compare(notice.warning, false)
    wait(100)
    service.updateStatus('{"schema":4,"state":"idle","endpoint_ready":true}')
    compare(service.error, "Missing model")
    service.operation = "apply"
    service.finishAction(true, "")
    compare(service.message, "")
    compare(notice.visible, false)
    passed++
  }

  function test_tooltip_layout_and_theme_colours() {
    colors.load('color2 = "#112233"\nyellow = "#445566"\ngreen = "#778899"')
    compare(String(colors.ready), "#778899")
    compare(String(colors.warning), "#445566")
    wait(0)
    var left = tooltip.children[0]
    var hints = tooltip.children[1]
    compare(left.children[0].text, tooltip.model)
    compare(left.children[1].text, tooltip.stateLabel)
    compare(left.children[1].color, colors.ready)
    compare(left.children[0].x, left.children[1].x)
    compare(left.y, hints.y)
    verify(hints.x >= left.x + left.width + tooltip.spacing)
    compare(hints.text, "L-click: Menu\nR-click:  TUI")
    compare(hints.horizontalAlignment, Text.AlignRight)
    colors.load('color2 = "#abcdef"\ncolor3 = "#fedcba"')
    compare(String(colors.ready), "#abcdef")
    compare(String(colors.warning), "#fedcba")
    tooltip.stateLabel = "Switching"
    tooltip.stateColor = colors.warning
    compare(left.children[1].text, "Switching")
    compare(left.children[1].color, colors.warning)
    passed++
  }

  function test_hardware_survives_all_model_transitions() {
    service.modelOptions = [{value: "test", label: "Test model"}]
    service.updateHardware('{"schema":4,"gpus":["Intel","AMD Radeon RX 6400"],"preferred_gpu":"RX 6400"}')
    for (var state of ["stopped", "loading", "idle", "recording", "failed", "idle"]) {
      service.updateStatus(JSON.stringify({schema: 4, state: state,
        loaded: state !== "stopped" && state !== "failed", execution_device: null}))
      compare(service.hardwareLabel, "AMD Radeon RX 6400")
      compare(service.hardwareProcess.running, false)
    }
    service.statusError = "Status unavailable"
    compare(service.hardwareLabel, "AMD Radeon RX 6400")
    service.statusError = ""
    service.updateHardware('{"schema":4,"gpus":["Intel"],"preferred_gpu":""}')
    compare(service.hardwareLabel, "Intel")
    service.updateHardware('{"schema":4,"gpus":["Intel","AMD"],"preferred_gpu":""}')
    compare(service.hardwareLabel, "2 GPUs (selection unclear)")
    service.hardwareProcess.exited(1, 0)
    compare(service.hardwareLabel, "GPU unavailable")
    compare(service.controlAvailable, true)
    service.updateHardware('{"schema":4,"gpus":["Intel"],"preferred_gpu":""}')
    compare(service.hardwareLabel, "Intel")
    passed++
  }
}
