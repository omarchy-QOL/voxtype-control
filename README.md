# Voxtype Control for Omarchy

Local dictation controls in the Omarchy bar. Choose a speech model, switch
spoken languages, and edit word replacements without leaving your desktop.

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
- **Right-click**, or select **Voxtype TUI**, to open Voxtype's terminal menu
  for model downloads and configuration.

Parakeet v3 recognizes languages automatically. Canary requires **English** or
**German**; select one before loading. Available choices depend on the model.

The header shows the current model; dropdowns show your pending selection.
The GPU row identifies hardware, not a guarantee of GPU acceleration.

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
| `V`                 | Open Voxtype TUI          |
| `S`                 | Open settings             |
| `R`                 | Edit replacements         |
| `Q` / `Esc`         | Close the panel or dialog |

While typing in a search field, letters remain ordinary text.

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

## Remove

```bash
omarchy plugin remove io.github.ilyazar.voxtype-control
```

This removes the panel, not Voxtype, the helper, your models, or replacements.

## Development

See [DEVELOPMENT.md](DEVELOPMENT.md) for the helper contract and tests.

## License

[MIT](LICENSE)
