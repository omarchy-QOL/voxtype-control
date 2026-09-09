#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
omarchy plugin validate "$ROOT"
qt_tools=/usr/lib/qt6/bin
shell_root="${OMARCHY_PATH:-/usr/share/omarchy}/shell"
test_root="$(mktemp -d /tmp/voxtype-qml-test.XXXXXX)"
trap 'rm -rf -- "$test_root"' EXIT
ln -s "$shell_root" "$test_root/qs"
find "$ROOT" -path "$ROOT/.git" -prune -o -path "$ROOT/TODO" -prune \
  -o -name '*.qml' -type f -print0 | while IFS= read -r -d '' file; do
  "$qt_tools/qmlformat" "$file" >/dev/null
done
# Host QtObject properties and Quickshell's exit-status enum lack complete type metadata.
"$qt_tools/qmllint" -I "$test_root" -I /usr/lib/qt6/qml \
  --missing-property disable --signal-handler-parameters disable \
  "$ROOT"/*.qml "$ROOT"/components/*.qml "$ROOT"/history/*.qml \
  "$ROOT"/services/*.qml
node "$ROOT/tests/service.test.mjs"
node "$ROOT/tests/history.test.mjs"
mkdir "$test_root/runtime"
cp -a "$ROOT"/*.qml "$ROOT/components" "$ROOT/history" "$ROOT/logic" \
  "$ROOT/services" "$ROOT/tests" "$test_root/runtime/"
cp "$ROOT/tests/qml/shell.qml" "$test_root/runtime/shell.qml"
ln -s "$shell_root/Commons" "$test_root/runtime/Commons"
ln -s "$shell_root/Ui" "$test_root/runtime/Ui"
# The Qt-only runner cannot load Quickshell's statically linked QML plugins.
if ! env -u WAYLAND_DISPLAY QT_QPA_PLATFORM=offscreen \
  timeout 20 quickshell --no-color -p "$test_root/runtime/shell.qml" \
  >"$test_root/runtime.log" 2>&1; then
  cat "$test_root/runtime.log"
  exit 1
fi
cat "$test_root/runtime.log"
rg -q 'VOXTYPE_QML_TESTS_PASSED' "$test_root/runtime.log"
printf '%s\n' 'ok - Qt 6 lint and real Quickshell/QML runtime tests'
