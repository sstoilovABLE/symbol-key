# Currency Switcher

A tiny AutoHotkey v2 script for Windows that lets you cycle through currency symbols with a single hotkey.

I used to Google-search things like "gbp symbol" or "euro symbol" and copy-paste the symbol from there whenever I needed the symbol, but that felt roundabout and time-consuming. That is why I wrote this utility.

People online often recommend key remapping tools, but the reality is that in something like Microsoft PowerToys, the remapping setting only lets you remap a single key, not a combination like `Shift + 4`. On top of that, key remapping utilities do not give you the flexibility to cycle through symbols of your choice the way this utility does.

## Features

- Cycle through currency symbols by repeatedly pressing a hotkey (default `Shift+4`)
- Built-in symbols/examples: $ (US Dollar), € (Euro), £ (British Pound), ₹ (Indian Rupee), ¥ (Chinese Yuan / Japanese Yen), § (Section), © (Copyright), ™ (Trademark)
- Add your own custom symbols
- Enable/disable symbols and reorder them to control the cycle order
- Choose any hotkey you like via a standard hotkey picker
- Settings persist automatically between sessions
- Runs quietly from the system tray

## Requirements

- Windows
- [AutoHotkey v2.0+](https://www.autohotkey.com)

## Installation & Usage

1. Download and install [AutoHotkey v2](https://www.autohotkey.com).
2. Download `CurrencySwitcher.ahk` from this repo.
3. Double-click `CurrencySwitcher.ahk` to run it. On first run, the Settings window opens automatically so you can configure your symbols and hotkey.
4. Press the hotkey (default `Shift+4`) anywhere to type a currency symbol.

To have the script start automatically when you log in, create a shortcut to `CurrencySwitcher.ahk` and place it in your Windows Startup folder (`shell:startup`).

## Configuration

Right-click the tray icon and choose **Settings** to open the configuration window at any time. From there you can:

- **Enable/disable symbols** — check or uncheck symbols in the list to include or exclude them from the cycle.
- **Reorder symbols** — select a symbol and use **Move Up** / **Move Down** to change its position; the list order is the cycle order.
- **Add a custom symbol** — type it into the text field and click **Add**. Custom symbols can also be removed.
- **Change the hotkey** — focus the hotkey field and press the key combination you want (default `Shift+4`). See [Hotkeys that can't be set](#hotkeys-that-cant-be-set) for combinations the hotkey picker doesn't accept.

All settings are saved to `CurrencySwitcher.ini`, stored next to the script, and are loaded automatically the next time it runs. You can safely delete the `.ini` - it will be recreated the next time you run the script.

### Hotkeys that can't be set

The hotkey picker is a standard Windows control, and it doesn't accept a few combinations. If you press one of these, the field reverts to your last hotkey rather than clearing:

- **A modifier key on its own** — `Shift`, `Ctrl` or `Alt` by themselves. A hotkey needs a normal key in addition to any modifiers.
- **`Ctrl + Tab`** — reserved by Windows for switching between tabs/windows.
- **Anything combined with `Backspace` or `Delete`** — e.g. `Shift + Backspace`, `Ctrl + Delete`. The picker uses `Backspace`/`Delete` to clear the field, so it can't record them as part of a hotkey.

Pick a different combination (for example a letter, digit, or function key, optionally with modifiers) for these cases.

The tray icon menu also offers **Reload** (restart the script after editing settings or the file) and **Exit**.

## How cycling works

Each press of the hotkey either types the next symbol or replaces the one just typed, depending on timing:

- **First press**: types the first enabled symbol in your configured order, e.g. `$`.
- **Press again within the 3-second window**: the script backspaces the previous symbol and types the next one in order, e.g. `$` becomes `€`.
- **Keep pressing**: continues advancing through the list, e.g. `€` becomes `£`.
- **One more press**: cycles back to the beginning, e.g. `£` becomes `$` again.

### When the cycle resets

The cycle resets — so the next press starts over from the first symbol — as soon as either of these happens, whichever comes first:

- **The 3-second window elapses.** If you don't press the hotkey again within **3 seconds**, the cycle ends and the next press starts fresh.
- **You press any other keyboard key.** Typing anything else — including arrow keys, Home/End, Page Up/Down, Delete, Enter, Tab, Escape, or any regular character — ends the cycle immediately, so your next hotkey press inserts the first symbol (`$`) again instead of continuing where the cycle left off. (Holding a modifier key like Shift or Ctrl by itself doesn't count, since that's how you hold the hotkey down in the first place.)

This 3-second window is also noted in the Settings window for reference.

## Notes / Limitations

- Some applications handle simulated backspace or Unicode input differently, which can occasionally leave stray characters or fail to delete cleanly.
- Secure/password input fields may block simulated keystrokes entirely, preventing the script from working there.
- Custom symbols made up of multiple code units (e.g. some emoji) may not always delete cleanly with a single backspace in every application.

## License

MIT — see [LICENSE](LICENSE).
