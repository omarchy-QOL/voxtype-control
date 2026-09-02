# Voxtype Control

Capability-aware Voxtype controls for the Omarchy Quattro bar.

The plugin replaces only the built-in Dictation child of
`omarchy.indicators`. It keeps one shared status follower regardless of monitor
count, shows the active local ASR backend and model, and provides backend and
language selection.

## Model discovery

Voxtype's native TUI and this plugin have different scopes.

The native TUI uses Voxtype's model catalog. It resolves the model directory
through `XDG_DATA_HOME`; the default is:

```text
~/.local/share/voxtype/models
```

Whisper files use names such as `ggml-base.en.bin`. Native-engine model
directories live under the same root. The TUI cycles through models from its
built-in catalog, checks that catalog against the model directory, reports
which entries are installed, and can offer a download for a missing selection.

This plugin does not use that catalog because this installation keeps Voxtype
in remote Whisper mode. Its picker switches the two external resident
sidecars instead:

- Parakeet availability comes from the managed systemd unit's
  `--asr-model` path, normally below `~/.local/share/nemo-speech/models`.
- Canary availability requires its managed unit, launcher, and a Canary GGUF
  below `~/.local/share/transcribe-cpp/models`.

An unavailable sidecar is omitted from the picker. The active model and device
come from the health-gated service process rather than a hard-coded host
default.

## Controls

- Left click opens backend and language controls.
- Right click opens the full Voxtype configuration TUI.
- Pause/Break and Ctrl+Delete remain direct `voxtype record toggle` bindings.

Canary exposes automatic, English, and German routing. Parakeet TDT 0.6B v3
exposes its 25 supported languages plus automatic routing. The backend picker
only lists Workflow-managed sidecars whose service and model assets are
present; Voxtype's own model catalog remains in its native TUI.

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
