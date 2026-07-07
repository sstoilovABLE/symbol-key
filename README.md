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
- **Change the hotkey** — use the hotkey picker control to record a new key combination (default `Shift+4`).

All settings are saved to `CurrencySwitcher.ini`, stored next to the script, and are loaded automatically the next time it runs. You can safely delete the `.ini` - it will be recreated the next time you run the script.

The tray icon menu also offers **Reload** (restart the script after editing settings or the file) and **Exit**.

## How cycling works

Each press of the hotkey either types the next symbol or replaces the one just typed, depending on timing:

- **First press**: types the first enabled symbol in your configured order, e.g. `$`.
- **Press again within ~3 seconds**: the script backspaces the previous symbol and types the next one in order, e.g. `$` becomes `€`.
- **Keep pressing**: continues advancing through the list, e.g. `€` becomes `£`.
- **One more press**: cycles back to the beginning, e.g. `£` becomes `$` again.

The cycle resets — so the next press starts over from the first symbol — after about 3 seconds without pressing the hotkey. If you type other text in between presses within that window, press elsewhere or wait a moment before starting a new cycle.

## Notes / Limitations

- Some applications handle simulated backspace or Unicode input differently, which can occasionally leave stray characters or fail to delete cleanly.
- Secure/password input fields may block simulated keystrokes entirely, preventing the script from working there.
- Custom symbols made up of multiple code units (e.g. some emoji) may not always delete cleanly with a single backspace in every application.

## License

MIT — see [LICENSE](LICENSE).
