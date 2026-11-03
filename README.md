# Voxtype Control for Omarchy

Local dictation controls in the Omarchy bar. Switch between Voxtype and Hex,
choose a speech model and spoken language, recover completed transcripts, and
edit word replacements without leaving your desktop.

## Screenshot

Coming soon.

<!-- Add the screenshot: ![Voxtype model and language controls](preview.png) -->

## Install

Requires Omarchy Quattro, Voxtype with local models, and the separate
`dictation-control` helper (schema 5). The helper and models are **not
bundled**; this plugin needs an already-configured Voxtype setup. Hex is
optional: install `hex-bin` and run `hex model install` to offer it.

```bash
omarchy plugin add https://github.com/omarchy-QOL/voxtype-control --enable
```

### Stock dictation indicator

This plugin does not automatically replace the stock dictation indicator on
Omarchy versions that still ship one.
To show only the plugin microphone, remove `Dictation` from the
`omarchy.indicators` entry's `items` array in `~/.config/omarchy/shell.json`.
Disabling or removing the plugin does not restore that entry automatically
(you have to add it back manually).

## Use

- **Left-click** the microphone to open model and language controls.
- Choose **Voxtype** or **Hex** in the header dropdown to switch dictation. The
  old backend unloads first and the new one loads its last model. The panel,
  replacements and transcript history stay the same.
- Choose an installed model and language, then select **Apply model/language**.
- Click **[C]opy last transcript**, or press `c`, to copy the newest completed
  transcript directly to the clipboard, without opening history. This uses the
  same copy action as Enter in history, independent of its search filter.
- Wait for **Ready** before dictating. Finish dictation before switching.
- Select the red eject icon to unload the current model. Its files stay on disk.
- Select **Transcripts** to search, review, copy, or explicitly delete completed
  dictations. Click an entry or press Enter to copy it; arrow-key browsing does
  not copy. Use the mouse wheel or scrollbar to read long transcripts.
  Highlighting text with the mouse copies that selection on release and shows a
  short in-panel confirmation. Full-entry copies flash the row yellow, send a
  five-second desktop notification, then ask whether to close the plugin. **Yes**
  is selected by default so Enter closes it and restores the previous focus;
  use `h`/`l` to choose, or press Esc for **No**.
- **Right-click**, or use the first footer shortcut, to manage models:
  `[v]oxtype tui` opens Voxtype's terminal menu and `[m]odels` opens Hex's model
  picker.

The footer contains that shortcut, `[s]ettings`,
`[r]eplacements` and `[t]ranscripts`. Bracketed keys use the system theme's
yellow. Click a label or press its key; Tab and arrow navigation also work.
A divider separates the footer. The panel fits the footer and the two equally
high primary buttons without clipping their labels.

Parakeet v3 recognizes languages automatically. Canary requires **English** or
**German**; select one before loading. Available choices depend on the model.
Hex has no Canary support.

The header shows the current model; dropdowns show your pending selection.
The GPU row identifies hardware, not a guarantee of GPU acceleration.

You can close the menu while a model or language change is applying. The
microphone keeps pulsing yellow, then flashes green for one second when Ready.
The hover tooltip also shows **Switching** in theme yellow and **Ready** in green.
You can dictate immediately; the flash does not add a delay.

Recording failures show a critical desktop notification. The microphone icon
also pulses yellow for five seconds so failures from a desktop shortcut remain
visible without a terminal.

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
| `c`                 | Copy last transcript      |
| `v` or `m`          | Voxtype TUI or Hex models |
| `s`                 | Open settings             |
| `r`                 | Edit replacements         |
| `t`                 | Open transcript history   |
| `q` / `Esc`         | Close the panel or dialog |

While typing in a search field, letters remain ordinary text. In transcript
history, arrow keys move, Enter copies, `Ctrl+D` deletes the selected entry,
and `Ctrl+Shift+D` deletes all transcript history. Both deletions require
confirmation. After a successful full-entry copy, `h`/`l` chooses whether to
close the plugin, Enter accepts the default **Yes**, and Esc means **No**.

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
either backend attempts output. Hex's own history stays off so there is one
store. It uses private atomic JSON files under
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
confirmed `Ctrl+D` or `Ctrl+Shift+D` actions when removal is intended. The
explicit `history clear` CLI command remains available.

## Remove

```bash
omarchy plugin remove omarchy-qol.voxtype-control
```

This removes the panel, not Voxtype, the helper, transcripts, models, or
replacements. If you hid the stock dictation indicator, add `Dictation` back
as described above.

## Development

See [DEVELOPMENT.md](DEVELOPMENT.md) for the helper contract and tests.

## License

[MIT](LICENSE)
