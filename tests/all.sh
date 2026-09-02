#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

omarchy plugin validate "$ROOT"

qmlformat "$ROOT/Service.qml" >/dev/null
qmlformat "$ROOT/BarWidget.qml" >/dev/null

jq -e '
  .id == "io.github.ilyazar.voxtype-control" and
  .kinds == ["service", "bar-widget"] and
  .keepLoaded == true
' "$ROOT/manifest.json" >/dev/null

[[ "$(rg -l 'omarchy-voxtype-status' "$ROOT"/*.qml | wc -l)" -eq 1 ]]
rg -Fq 'bar.shell.serviceFor(moduleName)' "$ROOT/BarWidget.qml"
rg -Fq 'command: ["omarchy-voxtype-status"]' "$ROOT/Service.qml"
! rg -q 'systemctl|switch_asr_backend|language_cycle' "$ROOT"/*.qml

printf 'ok - plugin contract\n'
