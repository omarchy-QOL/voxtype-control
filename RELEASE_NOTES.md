# 0.5.0

Local release candidate on `dev`. Not published or submitted to the marketplace.

## Changes

- Replace the duplicate action buttons with a clickable shortcut footer.
- Use theme yellow for bracketed shortcut keys and add a footer divider.
- Fit the main panel to its controls rather than the removed button row.
- Place the shorter apply button beside `[C]opy last transcript`.
- Copy the newest stored transcript through the shared history action, even
  when the history list is stale or search-filtered.
- Add a balanced two-line copy tooltip and explicit clipboard confirmation.
- Show Switching in theme yellow in the microphone hover tooltip; keep Ready
  green.
- Align widget service lookup and popup routing with the new manifest ID.
- Add transcript scrolling, copy-on-selection, copy feedback, and a default-yes
  close prompt after full transcript copies.
- Require confirmation for transcript deletion through `Ctrl+D` and
  `Ctrl+Shift+D`.
- Pulse the microphone yellow on recording failures, accepting failure reports
  under both the current and previous plugin IDs.

## Plugin identity

The candidate uses `omarchy-qol.voxtype-control`, replacing the v0.4.0 ID
`io.github.ilyazar.voxtype-control`. Existing installations are not renamed
or migrated automatically. Back up local plugin edits and update enabled-plugin,
bar, and desktop-shortcut references when adopting the new ID. Do not enable
both identities at once. Model files and transcript history are external to
this plugin and are not removed by the identity change.

The separately installed schema-4 `voxtype-control` helper remains required.
This candidate does not change or restart capture or ASR services.

## Validation

- Native plugin manifest validation and Qt 6 lint checks.
- JavaScript tests for shortcut dispatch, layout, ID consistency, and shared
  latest-transcript copying.
- 29 isolated Quickshell/QML runtime cases, including equal-height buttons,
  label fit, themed shortcut colors, the two-line hover tooltip, transcript
  selection and copy confirmation, and recording-failure feedback.
- Live UI and clipboard acceptance for the UI changes using the existing
  installation. The new identity still requires an isolated installation
  acceptance check before promotion.

## Promotion

Review and test before merging `dev` into upstream `main`. Publish 0.5.0 only
after that merge. Marketplace submission is a separate approval step. No
publication or upstream merge is part of this preparation.
