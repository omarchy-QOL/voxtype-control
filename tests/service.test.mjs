import assert from "node:assert/strict";
import fs from "node:fs";
import vm from "node:vm";

const source = fs.readFileSync(new URL("../Service.qml", import.meta.url), "utf8");
const context = vm.createContext({ metadataUpdated() {}, refreshMetadata() {},
  applyProcess: {}, busy: false, dictating: false, downloadBusy: false, followerHealthy: false, revision: 0,
  warningTimer: { restart() {}, stop() {} }, actionFinished() {}, errorOperation: "",
  modelOptions: [
    { value: "parakeet", codes: ["auto"], reason: "" },
    { value: "canary", codes: ["en", "de"], reason: "" },
    { value: "moonshine", codes: ["ja"], reason: "" }
  ], modelId: "", language: "", controlPath: "/test/voxtype-control" });
for (const name of ["modelFor", "languageOptionsFor", "defaultLanguageFor", "updateStatus", "updateHardware", "updateFollower",
  "request", "cleanError", "clearWarning", "warn", "reportFailure", "resolveFailure", "finishAction"]) {
  const code = source.match(new RegExp(`  function ${name}\\([^]*?\\n  \\}`))?.[0];
  assert.ok(code, name);
  vm.runInContext(code, context);
}
assert.equal(context.defaultLanguageFor("parakeet"), "auto");
assert.equal(context.defaultLanguageFor("canary"), "");
assert.equal(context.defaultLanguageFor("moonshine"), "ja");
assert.equal(context.defaultLanguageFor("missing"), "");
context.updateStatus(JSON.stringify({ schema: 4, model_id: "canary", language: "de",
  state: "streaming", endpoint_ready: true, loaded: true, processes_active: true }));
assert.equal(context.polledState, "streaming");
context.updateHardware('{"schema":4,"gpus":["Intel","AMD Radeon RX 6400"],"preferred_gpu":"RX 6400"}');
context.updateStatus('{"schema":4,"loaded":true}');
assert.equal(context.hardwareLabel, "AMD Radeon RX 6400");
context.updateStatus('{"schema":4,"loaded":false}');
assert.equal(context.hardwareLabel, "AMD Radeon RX 6400");
assert.equal(vm.runInContext(source.match(/readonly property string modelLabel: (.*)/)[1], context), "No model");
context.updateStatus('{"schema":4,"loaded":true,"execution_device":null}');
assert.equal(context.hardwareLabel, "AMD Radeon RX 6400");
context.updateFollower('{"alt":"recording"}');
context.updateStatus('{"schema":4,"state":"idle","model_id":"canary","language":"de"}');
assert.equal(context.followerState, "recording");
assert.equal(context.followerHealthy, true);
assert.equal(context.polledState, "idle");
context.updateFollower('invalid JSON');
assert.equal(context.followerHealthy, false);
assert.equal(context.defaultLanguageFor("canary"), "de");
assert.throws(() => context.updateStatus('{"schema":2}'));
assert.throws(() => context.updateStatus('{"schema":3}'));
assert.throws(() => context.updateHardware('{"schema":3,"gpus":[]}'));
assert.throws(() => context.updateHardware('{"schema":4,"gpus":null,"preferred_gpu":""}'));
assert.throws(() => context.updateHardware('{"schema":4,"gpus":[""],"preferred_gpu":""}'));
for (const [gpus, preference, expected] of [
  [["Intel", "AMD Radeon RX 6400"], "", "2 GPUs (selection unclear)"],
  [["AMD Radeon RX 6400", "AMD Radeon RX 6400"], "RX 6400", "2 GPUs (selection unclear)"],
  [["Intel"], "RX 6400", "Configured GPU not found"],
  [["Intel"], "", "Intel"],
  [[], "", "No GPU detected"],
  [["Intel", "AMD Radeon RX 6400"], "rx 6400", "AMD Radeon RX 6400"],
]) {
  context.updateHardware(JSON.stringify({schema: 4, gpus, preferred_gpu: preference}));
  assert.equal(context.hardwareLabel, expected);
}
context.error = "previous error";
context.errorOperation = "apply";
context.request(["apply", "canary", "en"]);
assert.equal(context.error, "previous error");
assert.equal(context.applyProcess.running, true);
assert.equal(context.applyProcess.command.join(" "), "/test/voxtype-control apply canary en");
assert.equal(context.revision, 1);
context.finishAction(true, "");
assert.equal(context.error, "");
context.applyProcess.running = false;
context.dictating = true;
context.request(["apply", "canary", "en"]);
assert.equal(context.warning, "Stop dictation before applying changes.");
assert.equal(context.applyProcess.running, false);
context.dictating = false;
context.reportFailure("Error: voxtype-control: voxtype-control: Finish dictation before switching models", "apply");
assert.equal(context.warningKind, "dictation");
assert.equal(context.error, "");
context.reportFailure("voxtype-control: voxtype-control: Missing model", "download");
assert.equal(context.error, "Missing model");
context.operation = "apply";
context.finishAction(true, "");
assert.equal(context.error, "Missing model");
context.operation = "download";
context.finishAction(true, "");
assert.equal(context.error, "");

const widget = fs.readFileSync(new URL("../BarWidget.qml", import.meta.url), "utf8");
const condition = widget.match(/readonly property bool canApply: ([^]*?)\n\n/)[1];
const panel = vm.createContext({ voxtype: { controlAvailable: true, busy: false, dictating: false,
  loaded: true, endpointReady: true, modelId: "canary", language: "en", errorOperation: "" },
  selectedModel: { codes: ["en", "de"], reason: "" }, draftModelId: "canary", draftLanguage: "" });
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
vm.runInContext(widget.match(/  function applyDraft\([^]*?\n  \}/)[0], panel);
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
assert.ok(!widget.includes("recover"));
assert.ok(!widget.includes("Language is controlled by this model."));
assert.ok(!widget.includes("Choose the language you are speaking."));
assert.ok(widget.includes('"Load STT model / Apply language selection"'));
assert.ok(widget.includes("checkColor: root.ready"));
assert.ok(!widget.includes("slotSize: Style.bar.statusSlot"));
const launch = vm.createContext({
  voxtype: { controlPath: "/test/voxtype-control", unload() { throw new Error("TUI must not unload"); } },
  close() {}, Quickshell: { execDetached(argv) { launch.launched = argv; } },
});
vm.runInContext(widget.match(/  function launchConfiguration\([^]*?\n  \}/)[0], launch);
launch.launchConfiguration();
assert.equal(launch.launched.join(" "), "omarchy-launch-terminal -e /test/voxtype-control configure");
assert.ok(widget.includes('id: unloadButton'));
assert.ok(widget.includes('tooltipText: "Unload current model; keep its files"'));
assert.ok(widget.includes('text: "Voxtype TUI"'));
console.log("ok - language policies, draft validation, state and process requests");

const models = [
  { label: "Parakeet TDT v3 INT8", engine: "parakeet", value: "p", installed: true },
  { label: "Whisper medium", engine: "whisper", value: "w", installed: false },
];
context.modelOptions = models;
const localFilter = source.match(/readonly property var localModels: (.*)/)[1];
assert.equal(vm.runInContext(localFilter, context).length, 1);
assert.equal(vm.runInContext(localFilter, context)[0].value, "p");
const picker = fs.readFileSync(new URL("../UnloadModel.qml", import.meta.url), "utf8");
assert.ok(picker.includes('onCloseRequested: root.cancelled()'));
assert.ok(picker.includes('service.modelLabel + "?"'));
assert.ok(picker.includes('property int choice: 1'));
assert.ok(!picker.includes('TextField'));
assert.ok(picker.includes('onClicked: root.service.unload()'));
assert.ok(!widget.includes("addButton") && !source.includes("downloadModel"));
assert.ok(widget.includes('options: root.voxtype ? root.voxtype.localModels : []'));
assert.equal(widget.match(/Qt.callLater\(root.focusControls\)/g).length, 5);
assert.ok(!widget.includes('Qt.callLater(function() { keyCatcher'));
let clicks = 0, toggles = 0;
const dropdown = { enabled: false, toggle() { toggles++; } };
const button = { enabled: false, clicked() { clicks++; } };
const keyboard = vm.createContext({ root: { actions: [dropdown, button], actionIndex: 0 },
  backendDropdown: dropdown, languageDropdown: {} });
vm.runInContext(widget.match(/  function activateAction\([^]*?\n  \}/)[0], keyboard);
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

assert.ok(widget.includes("controlRows: [[backendDropdown, unloadButton]"));
assert.ok(widget.includes("readonly property var actions: [].concat.apply([], controlRows)"));
assert.ok(widget.includes('text: "h/j/k/l: move"'));
assert.ok(widget.includes('text: "Settings"'));
assert.ok(widget.includes('text: "Replacements"'));
assert.ok(widget.includes('text: "[V]oxtype  [S]ettings  [R]eplacements"'));
launch.editorLauncher = {};
launch.editingReplacements = false;
launch.ipcTarget = "voxtype.editor.DP-3";
launch.close = () => { throw new Error("replacement editing must preserve the panel"); };
vm.runInContext(widget.match(/  function launchReplacements\([^]*?\n  \}/)[0], launch);
launch.launchReplacements();
assert.equal(launch.editorLauncher.command.join(" "), "omarchy-launch-terminal -e /test/voxtype-control edit-replacements voxtype.editor.DP-3");
assert.equal(launch.editingReplacements, true);
assert.equal(launch.editorLauncher.running, true);
launch.controller = { show() {} };
launch.root = { focusControls() {} };
launch.Qt = { callLater(fn) { fn(); } };
launch.draftModelId = "pending-model";
vm.runInContext(widget.match(/  function open\([^]*?\n  \}/)[0], launch);
launch.open();
assert.equal(launch.editingReplacements, false);
assert.equal(launch.draftModelId, "pending-model");
assert.ok(widget.includes("open: root.opened && !root.editingReplacements"));
let closes = 0;
const shortcuts = vm.createContext({ root: { close() { closes++; } },
  configureButton: button, configFileButton: button,
  replacementsButton: button, backendDropdown: { close() {} }, languageDropdown: { close() {} },
  actionIndex: 0, actions: ["model", "unload", "language", "apply", "tui", "settings", "replacements"],
  controlRows: [["model", "unload"], ["language"], ["apply"], ["tui", "settings", "replacements"]],
  focusControls() {} });
vm.runInContext(widget.match(/  function activateShortcut\([^]*?\n  \}/)[0], shortcuts);
const previousClicks = clicks;
for (const key of ["v", "S", "R", "x", "+"]) shortcuts.activateShortcut(key);
assert.equal(clicks - previousClicks, 3);
shortcuts.activateShortcut("q");
shortcuts.activateShortcut("Q");
assert.equal(closes, 2);
assert.ok(widget.includes('blocked: root.unloadingModel || backendDropdown.popupOpen || languageDropdown.popupOpen'));
button.enabled = false;
shortcuts.activateShortcut("r");
assert.equal(clicks - previousClicks, 3);
vm.runInContext(widget.match(/  function moveControl\([^]*?\n  \}/)[0], shortcuts);
shortcuts.moveControl(1);
assert.equal(shortcuts.actionIndex, 1);
shortcuts.moveControl(1);
assert.equal(shortcuts.actionIndex, 2);
shortcuts.moveControl(1);
assert.equal(shortcuts.actionIndex, 3);
shortcuts.moveControl(-1);
assert.equal(shortcuts.actionIndex, 2);
vm.runInContext(widget.match(/  function moveCursor\([^]*?\n  \}/)[0], shortcuts);
shortcuts.actionIndex = 0;
shortcuts.moveCursor(1, 0);
assert.equal(shortcuts.actionIndex, 1);
shortcuts.moveCursor(-1, 0);
assert.equal(shortcuts.actionIndex, 0);
shortcuts.moveCursor(0, 1);
assert.equal(shortcuts.actionIndex, 2);
shortcuts.moveCursor(1, 0);
assert.equal(shortcuts.actionIndex, 2);
shortcuts.moveCursor(0, 1);
assert.equal(shortcuts.actionIndex, 3);
shortcuts.moveCursor(0, 1);
assert.equal(shortcuts.actionIndex, 4);
shortcuts.moveCursor(1, 0);
assert.equal(shortcuts.actionIndex, 5);
shortcuts.moveCursor(1, 0);
assert.equal(shortcuts.actionIndex, 6);
shortcuts.moveCursor(0, -1);
assert.equal(shortcuts.actionIndex, 3);
assert.ok(widget.indexOf("NoticeSection {") < widget.indexOf('label: "Speech model"'));
console.log("ok - row/column movement, all-control Tab cycle, and unload-only picker");

const stateColor = widget.match(/readonly property color stateColor:([^]*?)\n  readonly/)[1];
const status = vm.createContext({ voxtype: { stateLabel: "Ready" }, ready: "green", warning: "yellow", urgent: "red" });
assert.equal(vm.runInContext(stateColor, status), "green");
for (const label of ["Switching", "Installing", "Transcribing", "Unavailable", "Unloaded"]) {
  status.voxtype.stateLabel = label;
  assert.equal(vm.runInContext(stateColor, status), "yellow");
}
status.voxtype.stateLabel = "Listening";
assert.equal(vm.runInContext(stateColor, status), "red");
assert.ok(widget.includes("stateColor: root.stateColor"));
assert.ok(!widget.match(/#[0-9a-fA-F]{6}/));
console.log("ok - shared panel/tooltip state colour and no hardcoded palette");

let focused = 0;
const focus = vm.createContext({ backendDropdown: { popupOpen: false }, languageDropdown: { popupOpen: false },
  unloadingModel: false, editingReplacements: false, keyCatcher: { forceActiveFocus() { focused++; } } });
vm.runInContext(widget.match(/  function focusControls\([^]*?\n  \}/)[0], focus);
focus.focusControls();
assert.equal(focused, 1);
focus.backendDropdown.popupOpen = true;
focus.focusControls();
assert.equal(focused, 1);
focus.backendDropdown.popupOpen = false;
focus.focusControls();
assert.equal(focused, 2);
focus.unloadingModel = true;
focus.focusControls();
assert.equal(focused, 2);
console.log("ok - applied-state gating and search/confirmation focus ownership");
