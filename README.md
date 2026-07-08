# SymbolKey

<div style="float: left; margin-right: 16px; margin-bottom: 8px;">
  <img src="compilation-assets/SymbolKey-icon-128-256.png" alt="SymbolKey logo" width="128" />
</div>

SymbolKey is a tiny AutoHotkey v2 utility for Windows that lets you type hard-to-reach symbols with one hotkey.

Press your chosen hotkey once to insert the first enabled symbol. Press it again within the short cycling window and SymbolKey replaces that symbol with the next one in your list. This makes one key combination work for symbols you might otherwise search for, copy, paste, or memorize Alt codes for.

It works well for currency symbols such as `$`, `€`, `£`, `₹`, and `¥`, but it is not limited to money. You can use it for legal marks, typographic marks, math symbols, arrows, emoji, or any custom symbol you add.

## Why SymbolKey exists

I kept searching the web for things like "gbp symbol", "euro symbol", "rupee symbol", "yen symbol", "copyright symbol", and "section sign", then copying the character from the results. That is slow for something that should take one keystroke.

Key remapping tools help with simple substitutions, but they usually map one key or key combination to one output. SymbolKey is different: one configurable hotkey can cycle through a list of symbols that you control.

## Features

- Type useful symbols from any app with a single configurable hotkey.
- Press the hotkey repeatedly to cycle through enabled symbols in order.
- Built-in examples include `$`, `€`, `£`, `₹`, `¥`, `§`, `©`, and `™`.
- Add your own symbols, rename them, enable or disable them, and reorder the cycle.
- Choose your own hotkey with a standard Windows hotkey picker.
- Settings persist automatically between sessions.
- Runs quietly from the Windows system tray.

## Good Uses

| Use case | Examples |
| --- | --- |
| Prices and invoices | `$`, `€`, `£`, `₹`, `¥` |
| Legal or business text | `§`, `©`, `™`, `®` |
| Editing and writing | `–`, `—`, `…`, `•` |
| Notes and checklists | `→`, `✓`, `✗`, `★` |
| Math and technical notes | `±`, `×`, `÷`, `≤`, `≥` |
| Personal shortcuts | Any symbol or short Unicode text you add |

## Requirements

- Windows
- [AutoHotkey v2.0+](https://www.autohotkey.com)

## Installation & Usage

1. Download and install [AutoHotkey v2](https://www.autohotkey.com).
2. Download `SymbolKey.ahk` from this repo.
3. Double-click `SymbolKey.ahk` to run it.
4. On first run, the Settings window opens automatically so you can configure your symbols and hotkey.
5. Press the hotkey anywhere to type the first enabled symbol. The default hotkey is `Shift+4`.
6. Press the hotkey again within 3 seconds to replace the symbol with the next enabled symbol.

To start SymbolKey automatically when you log in, create a shortcut to `SymbolKey.ahk` and place it in your Windows Startup folder (`shell:startup`).

## Configuration

Right-click the tray icon and choose **Settings** to open the configuration window at any time.

| Setting | What it does |
| --- | --- |
| Enable or disable symbols | Check or uncheck symbols to include or exclude them from the cycle. |
| Reorder symbols | Select a row and use **Move Up** or **Move Down**. The list order is the cycle order. |
| Rename symbols | Double-click a row or select it and click **Rename**. |
| Add a custom symbol | Type the symbol into the text field and click **Add**. |
| Delete a custom symbol | Select the custom row and click **Delete**. |
| Change the hotkey | Focus the hotkey field and press the key combination you want. |

All settings are saved to `SymbolKey.ini`, stored next to the script, and loaded automatically the next time SymbolKey runs. You can safely delete the `.ini` file; it will be recreated on the next run.

## Hotkeys That Can't Be Set

The hotkey picker is a standard Windows control, and it does not accept a few combinations. If you press one of these, the field reverts to your last valid hotkey rather than clearing:

| Hotkey type | Why it does not work |
| --- | --- |
| A modifier key on its own, such as `Shift`, `Ctrl`, or `Alt` | A hotkey needs a normal key in addition to any modifiers. |
| `Ctrl+Tab` | Windows reserves it for switching between tabs or windows. |
| Anything combined with `Backspace` or `Delete` | The picker uses those keys to clear the field, so it cannot record them as part of a hotkey. |

Pick a different combination, such as a letter, digit, or function key with optional modifiers.

The tray icon menu also offers **Reload** to restart the script after editing settings or the file, and **Exit** to close SymbolKey.

## How Cycling Works

Each hotkey press either types the next symbol or replaces the one just typed, depending on timing:

1. First press: types the first enabled symbol in your configured order, such as `$`.
2. Press again within 3 seconds: SymbolKey backspaces the previous symbol and types the next one, such as replacing `$` with `€`.
3. Keep pressing: SymbolKey continues through the list, such as `€` to `£` to `₹`.
4. After the last enabled symbol: SymbolKey cycles back to the beginning.

### When The Cycle Resets

The cycle resets, so the next hotkey press starts over from the first symbol, as soon as either of these happens:

| Reset trigger | Result |
| --- | --- |
| The 3-second window elapses | The next hotkey press starts a new cycle from the first enabled symbol. |
| You press any other keyboard key | The current cycle ends immediately. This includes arrows, Home/End, Page Up/Down, Delete, Enter, Tab, Escape, and regular characters. |

Holding a modifier key such as `Shift` or `Ctrl` by itself does not reset the cycle, since modifiers are commonly held while pressing a hotkey.

## Troubleshooting

| Problem | What to try |
| --- | --- |
| A symbol does not appear in one app | Try another app first. Some apps handle simulated Unicode input differently. |
| Cycling leaves a stray character | The target app may not process simulated backspace cleanly. Increase caution with multi-code-unit symbols such as some emoji. |
| Nothing types in a password box or secure field | Secure fields may block simulated keystrokes by design. |
| The hotkey field shows `None` while setting a hotkey | Choose a supported combination. `Backspace`, `Delete`, lone modifiers, and some reserved Windows shortcuts cannot be captured. |
| Settings disappeared | Check whether `SymbolKey.ini` is next to `SymbolKey.ahk`. If it is missing, SymbolKey recreates it with defaults. |

## FAQ

### Can SymbolKey type currency symbols?

Yes. The defaults include common currency-symbol examples like `$`, `€`, `£`, `₹`, and `¥`, and you can add others.

### Can I use it for non-currency symbols?

Yes. SymbolKey can insert any symbol or short Unicode text that AutoHotkey can send with `SendText`.

### Is this the same as an Alt-code tool?

No. Alt codes require remembering numeric codes and can vary by environment. SymbolKey gives you one configurable hotkey and a visible list of symbols.

### Can I change the default `Shift+4` hotkey?

Yes. Open **Settings**, focus the hotkey field, and press the new key combination.

### Where are settings stored?

Settings are stored in `SymbolKey.ini` next to the script.

## Notes / Limitations

- Some applications handle simulated backspace or Unicode input differently, which can occasionally leave stray characters or fail to delete cleanly.
- Secure/password input fields may block simulated keystrokes entirely.
- Custom symbols made up of multiple code units, such as some emoji, may not always delete cleanly with a single backspace in every application.
- The project icon PNGs were generated with help from Claude Code. The `.ico` file was created manually with Greenfish Icon Editor Pro so the compiled executable can use the different PNGs at different icon sizes.

## License

MIT - see [LICENSE](LICENSE).
