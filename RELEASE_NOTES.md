# 0.5.0

Release candidate on `dev`; promotion to `main` remains pending.

## Changes

- Switch between Voxtype and Hex from the panel header without changing the
  model, language, replacements, and transcript workflows.
- Keep backend UI under `ui/voxtype` and `ui/hex`, with common controls under
  `ui/shared`.
- Keep panel width stable across backends and fit primary action labels.
- Discard stale status, backend-list, and model-catalog replies after changes.
- Follow dictation directly through the backend-aware helper.
- Keep shared replacements and durable transcript history outside the plugin.
- Provide transcript search, scrolling, copy-on-selection, clipboard feedback,
  and confirmed deletion. Full-entry copies offer a default-yes close prompt.
- Report recording failures through notifications and the microphone indicator.

## Dependencies and ownership

Install the separate schema-5 `dictation-control` helper from the Workflow
Voxtype setup. The helper owns backend selection, model operations, shared
replacements, history, and delivery. Desktop shortcuts must call that entry
point. Hex additionally needs `hex-bin` and an installed model.

The companion helper changes serialize switching and recording, validate a
saved selection before stopping working dictation, and stop failed loads.
Hex transcript capture and delivery share the recording lock. Replacement
saves check the active backend before changing the dictionary.

The plugin ID is `omarchy-qol.voxtype-control`. Models, application settings,
replacements, and transcript history are independently owned and retained when
removing the plugin.

## Validation and remaining gates

The plugin passes native validation, Qt 6 lint, JavaScript checks, and 33
isolated Quickshell/QML cases. The companion helper passes 150 tests, including
real CLI configuration validation, with no skips.

Isolated checks with the real backends have exercised mouse switching in both
directions, model restoration, stable panel width, transcript search/copy,
and speech delivered into an unsent terminal with matching stored text.
These checks do not replace the user's microphone acceptance or a real reboot
with Hex selected.

Native removal has a confirmed open-tool cleanup failure: a Voxtype TUI and
its terminal launched from the widget remain running after plugin removal.
Closing test-created processes manually does not make that case pass. The
removal behavior needs a decision before claiming general lifecycle readiness.

## Promotion

Resolve the removal contract, complete the remaining acceptance checks, and
record exact plugin/helper revisions before the merge decision. Publishing a
release and marketplace submission remain separate actions.
