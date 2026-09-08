import assert from "node:assert/strict";
import fs from "node:fs";
import vm from "node:vm";

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

const logicSource = fs.readFileSync(
  new URL("../logic/TranscriptHistory.js", import.meta.url), "utf8").replace(".pragma library", "");
const logic = vm.createContext({ Qt: { formatDateTime: () => "formatted" }, Date, isNaN });
vm.runInContext(logicSource, logic);
const entries = [{id: "new"}, {id: "old"}];
assert.equal(logic.indexForId(entries, "old"), 1);
assert.equal(logic.indexForId(entries, "missing"), -1);
assert.equal(logic.retainedId(entries, "old"), "old");
assert.equal(logic.retainedId(entries, "missing"), "new");
assert.equal(logic.retainedId([], "old"), "");

const serviceSource = fs.readFileSync(
  new URL("../history/TranscriptHistoryService.qml", import.meta.url), "utf8");
const root = { entries: [], warning: "stale", error: "stale" };
const service = vm.createContext({ root });
vm.runInContext(qmlFunction(serviceSource, "updateList"), service);
service.updateList(JSON.stringify({schema: 1, entries: [{id: "one", text: "exact"}],
  capture_error: "save failed", warnings: ["bad entry"]}));
assert.equal(root.entries[0].text, "exact");
assert.equal(root.warning, "save failed\nbad entry");
assert.equal(root.error, "");
assert.throws(() => service.updateList('{"schema":2,"entries":[]}'), /current Voxtype/);

const view = fs.readFileSync(
  new URL("../history/TranscriptHistory.qml", import.meta.url), "utf8");
const activate = qmlFunction(view, "activate");
assert.ok(activate.includes("service.refresh"));
assert.ok(!activate.includes("copy"));
assert.ok(view.includes("selectedId"));
assert.ok(view.includes("requestConfirmation(\"delete\")"));
assert.ok(view.includes("requestConfirmation(\"clear\")"));
assert.ok(serviceSource.includes('[root.controlPath, "history", action]'));
assert.ok(!serviceSource.includes("sh -c"));
console.log("ok - transcript identity, service parsing, and explicit copy/delete contracts");
