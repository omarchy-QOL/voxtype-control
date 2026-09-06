# Voxtype control

A thin model/language panel for Omarchy Quattro. It requires Workflow's
`voxtype-control` helper with schema 4 and Voxtype's JSON configuration API.

- Left click opens model selection; right click opens the Voxtype TUI.
- Hover shows the model above the panel's live status, with aligned click
  hints on the right. Ready/warning colours come from the active theme's
  green/yellow (or ANSI color2/color3), not fixed colours.
- The bottom buttons open Voxtype TUI, Settings, or Replacements.
- The live status sits beneath Voxtype on the left. The right-hand box lists
  model and host GPU. Long labels truncate instead of widening the panel.
  Hardware discovery uses Fastfetch, independently of model loading. Unloading
  changes the model to "No model" without clearing the hardware name. This row
  identifies hardware; it does not claim that inference uses GPU acceleration.
- The main dropdown contains local models only, including external Parakeet
  Q8/FP16 and Canary Q8. Use the Voxtype TUI for model downloads; there is no
  download button or installation picker in this plugin. Neither the plugin
  nor the inspected Voxtype 1.0.1 TUI provides a model-file deletion action.
- Parakeet v3 uses automatic recognition. Canary requires English or German.
  Selecting Canary clears an incompatible language; choose one before Load.
  The disabled Load button explicitly identifies a missing language choice.
- Apply waits for the systemd operation's exit status. Apply/unload are
  unavailable during dictation; the backend also checks for races. An unchanged
  healthy runtime disables Apply. A model/language change, unloaded/unhealthy
  model, or failed Apply enables load/retry with a green checkmark.
  While switching, only the rotating icon uses the current theme's yellow.
- The red cross asks whether to unload the backend-reported active model.
  No is selected initially; arrows/hjkl and Tab move between Yes and No.
  Enter confirms, and q/Escape cancels. Model files are always retained.
  The confirmation fits its single-line question, including panel insets.
  Names wider than the screen are elided, never wrapped.
- Ctrl+Insert toggles dictation; Pause/Break and Ctrl+Delete still work.
- Ctrl+Shift+Insert toggles this panel. Left/Right or h/l move across a row;
  Up/Down or k/j move between rows. Tab/Shift+Tab traverse all seven controls.
  Enter activates the selected control and focuses search when appropriate.
- With dropdowns closed, V opens the TUI, S opens Settings, and R opens
  Replacements. Q or Escape closes the main panel. q/h/j/k/l remain text while
  a model/language search has focus; closing search restores panel navigation.

The helper owns configuration and service changes. Downloads delegate to the
upstream CLI, without activation. There is no custom downloader, operation
journal, recovery protocol, or second model switcher.
A shell reload does not terminate the systemd-owned switch. The TUI edits
shared preferences; the panel remains authoritative for model selection.
The language dropdown describes enabled choices, not every language the model
can recognize. EN/DE is the user's current preference restriction.
Both dropdowns use an explicit owner binding: upstream selection writes cannot
disconnect the displayed value from the draft submitted by Apply. Reopening
the panel resets both displays to the controller selection. The header shows
runtime state; dropdowns show the pending selection until it is applied.

## Quick replacements

Press R in the panel. Your Omarchy default editor opens a private temporary
TOML file containing only the `[text.replacements]` entries, without extra
blank rows. Edit, save and close (`:wq` in Neovim); validation and saving happen
automatically, then the same panel returns with its pending selections intact.
There is no confirmation prompt. Quit without saving (`:q!`) to discard unsaved
edits. GUI editors use their wait-for-close option. Invalid edits leave the
config unchanged, retain the draft, and show a notification with its path.

New pairs append in the shared config, even when typed at the top. Updates
keep their existing positions; deleting a pair removes it. Unchanged entries,
comments and other settings stay intact. Reordering or reformatting unchanged
pairs is ignored; use Settings for deliberate formatting/comment changes.
Invalid TOML and case-insensitive duplicate keys are rejected. Conflicting
replacement edits from another session are not overwritten.

Voxtype validates the result before saving. If dictation is idle and loaded,
its capture process restarts to read the new replacements; an already-ready
external Parakeet/Canary worker stays loaded. Native in-process models need to
reload. An unloaded model stays unloaded. Finish dictation before saving.
The CLI entry point is `voxtype-control edit-replacements` inside a terminal.

## Warnings and errors

Notices appear below the first divider, before Speech model. Warning is theme
yellow; Error is theme red. Repeated CLI prefixes are removed.

- Safely rejected actions (dictation active or another operation busy) are
  warnings. They expire after ten seconds or clear after a successful retry;
  a dictation warning also clears when dictation ends. A failed command exiting
  does not prove that an external controller lock has been released.
- Failed actions remain errors until a relevant retry succeeds. A healthy
  transcription endpoint does not erase an unrelated failed action.
- Status/catalog errors clear when their own check succeeds. They take
  priority over temporary warnings, and failed catalog checks retry.

Persistent means unresolved, not that the hardware is permanently broken.
The standalone `tests/notice_preview.qml` exercises the same notice handlers
with simulated failures and no model operations.

## Installation

The controller is a separate prerequisite and is not included in this
repository. Installing this plugin alone does not install Voxtype, its helper,
or speech models.

Once the schema-4 helper is available:

```bash
omarchy plugin add https://github.com/omarchy-QOL/voxtype-control
```

Install the helper with `apps/voxtype-setup/setup_voxtype.sh`. Keep the plugin
as an actual Git checkout or worktree at:

```text
~/.config/omarchy/plugins/io.github.ilyazar.voxtype-control
```

Do not make the plugin root a symlink: the native validator rejects it and
the recursive file watcher does not traverse it. The active development
worktree lives directly at the path above; `git worktree list` identifies it.
Uncommitted development work should not be updated through the release updater.

The service is recreated with the widget on plugin reload. It deliberately
does not use `keepLoaded`: model operations belong to systemd, not the UI
service. Saving plugin source now uses Omarchy's ordinary reload path.
If a rescan retains compiled QML after a helper schema change, run
`omarchy restart shell`. This does not restart the systemd-owned speech model.

Fastfetch (included in Omarchy) supplies GPU inventory through
`voxtype-control hardware`. The shared service refreshes it at startup and on
panel opening/metadata refresh, never during ordinary status polling. There is
no persistent hardware cache or additional service. A unique
`settings.json` `device_match` chooses the displayed GPU; without a preference,
only a single-GPU inventory selects itself. Multiple or unmatched GPUs are
reported explicitly, never guessed by enumeration order.

Hardware-discovery failures affect only that row, not model controls. A later
metadata refresh retries discovery. Actual execution-device evidence remains
separate in `voxtype-control status`; native engines without telemetry report
`execution_device: null`, including on machines with a GPU.

This is a service + bar-widget plugin, not a system-tray application or the
built-in Dictation indicator. Its bar icon uses the standard BarIconButton
size, rather than the smaller status-indicator overrides.

Keep Omarchy's other indicators enabled; exclude its duplicate Dictation item
when this widget is enabled. Plugin removal only removes its widget/link.
Use the Workflow setup's removal command to remove the controller and units.

## Validation

```bash
./tests/all.sh
```

Tests use the explicit Qt 6 tools and an isolated offscreen Quickshell process
for real QML binding checks. The plain Qt test runner cannot load Quickshell's
statically linked QML plugins. The test service disables its polling/follower
and overrides metadata refresh, so these tests do not access model services.

Qt 6 lint resolves `qs.*` against the installed shell. Two known metadata
gaps are excluded: dynamic host QtObject properties and Quickshell's
`QProcess::ExitStatus` signal type. This is not a claim of exhaustive static
type checking. Runtime tests verify hover binding preservation and that stale
poll responses cannot override the live status stream. Keyboard shortcuts use
the same enabled controls as mouse actions, including unload confirmation.

These checks do not prove live speech or GPU behavior.
