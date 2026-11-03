import assert from "node:assert/strict";
import fs from "node:fs";
import vm from "node:vm";

const source = fs.readFileSync(new URL("../services/ModelControlService.qml", import.meta.url), "utf8");
const context = vm.createContext({ metadataUpdated() {}, refreshMetadata() {},
  applyProcess: {}, busy: false, dictating: false, downloadBusy: false, followerHealthy: false, revision: 0,
  warningTimer: { restart() {}, stop() {} }, actionFinished() {}, errorOperation: "",
  reloadState: "", readyTimer: { restart() {}, stop() {} },
  recordingFailureTimer: { running: false, restart() { this.running = true; } },
  modelOptions: [
    { value: "parakeet", codes: ["auto"], reason: "" },
    { value: "canary", codes: ["en", "de"], reason: "" },
    { value: "moonshine", codes: ["ja"], reason: "" }
  ], modelId: "", language: "", backend: "voxtype", controlPath: "/test/dictation-control" });
for (const name of ["modelFor", "languageOptionsFor", "defaultLanguageFor", "updateStatus", "updateHardware", "updateFollower",
  "request", "useBackend", "selectBackend", "cleanError", "clearWarning", "warn", "showRecordingFailure", "reportFailure", "resolveFailure", "finishAction"]) {
  const code = source.match(new RegExp(`  function ${name}\\([^]*?\\n  \\}`))?.[0];
  assert.ok(code, name);
  vm.runInContext(code, context);
}
Object.defineProperty(context, "reloading", {get: () => context.reloadState !== ""});
Object.defineProperty(context, "recordingFailure", {get: () => context.recordingFailureTimer.running});
context.Qt = { callLater(callback) { callback(); } };
context.follower = { running: true };
context.refreshMetadata = () => { context.metadataRefreshes = (context.metadataRefreshes || 0) + 1; };
assert.equal(context.defaultLanguageFor("parakeet"), "auto");
assert.equal(context.defaultLanguageFor("canary"), "");
assert.equal(context.defaultLanguageFor("moonshine"), "ja");
assert.equal(context.defaultLanguageFor("missing"), "");
context.updateStatus(JSON.stringify({ schema: 5, backend: "voxtype", model_id: "canary", language: "de",
  state: "streaming", endpoint_ready: true, loaded: true, processes_active: true }));
assert.equal(context.polledState, "streaming");
context.updateHardware('{"schema":5,"gpus":["Intel","AMD Radeon RX 6400"],"preferred_gpu":"RX 6400"}');
context.updateStatus('{"schema":5,"backend":"voxtype","loaded":true}');
assert.equal(context.hardwareLabel, "AMD Radeon RX 6400");
context.updateStatus('{"schema":5,"backend":"voxtype","loaded":false}');
assert.equal(context.hardwareLabel, "AMD Radeon RX 6400");
assert.equal(vm.runInContext(source.match(/readonly property string modelLabel: (.*)/)[1], context), "No model");
context.updateStatus('{"schema":5,"backend":"voxtype","loaded":true,"execution_device":null}');
assert.equal(context.hardwareLabel, "AMD Radeon RX 6400");
context.updateFollower('{"alt":"recording"}');
context.updateStatus('{"schema":5,"backend":"voxtype","state":"idle","model_id":"canary","language":"de"}');
assert.equal(context.followerState, "recording");
assert.equal(context.followerHealthy, true);
assert.equal(context.polledState, "idle");
context.updateFollower('invalid JSON');
assert.equal(context.followerHealthy, false);
assert.equal(context.defaultLanguageFor("canary"), "de");
assert.throws(() => context.updateStatus('{"schema":2}'));
assert.throws(() => context.updateStatus('{"schema":3}'));
assert.throws(() => context.updateHardware('{"schema":3,"gpus":[]}'));
assert.throws(() => context.updateHardware('{"schema":5,"gpus":null,"preferred_gpu":""}'));
assert.throws(() => context.updateHardware('{"schema":5,"gpus":[""],"preferred_gpu":""}'));
for (const [gpus, preference, expected] of [
  [["Intel", "AMD Radeon RX 6400"], "", "2 GPUs (selection unclear)"],
  [["AMD Radeon RX 6400", "AMD Radeon RX 6400"], "RX 6400", "2 GPUs (selection unclear)"],
  [["Intel"], "RX 6400", "Configured GPU not found"],
  [["Intel"], "", "Intel"],
  [[], "", "No GPU detected"],
  [["Intel", "AMD Radeon RX 6400"], "rx 6400", "AMD Radeon RX 6400"],
]) {
  context.updateHardware(JSON.stringify({schema: 5, gpus, preferred_gpu: preference}));
  assert.equal(context.hardwareLabel, expected);
}
context.error = "previous error";
context.errorOperation = "apply";
context.request(["apply", "canary", "en"]);
assert.equal(context.error, "previous error");
assert.equal(context.applyProcess.running, true);
assert.equal(context.applyProcess.command.join(" "), "/test/dictation-control apply canary en");
assert.equal(context.revision, 1);
context.finishAction(true, "");
assert.equal(context.error, "");
context.applyProcess.running = false;
context.dictating = true;
context.request(["apply", "canary", "en"]);
assert.equal(context.warning, "Stop dictation before applying changes.");
assert.equal(context.applyProcess.running, false);
context.dictating = false;
context.reportFailure("Error: dictation-control: voxtype-control: Finish dictation before switching models", "apply");
assert.equal(context.warningKind, "dictation");
assert.equal(context.error, "");
context.showRecordingFailure("Selected microphone jack is disconnected");
assert.equal(context.warning, "Selected microphone jack is disconnected");
assert.equal(context.warningKind, "recording");
assert.equal(context.recordingFailure, true);
context.clearWarning();
context.reportFailure("dictation-control: voxtype-control: Missing model", "download");
assert.equal(context.error, "Missing model");
context.operation = "apply";
context.finishAction(true, "");
assert.equal(context.error, "Missing model");
context.operation = "download";
context.finishAction(true, "");
assert.equal(context.error, "");

const widget = fs.readFileSync(new URL("../BarWidget.qml", import.meta.url), "utf8");
const controls = ["ControlPanel", "Body", "Footer"].map((name) => fs.readFileSync(
  new URL(`../ui/shared/panel/${name}.qml`, import.meta.url), "utf8").replace(/root\.panel\./g, "root."))
  .join("\n");
const statusHeader = fs.readFileSync(
  new URL("../ui/shared/panel/Header.qml", import.meta.url), "utf8");
function qmlFunction(source, name) {
  const start = source.indexOf(`function ${name}(`);
  assert.notEqual(start, -1, name);
  const open = source.indexOf("{", start);
  let depth = 0;
  for (let index = open; index < source.length; index++) {
    if (source[index] === "{") depth++;
    if (source[index] === "}" && --depth === 0) return source.slice(start, index + 1);
  }
  throw new Error(`Unclosed QML function: ${name}`);
}
const condition = controls.match(/readonly property bool canApply: (.*)/)[1];
const panel = vm.createContext({ voxtype: { controlAvailable: true, busy: false, dictating: false,
  loaded: true, endpointReady: true, modelId: "canary", language: "en", errorOperation: "" },
  selectedModel: { codes: ["en", "de"], reason: "" }, draftModelId: "canary", draftLanguage: "" });
panel.root = panel;
assert.equal(vm.runInContext(condition, panel), false);
panel.draftLanguage = "de";
assert.equal(vm.runInContext(condition, panel), true);
panel.draftLanguage = "en";
assert.equal(vm.runInContext(condition, panel), false);
panel.draftModelId = "parakeet";
assert.equal(vm.runInContext(condition, panel), true);
panel.draftModelId = "canary";
panel.voxtype.loaded = false;
assert.equal(vm.runInContext(condition, panel), true);
panel.voxtype.loaded = true;
panel.voxtype.endpointReady = false;
assert.equal(vm.runInContext(condition, panel), true);
panel.voxtype.endpointReady = true;
panel.voxtype.errorOperation = "apply";
assert.equal(vm.runInContext(condition, panel), true);
panel.voxtype.dictating = true;
assert.equal(vm.runInContext(condition, panel), false);
panel.voxtype.dictating = false;
panel.voxtype.errorOperation = "";
panel.draftLanguage = "de";
panel.voxtype.language = "de";
assert.equal(vm.runInContext(condition, panel), false);
panel.voxtype.language = "en";
panel.selectedModel.reason = "Missing model";
assert.equal(vm.runInContext(condition, panel), false);
assert.ok(!source.includes("pendingOperation"));
const submitted = [];
panel.voxtype.applySelection = (id, language) => submitted.push([id, language]);
Object.defineProperty(panel, "canApply", {get: () => vm.runInContext(condition, panel)});
vm.runInContext(qmlFunction(controls, "applyDraft"), panel);
panel.selectedModel.reason = "";
panel.voxtype.modelId = "parakeet";
panel.voxtype.language = "auto";
panel.draftModelId = "canary";
for (const loaded of [false, true, false, true]) {
  panel.voxtype.loaded = loaded;
  panel.draftLanguage = "";
  const before = submitted.length;
  panel.applyDraft();
  assert.equal(submitted.length, before);
  panel.draftLanguage = "de";
  panel.applyDraft();
  assert.deepEqual(submitted.at(-1), ["canary", "de"]);
}
assert.ok(!controls.includes("recover"));
assert.ok(!controls.includes("Language is controlled by this model."));
assert.ok(!controls.includes("Choose the language you are speaking."));
assert.ok(controls.includes('"Apply model/language"'));
const copiedIds = [];
const latest = vm.createContext({ root: { historyService: {
  busy: false, query: "old search", entries: [{ id: "stale" }],
  copy(id) { copiedIds.push(id); },
} } });
vm.runInContext(qmlFunction(controls, "copyLastTranscript"), latest);
latest.copyLastTranscript();
assert.deepEqual(copiedIds, ["latest"]);
assert.equal(latest.root.showLastCopyNotice, true);
latest.root.historyService.busy = true;
latest.copyLastTranscript();
assert.equal(copiedIds.length, 1);
latest.root.historyService = null;
latest.copyLastTranscript();
assert.equal(copiedIds.length, 1);
assert.ok(controls.includes('[applyButton, copyLastButton]'));
assert.ok(controls.includes('height: Math.max(applyButton.implicitHeight, copyLastButton.implicitHeight)'));
assert.ok(controls.includes('body.primaryActions.naturalWidth + root.horizontalInset'));
assert.ok(controls.includes('enabled: root.historyService && !root.historyService.busy'));
console.log("ok - latest transcript copy uses the shared history path, independent of model state and search");
assert.ok(controls.includes("checkColor: root.ready"));
assert.ok(!widget.includes("slotSize: Style.bar.statusSlot"));
const voxtypeUi = fs.readFileSync(new URL("../ui/voxtype/Backend.qml", import.meta.url), "utf8");
const hexUi = fs.readFileSync(new URL("../ui/hex/Backend.qml", import.meta.url), "utf8");
assert.ok(hexUi.includes('toolShortcut: "m"') && !hexUi.includes("omarchy-launch-terminal"));
assert.ok(widget.includes('voxtype.backend === "hex" ? hexBackend : voxtypeBackend'));
const launch = vm.createContext({
  backendUi: {},
  voxtype: { controlPath: "/test/dictation-control", unload() { throw new Error("TUI must not unload"); } },
  close() {}, Quickshell: { execDetached(argv) { launch.launched = argv; } },
});
vm.runInContext(qmlFunction(widget, "launchConfiguration"), launch);
vm.runInContext(`backendUi.toolCommand = ${voxtypeUi.match(/function toolCommand\([^]*?\n  \}/)[0].replace("function toolCommand", "function")}`, launch);
launch.launchConfiguration();
assert.equal(launch.launched.join(" "), "omarchy-launch-terminal -e /test/dictation-control configure");
assert.ok(controls.includes('id: unloadButton'));
assert.ok(controls.includes('tooltipText: "Unload current model; keep its files"'));
assert.ok(voxtypeUi.includes('toolSuffix: "oxtype tui"'));
context.applyProcess = {};
context.backends = [{ value: "voxtype", reason: "" }, { value: "hex", reason: "Install hex-bin to use Hex" }];
context.useBackend("hex");
assert.equal(context.applyProcess.running, undefined);
assert.equal(context.warning, "Install hex-bin to use Hex");
context.backends[1].reason = "";
context.useBackend("voxtype");
assert.equal(context.applyProcess.running, undefined);
context.useBackend("hex");
assert.equal(context.applyProcess.command.join(" "), "/test/dictation-control use hex");
assert.equal(context.reloadState, "loading");
context.applyProcess = {};
context.dictating = true;
context.useBackend("voxtype");
assert.equal(context.applyProcess.running, undefined);
context.dictating = false;
context.reloadState = "";
const catalog = context.modelOptions;
const refreshes = context.metadataRefreshes || 0;
context.updateStatus('{"schema":5,"backend":"hex","state":"stopped"}');
assert.equal(context.backend, "hex");
assert.equal(context.modelOptions.length, 0);
assert.equal(context.follower.running, true);
assert.equal(context.followerHealthy, false);
assert.equal(context.metadataRefreshes, refreshes + 1);
context.backend = "voxtype";
context.modelOptions = catalog;
console.log("ok - language policies, draft validation, state and process requests");

const models = [
  { label: "Parakeet TDT v3 INT8", engine: "parakeet", value: "p", installed: true },
  { label: "Whisper medium", engine: "whisper", value: "w", installed: false },
];
context.modelOptions = models;
const localFilter = source.match(/readonly property var localModels: (.*)/)[1];
assert.equal(vm.runInContext(localFilter, context).length, 1);
assert.equal(vm.runInContext(localFilter, context)[0].value, "p");
const picker = fs.readFileSync(new URL("../ui/shared/panel/UnloadModel.qml", import.meta.url), "utf8");
assert.ok(picker.includes('onCloseRequested: root.cancelled()'));
assert.ok(picker.includes('service.modelLabel + "?"'));
assert.ok(picker.includes('property int choice: 1'));
assert.ok(!picker.includes('TextField'));
assert.ok(picker.includes('onClicked: root.service.unload()'));
assert.ok(!controls.includes("addButton") && !source.includes("downloadModel"));
assert.ok(controls.includes('options: root.voxtype ? root.voxtype.localModels : []'));
assert.equal(controls.match(/Qt.callLater\(root.focusControls\)/g).length, 5);
assert.ok(!controls.includes('Qt.callLater(function() { keyCatcher'));
let clicks = 0, toggles = 0;
const dropdown = { enabled: false, toggle() { toggles++; } };
const button = { enabled: false, clicked() { clicks++; } };
const keyboard = vm.createContext({ root: { actions: [dropdown, button], actionIndex: 0 },
  backendSwitcher: {}, modelDropdown: dropdown, languageDropdown: {} });
vm.runInContext(qmlFunction(controls, "activateAction"), keyboard);
keyboard.activateAction();
assert.equal(toggles, 0);
dropdown.enabled = true;
keyboard.activateAction();
assert.equal(toggles, 1);
keyboard.root.actionIndex = 1;
keyboard.activateAction();
assert.equal(clicks, 0);
button.enabled = true;
keyboard.activateAction();
assert.equal(clicks, 1);
console.log("ok - fuzzy search, installed-only selector, and cancel without installation");

assert.ok(controls.includes("controlRows: [[backendSwitcher], [modelDropdown, unloadButton]"));
assert.ok(controls.includes("readonly property var actions: [].concat.apply([], controlRows)"));
assert.ok(!controls.includes('text: "h/j/k/l: move"'));
assert.equal((controls.match(/FooterShortcut \{/g) || []).length, 4);
assert.ok(controls.includes("suffix: root.backendUi.toolSuffix"));
for (const label of ['suffix: "ettings"',
  'suffix: "eplacements"', 'suffix: "ranscripts"']) assert.ok(controls.includes(label));
assert.ok(controls.includes("[configureShortcut, settingsShortcut, replacementsShortcut, historyShortcut]"));
assert.ok(controls.includes("footer.implicitWidth + root.horizontalInset"));
assert.ok(controls.includes('objectName: "voxtypeFooterSeparator"'));
assert.ok(controls.indexOf('objectName: "voxtypeFooterSeparator"') < controls.indexOf("id: footer"));
assert.ok(!controls.includes("id: actionRow"));
assert.ok(!controls.includes("configureButton"));
assert.equal((controls.match(/shortcutColor: root.warning/g) || []).length, 5);
launch.editorLauncher = {};
launch.editingReplacements = false;
launch.ipcTarget = "voxtype.editor.DP-3";
launch.close = () => { throw new Error("replacement editing must preserve the panel"); };
vm.runInContext(qmlFunction(widget, "launchReplacements"), launch);
launch.launchReplacements();
assert.equal(launch.editorLauncher.command.join(" "), "omarchy-launch-terminal -e /test/dictation-control edit-replacements voxtype.editor.DP-3");
assert.equal(launch.editingReplacements, true);
assert.equal(launch.editorLauncher.running, true);
launch.controller = { show() {} };
launch.controlPanel = { prepareOpen() { launch.prepared = true; } };
launch.draftModelId = "pending-model";
vm.runInContext(qmlFunction(widget, "open"), launch);
launch.open();
assert.equal(launch.editingReplacements, false);
assert.equal(launch.prepared, true);
assert.equal(launch.draftModelId, "pending-model");
assert.ok(controls.includes("open: root.panelOwner.opened && !root.editingReplacements"));
let closes = 0;
const shortcuts = vm.createContext({ root: {
    backendUi: { toolShortcut: "v" }, closeRequested() { closes++; }, actionIndex: 0,
    actions: ["model", "unload", "language", "apply", "copy", "tui", "settings", "replacements", "history"],
    controlRows: [["model", "unload"], ["language"], ["apply", "copy"],
      ["tui", "settings", "replacements", "history"]], focusControls() {},
  }, copyLastButton: button, configureShortcut: button, settingsShortcut: button,
  replacementsShortcut: button, historyShortcut: button,
  backendSwitcher: { close() {} }, modelDropdown: { close() {} }, languageDropdown: { close() {} } });
vm.runInContext(qmlFunction(controls, "activateShortcut"), shortcuts);
const previousClicks = clicks;
for (const key of ["c", "C", "v", "S", "R", "t", "x", "+"]) shortcuts.activateShortcut(key);
assert.equal(clicks - previousClicks, 6);
shortcuts.activateShortcut("q");
shortcuts.activateShortcut("Q");
assert.equal(closes, 2);
assert.ok(controls.includes('blocked: root.unloadingModel || root.backendSwitcher.popupOpen || root.modelDropdown.popupOpen || root.languageDropdown.popupOpen'));
button.enabled = false;
shortcuts.activateShortcut("r");
shortcuts.activateShortcut("C");
assert.equal(clicks - previousClicks, 6);
vm.runInContext(qmlFunction(controls, "moveControl"), shortcuts);
shortcuts.moveControl(1);
assert.equal(shortcuts.root.actionIndex, 1);
shortcuts.moveControl(1);
assert.equal(shortcuts.root.actionIndex, 2);
shortcuts.moveControl(1);
assert.equal(shortcuts.root.actionIndex, 3);
shortcuts.moveControl(-1);
assert.equal(shortcuts.root.actionIndex, 2);
vm.runInContext(qmlFunction(controls, "moveCursor"), shortcuts);
shortcuts.root.actionIndex = 0;
shortcuts.moveCursor(1, 0);
assert.equal(shortcuts.root.actionIndex, 1);
shortcuts.moveCursor(-1, 0);
assert.equal(shortcuts.root.actionIndex, 0);
shortcuts.moveCursor(0, 1);
assert.equal(shortcuts.root.actionIndex, 2);
shortcuts.moveCursor(1, 0);
assert.equal(shortcuts.root.actionIndex, 2);
shortcuts.moveCursor(0, 1);
assert.equal(shortcuts.root.actionIndex, 3);
shortcuts.moveCursor(1, 0);
assert.equal(shortcuts.root.actionIndex, 4);
shortcuts.moveCursor(-1, 0);
assert.equal(shortcuts.root.actionIndex, 3);
shortcuts.moveCursor(0, 1);
assert.equal(shortcuts.root.actionIndex, 5);
shortcuts.moveCursor(1, 0);
assert.equal(shortcuts.root.actionIndex, 6);
shortcuts.moveCursor(1, 0);
assert.equal(shortcuts.root.actionIndex, 7);
shortcuts.moveCursor(1, 0);
assert.equal(shortcuts.root.actionIndex, 8);
shortcuts.moveCursor(1, 0);
assert.equal(shortcuts.root.actionIndex, 5);
shortcuts.moveCursor(-1, 0);
assert.equal(shortcuts.root.actionIndex, 8);
shortcuts.moveCursor(0, -1);
assert.equal(shortcuts.root.actionIndex, 4);
assert.ok(controls.indexOf("NoticeSection {") < controls.indexOf('label: "Speech model"'));
console.log("ok - row/column movement, all-control Tab cycle, and unload-only picker");

const unloadButton = controls.match(/id: unloadButton[^]*?onClicked: root.unloadingModel = true/)[0];
assert.ok(unloadButton.includes('iconText: "\\uf052"'));
assert.ok(unloadButton.includes("foreground: root.urgent"));
assert.ok(unloadButton.includes("fontSize: Style.font.icon"));

const stateColor = widget.match(/readonly property color stateColor: (.*)/)[1];
const iconColor = widget.match(/readonly property color statusColor: (.*)/)[1];
const iconState = vm.createContext({voxtype: {dictationState: "idle", available: true,
  recordingFailure: false, reloading: true, readyFlash: false}, urgent: "red", warning: "yellow",
  ready: "green", foreground: "white", dim: "grey"});
assert.equal(vm.runInContext(iconColor, iconState), "yellow");
iconState.voxtype.reloading = false;
iconState.voxtype.recordingFailure = true;
assert.equal(vm.runInContext(iconColor, iconState), "yellow");
iconState.voxtype.recordingFailure = false;
iconState.voxtype.readyFlash = true;
assert.equal(vm.runInContext(iconColor, iconState), "green");
iconState.voxtype.dictationState = "recording";
assert.equal(vm.runInContext(iconColor, iconState), "red");
iconState.voxtype.dictationState = "idle";
iconState.voxtype.readyFlash = false;
assert.equal(vm.runInContext(iconColor, iconState), "white");
const status = vm.createContext({ voxtype: { stateLabel: "Ready" }, ready: "green",
  foreground: "white", warning: "yellow" });
assert.equal(vm.runInContext(stateColor, status), "green");
status.voxtype.reloading = true;
assert.equal(vm.runInContext(stateColor, status), "yellow");
status.voxtype.reloading = false;
status.voxtype.stateLabel = "Switching";
assert.equal(vm.runInContext(stateColor, status), "yellow");
for (const label of ["Installing", "Transcribing", "Unavailable", "Unloaded"]) {
  status.voxtype.stateLabel = label;
  assert.equal(vm.runInContext(stateColor, status), "white");
}
status.voxtype.stateLabel = "Listening";
assert.equal(vm.runInContext(stateColor, status), "white");
assert.equal(widget.match(/stateColor: root\.stateColor/g).length, 1);
assert.ok(statusHeader.includes('service.stateLabel === "Ready" ? ready : foreground'));
assert.ok(statusHeader.includes("service.recordingFailure ? warning"));
assert.ok(statusHeader.includes('service.dictationState === "recording" ? urgent'));
assert.ok(widget.includes("root.voxtype.reloading || root.voxtype.recordingFailure"));
assert.ok(source.includes('target: "omarchy-qol.voxtype-control"'));
assert.ok(!source.includes("io.github.ilyazar"));
assert.ok(!source.includes("omarchy-voxtype-status"));
assert.ok(source.includes("function recordFailure(message: string): void"));
assert.ok(statusHeader.includes("required property color warning"));
assert.ok(controls.includes("ready: root.ready"));
assert.ok(controls.includes("urgent: root.urgent"));
assert.ok(controls.includes("warning: root.warning"));
assert.ok(!widget.match(/#[0-9a-fA-F]{6}/));
const manifest = JSON.parse(fs.readFileSync(new URL('../manifest.json', import.meta.url), 'utf8'));
assert.ok(widget.includes(`moduleName: "${manifest.id}"`));
console.log("ok - shared panel/tooltip state colour and no hardcoded palette");

let focused = 0;
const focus = vm.createContext({ backendSwitcher: { popupOpen: false }, modelDropdown: { popupOpen: false }, languageDropdown: { popupOpen: false },
  root: { unloadingModel: false, editingReplacements: false },
  keyCatcher: { forceActiveFocus() { focused++; } } });
vm.runInContext(qmlFunction(controls, "focusControls"), focus);
focus.focusControls();
assert.equal(focused, 1);
focus.modelDropdown.popupOpen = true;
focus.focusControls();
assert.equal(focused, 1);
focus.modelDropdown.popupOpen = false;
focus.focusControls();
assert.equal(focused, 2);
focus.root.unloadingModel = true;
focus.focusControls();
assert.equal(focused, 2);
console.log("ok - applied-state gating and search/confirmation focus ownership");
