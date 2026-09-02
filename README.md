# Voxtype Control

Capability-aware Voxtype controls for the Omarchy Quattro bar.

The plugin replaces only the built-in Dictation child of
`omarchy.indicators`. It keeps one shared status follower regardless of monitor
count, shows the active local ASR backend and model, and provides backend and
language selection.

## Controls

- Left click opens backend, language, recording, and cancellation controls.
- Right click opens the full Voxtype configuration TUI.
- Pause/Break and Ctrl+Delete remain direct `voxtype record toggle` bindings.

Canary exposes automatic, English, and German routing. Parakeet TDT 0.6B v3
exposes its 25 supported languages plus automatic routing. Whisper rollback
models are reported as installed assets but are not treated as resident
sidecars.

## Requirements

- Omarchy Quattro
- Voxtype 1.0 or newer
- `omarchy-voxtype-status`
- the Workflow-managed `~/.local/bin/voxtype-control` helper
- `~/.local/bin/voxtype-configure-launcher`

The plugin does not install models, write systemd units, or run privileged
commands. ASR switching remains owned by `apps/voxtype-setup`.

## Bar migration

Keep the grouped indicator widget and remove only Dictation:

```json
{
  "id": "omarchy.indicators",
  "items": [
    "ScreenRecording",
    "Reminder",
    "NightLight",
    "Dnd",
    "StayAwake"
  ]
}
```

Place this plugin beside it:

```json
{
  "id": "io.github.ilyazar.voxtype-control"
}
```

## Validate

```bash
./tests/all.sh
```

## Development install

Link or copy this repository to:

```text
~/.config/omarchy/plugins/io.github.ilyazar.voxtype-control
```

Then rescan the shell and put the widget in the bar. The Workflow-managed
helper must be installed separately through `apps/voxtype-setup`.

## Remove

Remove the widget from the bar, then remove its plugin checkout or development
link. The plugin creates no services, models, configuration, or persistent
state of its own.
