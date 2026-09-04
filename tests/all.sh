#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

omarchy plugin validate "$ROOT"

qmlformat "$ROOT/Service.qml" >/dev/null
qmlformat "$ROOT/BarWidget.qml" >/dev/null
qmlformat "$ROOT/GuardedDropdown.qml" >/dev/null
qmlformat "$ROOT/GuardedSearchableDropdown.qml" >/dev/null

jq -e '
  .id == "io.github.ilyazar.voxtype-control" and
  .version == "0.2.2" and
  .kinds == ["service", "bar-widget"] and
  .keepLoaded == true
' "$ROOT/manifest.json" >/dev/null

[[ "$(rg -l 'omarchy-voxtype-status' "$ROOT"/*.qml | wc -l)" -eq 1 ]]
rg -Fq 'bar.shell.serviceFor(moduleName)' "$ROOT/BarWidget.qml"
rg -Fq 'command: ["omarchy-voxtype-status"]' "$ROOT/Service.qml"
rg -Fq 'text += "\u00a0"' "$ROOT/Service.qml"
rg -Fq 'property Timer metadataRetry' "$ROOT/Service.qml"
rg -Fq 'root.scheduleMetadataRetry()' "$ROOT/Service.qml"
follower_body="$(
  sed -n '/function updateFollower/,/function updateMetadata/p' \
    "$ROOT/Service.qml"
)"
! rg -q 'data\.(model|device)' <<<"$follower_body"
rg -Fq '"edit-config"' "$ROOT/BarWidget.qml"
! rg -q 'configPath|omarchy-launch-config-editor' \
  "$ROOT/Service.qml" "$ROOT/BarWidget.qml"
rg -Fq 'lastClosedAt' "$ROOT/GuardedDropdown.qml"
rg -Fq 'lastClosedAt' "$ROOT/GuardedSearchableDropdown.qml"
rg -Fq 'height: root.rowHeight' "$ROOT/GuardedDropdown.qml"
rg -Fq 'height: root.rowHeight' "$ROOT/GuardedSearchableDropdown.qml"
! rg -q 'systemctl|switch_asr_backend|language_cycle' "$ROOT"/*.qml

printf 'ok - plugin contract\n'
