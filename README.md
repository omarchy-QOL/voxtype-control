# Voxtype Control for Omarchy

Local dictation controls in the Omarchy bar. Choose a speech model, switch
spoken languages, recover completed transcripts, and edit word replacements
without leaving your desktop.

## Screenshot

Coming soon.

<!-- Add the screenshot: ![Voxtype model and language controls](preview.png) -->

## Install

Requires Omarchy Quattro, Voxtype with local models, and the separate
`voxtype-control` helper (schema 4). The helper and models are **not bundled**;
this plugin needs an already-configured Voxtype setup.

```bash
omarchy plugin add https://github.com/omarchy-QOL/voxtype-control --enable
```

## Use

- **Left-click** the microphone to open model and language controls.
- Choose an installed model and language, then select **Load / Apply**.
- Wait for **Ready** before dictating. Finish dictation before switching.
- Select **×** to unload the current model. Its files stay on disk.
- Select **Transcripts** to search, review, copy, or explicitly delete completed
  dictations. The newest entry is selected; opening and browsing never copy.
- **Right-click**, or select **TUI**, to open Voxtype's terminal menu
  for model downloads and configuration.

Parakeet v3 recognizes languages automatically. Canary requires **English** or
**German**; select one before loading. Available choices depend on the model.

The header shows the current model; dropdowns show your pending selection.
The GPU row identifies hardware, not a guarantee of GPU acceleration.

You can close the menu while a model or language change is applying. The
microphone keeps pulsing yellow, then flashes green for one second when Ready.
You can dictate immediately; the flash does not add a delay.

## Demo

Video walkthrough coming soon.

<!-- Add a GitHub video attachment URL here. -->

## Keybindings

Inside the panel:

| Key                 | Action                    |
| ------------------- | ------------------------- |
| Arrows or `h/j/k/l` | Move between controls     |
| `Tab` / `Shift+Tab` | Next / previous control   |
| `Enter`             | Activate or open search   |
| `v`                 | Open TUI                  |
| `s`                 | Open settings             |
| `r`                 | Edit replacements         |
| `t`                 | Open transcript history   |
| `q` / `Esc`         | Close the panel or dialog |

While typing in a search field, letters remain ordinary text. In transcript
history, Enter copies the selected entry and Tab moves to
Copy/Delete/Clear/Back. Delete and Clear require confirmation.

The Workflow setup also provides `Ctrl+Insert` for dictation and
`Ctrl+Shift+Insert` for this panel. Desktop shortcuts are configured separately,
not installed by the plugin.

## Word replacements

Select **Replacements** to edit spelling matches in your default editor:

```toml
"heard phrase" = "replacement"
```

Save and close to apply and return to the panel. New pairs append; existing
entries keep their order. Finish dictation before saving.

## Transcript privacy and delivery

The Workflow helper saves each completed, nonempty final transcript before
Voxtype attempts output. It uses private atomic JSON files under
`~/.local/state/voxtype-control/transcripts/`; audio is never retained and
history is never synced automatically. Entries do not expire silently.

The Workflow helper keeps delivery host-local and independent of history. Its
OptiPlex profile can explicitly stage Voxtype paste mode with Shift+Insert;
unvalidated hosts retain type mode.
Automatic and spoken submission are disabled, so text remains an unsent draft.
Paste mode updates the normal clipboard; selecting a history entry copies only
after the clipboard command succeeds. A storage failure allows insertion to
continue, shows a critical notification, and remains visible in the history view.

History remains available while models are unloaded or ASR is unavailable.
Removing the plugin or Workflow helper retains the transcript files. Use the
confirmed Delete/Clear actions when removal is intended.

## Remove

```bash
omarchy plugin remove io.github.ilyazar.voxtype-control
```

This removes the panel, not Voxtype, the helper, transcripts, models, or
replacements.

## Development

See [DEVELOPMENT.md](DEVELOPMENT.md) for the helper contract and tests.

## License

[MIT](LICENSE)
