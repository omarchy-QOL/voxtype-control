# Development

## Runtime contract

The service and bar widget run inside Omarchy's shell. The external
`voxtype-control` helper owns configuration and systemd operations; the plugin
does not install runtimes or models. Workflow's application setup supplies
the helper through `apps/voxtype-setup/setup_voxtype.sh`.

- `list` supplies model IDs, installed status, language codes, and blockers.
- `status` uses schema 4 for selection, process readiness, and operation state.
- `hardware` reads Fastfetch's GPU inventory and the device preference
  independently of model state.
- `apply MODEL LANGUAGE` and `unload` wait for the systemd operation to finish.
- `configure`, `edit-config`, and `edit-replacements` open the existing tools.
- `omarchy-voxtype-status` supplies the live dictation stream.

The header reports controller state; the model/language draft stays local to
each panel. Both dropdowns use an explicit QML Binding so upstream writes to
`value` cannot disconnect their displays from the submitted draft. Reopening
resets the draft to the controller selection.

The live status stream takes precedence over polling. A revision guard rejects
pre-action poll responses. Hardware refresh runs at startup and on metadata
refresh, not on each status poll. A unique configured GPU match is required
on multi-GPU hosts; hardware presence does not establish inference acceleration.

Apply feedback belongs to the shared service, not the panel. A fresh
post-completion status confirms readiness before the one-second green flash.
The glyph uses Keyboard Layout Pulse's 650 ms opacity/scale animation; failures
reset it without a success flash. Feedback never gates model usability.

## Notices and replacements

Safety rejections are temporary warnings. A failed command exiting does not
clear a busy warning. Failed actions remain errors until a relevant retry
succeeds; status/catalog errors clear when their own checks succeed.

The helper validates replacement edits, preserves unchanged order/comments,
and rejects conflicting edits. Invalid drafts are retained with a notification.
The editor return target is per-monitor and preserves the panel's pending
selection. Saving may restart idle capture to reread the configuration;
external workers remain resident where supported.

## Local checkout

The installed plugin must be a regular checkout or worktree, not a symlink:

```text
~/.config/omarchy/plugins/io.github.ilyazar.voxtype-control
```

Use `git worktree list` to identify a development checkout. Do not run the
release updater over uncommitted development changes. The service deliberately
omits `keepLoaded`: model operations belong to systemd and survive shell
reloads.
If a rescan retains compiled QML, run `omarchy restart shell`.

## Tests

```bash
./tests/all.sh
```

This runs the native manifest validator, Qt 6 formatting/lint checks, JavaScript
tests, and isolated offscreen Quickshell tests. Polling and model operations
are disabled in the QML fixtures; these checks do not prove speech accuracy
or real GPU loading.

Qt-only test runners cannot load Quickshell's statically linked plugins.
Lint excludes two host metadata gaps: dynamic QtObject properties and the
QProcess exit-status enum. Runtime tests cover selection bindings, repeated
search/reset cycles, navigation, notice lifetimes, tooltip colors, hardware
state, confirmation sizing, and spinner reset.

Keep local TODO files out of Git and release archives. Preserve the shared
model files and replacement dictionaries; they are not plugin-owned artifacts.
