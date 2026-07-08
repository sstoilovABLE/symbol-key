#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; SymbolKey
; Cycle through your chosen symbols by repeatedly pressing
; a configurable hotkey (default: Shift+4).
; ============================================================

ScriptVersion := "1.0"          ; shown in the Settings window title
SettingsFile := A_ScriptDir "\SymbolKey.ini"
CycleTimeoutMs := 3000          ; cycle resets after this much inactivity

; Built-in symbols: [symbol, description]
DefaultSymbols := [
    ["$", "US Dollar"],
    ["€", "Euro"],
    ["£", "British Pound"],
    ["₹", "Indian Rupee"],
    ["¥", "Yuan / Yen (Renminbi)"],
    ["§", "Section"],
    ["©", "Copyright"],
    ["™", "Trademark"],
]

; Runtime state
ActiveSymbols := []             ; symbols enabled for cycling, in order
CurrentHotkey := ""             ; currently registered hotkey
CycleIndex := 0                 ; 0 = not cycling
LastPressTick := 0
Suppressing := false            ; true while this script is sending its own keystrokes

; Modifier keys are excluded from the "any other key" interrupt set because
; they are held down as part of *composing* the symbol hotkey itself
; (e.g. holding Shift before pressing 4 for Shift+4); they don't represent
; typing a separate key.
ModifierVKs := Map(
    0x10, true, 0x11, true, 0x12, true,     ; Shift, Ctrl, Alt (generic)
    0x5B, true, 0x5C, true,                 ; LWin, RWin
    0xA0, true, 0xA1, true,                 ; L/R Shift
    0xA2, true, 0xA3, true,                 ; L/R Ctrl
    0xA4, true, 0xA5, true,                 ; L/R Alt
)

; GUI globals
SettingsGui := 0
LV := 0
HkCtrl := 0
LastGoodHotkey := ""            ; last complete hotkey shown in the picker
CustomEdit := 0
RowKeys := []                   ; parallel to LV rows: original (unrenamed) name of each row
ExitBtnHwnd := 0                ; used to show a hover tooltip on the Exit Script button

OnMessage(0x0200, WM_MOUSEMOVE)   ; WM_MOUSEMOVE: hover tooltip

LoadSettings()
ApplyHotkey(IniRead(SettingsFile, "General", "Hotkey", "+4"))
RegisterInterruptKeys()

A_TrayMenu.Delete()
A_TrayMenu.Add("Settings", (*) => ShowSettingsGui())
A_TrayMenu.Add("Reload", (*) => Reload())
A_TrayMenu.Add("Exit", (*) => ExitApp())
A_TrayMenu.Default := "Settings"
A_IconTip := "SymbolKey"
iconPath := A_ScriptDir "\SymbolKey.ico"
if !A_IsCompiled && FileExist(iconPath)
    TraySetIcon(iconPath)

; Always show the settings GUI on launch
ShowSettingsGui()

return

; ------------------------------------------------------------
; Hotkey handling
; ------------------------------------------------------------

ApplyHotkey(newHotkey) {
    global CurrentHotkey, CycleIndex
    if (CurrentHotkey != "") {
        try Hotkey(CurrentHotkey, "Off")
    }
    CurrentHotkey := newHotkey
    CycleIndex := 0
    if (newHotkey != "")
        Hotkey(newHotkey, OnSymbolKey, "On")
}

OnSymbolKey(*) {
    global CycleIndex, LastPressTick, ActiveSymbols, Suppressing
    if (ActiveSymbols.Length = 0) {
        ; Nothing enabled: pass the key through as typed
        PassThrough()
        return
    }
    now := A_TickCount
    if (CycleIndex = 0 || now - LastPressTick > CycleTimeoutMs) {
        CycleIndex := 1                     ; start (or restart) the cycle
    } else {
        ; Delete the previously typed symbol, then advance
        prev := ActiveSymbols[CycleIndex]
        Suppressing := true
        Send("{BS " StrLen(prev) "}")
        Suppressing := false
        CycleIndex := Mod(CycleIndex, ActiveSymbols.Length) + 1
    }
    Suppressing := true
    SendText(ActiveSymbols[CycleIndex])
    Suppressing := false
    LastPressTick := now
}

; Registers every keyboard key (except modifiers) as a pass-through hotkey
; that resets the cycle. This way, pressing any other key breaks the "keep
; pressing to cycle" flow immediately, rather than only after the 3-second
; timeout. AHK gives an exact-modifier hotkey (like the symbol hotkey
; itself) precedence over these "*"-wildcard ones for the same keystroke,
; so this doesn't interfere with the symbol hotkey's own key.
RegisterInterruptKeys() {
    global ModifierVKs
    loop 254 {
        vk := A_Index
        if ModifierVKs.Has(vk)
            continue
        try Hotkey(Format("~*vk{:X}", vk), ResetCycle, "On")
    }
}

; Ignore resets caused by this script's own simulated keystrokes (e.g. the
; backspace/retype used while cycling), so cycling doesn't reset itself.
ResetCycle(*) {
    global CycleIndex, Suppressing
    if Suppressing
        return
    CycleIndex := 0
}

PassThrough() {
    global CurrentHotkey, Suppressing
    ; Re-send the hotkey's own key so it behaves normally
    key := RegExReplace(CurrentHotkey, "^[#!^+<>*~$]+")
    mods := SubStr(CurrentHotkey, 1, StrLen(CurrentHotkey) - StrLen(key))
    mods := RegExReplace(mods, "[*~$<>]")   ; strip non-modifier prefixes
    Suppressing := true
    Send("{Blind}" mods "{" key "}")
    Suppressing := false
}

; ------------------------------------------------------------
; Settings persistence
; ------------------------------------------------------------

LoadSettings() {
    global ActiveSymbols, SettingsFile, DefaultSymbols
    ActiveSymbols := []
    if FileExist(SettingsFile) {
        loop {
            sym := IniRead(SettingsFile, "Symbols", "Symbol" A_Index, "")
            if (sym = "")
                break
            ActiveSymbols.Push(sym)
        }
    } else {
        ; Default: dollar, euro, pound
        ActiveSymbols := ["$", "€", "£"]
    }
}

SaveSettings(symbols, hotkeyStr, customSymbols, names) {
    global SettingsFile
    try FileDelete(SettingsFile)
    IniWrite(hotkeyStr, SettingsFile, "General", "Hotkey")
    for i, sym in symbols
        IniWrite(sym, SettingsFile, "Symbols", "Symbol" i)
    for i, entry in customSymbols
        IniWrite(entry[1] "|" entry[2], SettingsFile, "Custom", "Custom" i)
    for entry in names
        IniWrite(entry[2], SettingsFile, "Names", entry[1])
}

LoadCustomSymbols() {
    global SettingsFile
    result := []
    loop {
        raw := IniRead(SettingsFile, "Custom", "Custom" A_Index, "")
        if (raw = "")
            break
        parts := StrSplit(raw, "|", , 2)
        result.Push([parts[1], parts.Length > 1 ? parts[2] : "Custom"])
    }
    return result
}

; Names are keyed as "symbol|originalName" so renaming a symbol persists
; even though two default symbols can share the same glyph (e.g. yuan/yen ¥).
LoadNames() {
    global SettingsFile
    result := Map()
    if !FileExist(SettingsFile)
        return result
    content := IniRead(SettingsFile, "Names", , "")
    if (content = "")
        return result
    for line in StrSplit(content, "`n", "`r") {
        if (line = "")
            continue
        pos := InStr(line, "=")
        if (!pos)
            continue
        result[SubStr(line, 1, pos - 1)] := SubStr(line, pos + 1)
    }
    return result
}

; ------------------------------------------------------------
; Settings GUI
; ------------------------------------------------------------

ShowSettingsGui() {
    global SettingsGui, LV, HkCtrl, LastGoodHotkey, CustomEdit, RowKeys, ExitBtnHwnd
    global DefaultSymbols, ActiveSymbols, CurrentHotkey, SettingsFile, ScriptVersion

    if (SettingsGui is Gui) {
        SettingsGui.Show()
        WinActivate("ahk_id " SettingsGui.Hwnd)
        SetTimer(WatchHotkeyFocus, 30)
        return
    }

    SettingsGui := Gui(, "SymbolKey - Settings (v" ScriptVersion ")")
    SettingsGui.OnEvent("Close", (*) => CloseSettingsGui())

    SettingsGui.Add("Text", "w360", "Edit the symbols to cycle through and set their order.")
    SettingsGui.Add("Text", "w360",
        "Press the hotkey repeatedly to cycle. The cycle resets after "
        Round(CycleTimeoutMs / 1000) " seconds of inactivity, or as soon as "
        "you press any other keyboard key — whichever happens first.")
    LV := SettingsGui.Add("ListView", "w270 r10 Checked -Multi NoSortHdr", ["Symbol", "Name"])
    LV.ModifyCol(1, 55)
    LV.ModifyCol(2, 195)
    LV.OnEvent("DoubleClick", RenameRow)

    ; Build row list: saved order first (enabled), then remaining known symbols
    rows := []          ; [symbol, originalName, enabled]
    known := DefaultSymbols.Clone()
    for entry in LoadCustomSymbols()
        known.Push(entry)
    for sym in ActiveSymbols {
        desc := "Custom"
        for k, entry in known {
            if (entry[1] = sym) {
                desc := entry[2]
                known.RemoveAt(k)
                break
            }
        }
        rows.Push([sym, desc, true])
    }
    for entry in known
        rows.Push([entry[1], entry[2], false])

    names := LoadNames()
    RowKeys := []
    for row in rows {
        displayName := names.Has(row[1] "|" row[2]) ? names[row[1] "|" row[2]] : row[2]
        LV.Add(row[3] ? "Check" : "", row[1], displayName)
        RowKeys.Push(row[2])
    }

    ; Action buttons run vertically to the right of the list to save space and
    ; cut the whitespace a horizontal row left underneath the ListView.
    SettingsGui.Add("Button", "x+10 yp w80", "Move Up").OnEvent("Click", (*) => MoveRow(-1))
    SettingsGui.Add("Button", "xp y+8 w80", "Move Down").OnEvent("Click", (*) => MoveRow(1))
    SettingsGui.Add("Button", "xp y+8 w80", "Rename").OnEvent("Click", RenameClicked)
    SettingsGui.Add("Button", "xp y+8 w80", "Delete").OnEvent("Click", DeleteRow)

    ; Resume the rest of the layout below the ListView, not below the buttons.
    LV.GetPos(&lvX, &lvY, &lvW, &lvH)
    SettingsGui.Add("Text", "xm y" (lvY + lvH + 15), "Add a custom symbol:")
    CustomEdit := SettingsGui.Add("Edit", "x+10 w80 Limit10")
    SettingsGui.Add("Button", "x+10 w60", "Add").OnEvent("Click", AddCustom)

    SettingsGui.Add("Text", "xm y+15", "Hotkey:")
    HkCtrl := SettingsGui.Add("Hotkey", "x+10 w150", CurrentHotkey)
    LastGoodHotkey := CurrentHotkey
    HkCtrl.OnEvent("Change", HotkeyChanged)
    SettingsGui.Add("Text", "xm", "Default hotkey: Shift+4.")
    SettingsGui.Add("Text", "xm w360",
        "Focus the field above and press the key combination you want. A few "
        "keys can't be used on their own — see the README for the list.")

    SettingsGui.Add("Button", "xm y+15 w100 Default", "Save").OnEvent("Click", SaveClicked)
    SettingsGui.Add("Button", "x+10 w100", "Cancel").OnEvent("Click", (*) => CloseSettingsGui())

    ; Plain push buttons ignore custom text color, so a pale red fill is the
    ; simplest reliable stand-in for a "red" button. Right-aligned to the
    ; ListView's right edge (MarginX + its width of 360).
    exitX := SettingsGui.MarginX + 360 - 100
    ExitBtn := SettingsGui.Add("Button", "x" exitX " yp w100 BackgroundFFE0E0", "Exit Script")
    ExitBtn.OnEvent("Click", ExitClicked)
    ExitBtnHwnd := ExitBtn.Hwnd

    ; Watch which control has focus so we can silence the symbol hotkey only
    ; while the hotkey field is focused (see WatchHotkeyFocus).
    SetTimer(WatchHotkeyFocus, 30)

    SettingsGui.Show()
    WinActivate("ahk_id " SettingsGui.Hwnd)
}

; While the hotkey field has keyboard focus, suspend the symbol hotkey and
; the per-key interrupt hotkeys. Otherwise pressing e.g. Shift+4 to *set* the
; hotkey would instead fire the symbol hotkey - swallowing the keystroke
; before the field could see it, which is what made Shift+4 show up as "None".
; The Hotkey control has no Focus/LoseFocus event, so we poll Gui.FocusedCtrl
; (A_IsSuspended is the single source of truth, so this stays correct even
; across window close/reopen).
WatchHotkeyFocus() {
    global SettingsGui, HkCtrl
    onField := false
    if (SettingsGui is Gui) {
        focused := 0
        try focused := SettingsGui.FocusedCtrl
        if (IsObject(focused) && IsObject(HkCtrl))
            try onField := (focused.Hwnd = HkCtrl.Hwnd)
    }
    if (onField && !A_IsSuspended)
        Suspend(true)
    else if (!onField && A_IsSuspended)
        Suspend(false)
}

; The Hotkey control uses Backspace/Delete to clear itself, so those keys (and
; a few unsupported combinations) blank it out to "None". Rather than let that
; stick, restore the last complete hotkey. We debounce first, because while a
; combination is being composed the value is briefly empty (e.g. while only a
; modifier is held) — we only restore if it's *still* incomplete afterwards.
HotkeyChanged(ctrl, *) {
    global LastGoodHotkey
    if IsCompleteHotkey(ctrl.Value)
        LastGoodHotkey := ctrl.Value        ; remember every valid hotkey
    else
        SetTimer(RestoreHotkeyIfIncomplete, -150)
}

RestoreHotkeyIfIncomplete() {
    global HkCtrl, LastGoodHotkey
    try {
        if (IsObject(HkCtrl) && !IsCompleteHotkey(HkCtrl.Value))
            HkCtrl.Value := LastGoodHotkey
    }
}

; A hotkey is "complete" only if it has a non-modifier key, not just modifiers
; (or nothing, which is how the picker represents "None").
IsCompleteHotkey(hk) {
    return hk != "" && RegExReplace(hk, "^[#!^+<>*~$]+") != ""
}

MoveRow(dir) {
    global LV, RowKeys
    row := LV.GetNext(0, "Focused")
    if (!row)
        return
    target := row + dir
    if (target < 1 || target > LV.GetCount())
        return
    ; Swap the two rows (text + check state)
    r1 := [LV.GetText(row, 1), LV.GetText(row, 2), RowChecked(row)]
    r2 := [LV.GetText(target, 1), LV.GetText(target, 2), RowChecked(target)]
    LV.Modify(row, (r2[3] ? "Check" : "-Check") " -Select -Focus", r2[1], r2[2])
    LV.Modify(target, (r1[3] ? "Check" : "-Check") " Select Focus", r1[1], r1[2])
    tmp := RowKeys[row]
    RowKeys[row] := RowKeys[target]
    RowKeys[target] := tmp
}

RowChecked(row) {
    global LV
    return LV.GetNext(row - 1, "Checked") = row
}

RenameRow(ctrl, row) {
    global LV, RowKeys
    if (!row)
        return
    sym := LV.GetText(row, 1)
    current := LV.GetText(row, 2)
    ib := InputBox("Enter a name for " sym ":", "SymbolKey", "w300 h120", current)
    if (ib.Result != "OK")
        return
    newName := Trim(ib.Value)
    if (newName = "")
        newName := RowKeys[row]
    LV.Modify(row, "Select Focus", sym, newName)
}

RenameClicked(*) {
    global LV
    row := LV.GetNext(0, "Focused")
    if (!row) {
        MsgBox("Select a row to rename first.", "SymbolKey", "Iconi")
        return
    }
    RenameRow(0, row)
}

AddCustom(*) {
    global LV, CustomEdit, RowKeys
    sym := Trim(CustomEdit.Value)
    if (sym = "") {
        MsgBox("Enter a symbol first.", "SymbolKey", "Iconi")
        return
    }
    loop LV.GetCount() {
        if (LV.GetText(A_Index, 1) = sym && RowKeys[A_Index] = "Custom") {
            MsgBox("That symbol is already in the list.", "SymbolKey", "Iconi")
            return
        }
    }
    LV.Add("Check", sym, "Custom")
    RowKeys.Push("Custom")
    CustomEdit.Value := ""
}

DeleteRow(*) {
    global LV, RowKeys
    row := LV.GetNext(0, "Focused")
    if (!row) {
        MsgBox("Select a row to delete first.", "SymbolKey", "Iconi")
        return
    }
    LV.Delete(row)
    RowKeys.RemoveAt(row)
}

SaveClicked(*) {
    global ActiveSymbols
    if !ApplySettingsFromGui()
        return
    CloseSettingsGui()
    TrayTip("Settings saved. Press your hotkey to cycle: " JoinArr(ActiveSymbols, " "), "SymbolKey")
}

; Closes the window: stop watching for focus and make sure the app's hotkeys
; are re-enabled in case it was closed while the hotkey field held focus.
CloseSettingsGui() {
    global SettingsGui
    SetTimer(WatchHotkeyFocus, 0)
    SetTimer(RestoreHotkeyIfIncomplete, 0)
    Suspend(false)
    if (SettingsGui is Gui) {
        SettingsGui.Destroy()
        SettingsGui := 0
    }
}

ExitClicked(*) {
    if !ApplySettingsFromGui()
        return
    ExitApp()
}

; Reads the settings GUI controls, validates and applies them, and writes
; them to the .ini. Returns true on success, false if validation failed
; (in which case the GUI is left open so the user can fix it).
ApplySettingsFromGui() {
    global LV, HkCtrl, ActiveSymbols, CycleIndex, RowKeys, CurrentHotkey
    symbols := []
    customs := []
    names := []
    loop LV.GetCount() {
        sym := LV.GetText(A_Index, 1)
        name := LV.GetText(A_Index, 2)
        orig := RowKeys[A_Index]
        if (orig = "Custom")
            customs.Push([sym, "Custom"])
        if (name != orig)
            names.Push([sym "|" orig, name])
        if RowChecked(A_Index)
            symbols.Push(sym)
    }
    if (symbols.Length = 0) {
        MsgBox("Select at least one symbol.", "SymbolKey", "Icon!")
        return false
    }
    ; A blank value means the picker is showing "None" (e.g. the user pressed a
    ; combination it can't record, like Ctrl+Backspace). Keep the last working
    ; hotkey instead of clearing it or falling back to the default.
    hk := HkCtrl.Value != "" ? HkCtrl.Value : (CurrentHotkey != "" ? CurrentHotkey : "+4")
    try {
        ApplyHotkey(hk)
    } catch as e {
        MsgBox("Could not register that hotkey: " e.Message, "SymbolKey", "Icon!")
        return false
    }
    ActiveSymbols := symbols
    CycleIndex := 0
    SaveSettings(symbols, hk, customs, names)
    return true
}

; Shows a tooltip while hovering the Exit Script button.
WM_MOUSEMOVE(wParam, lParam, msg, hwnd) {
    global ExitBtnHwnd
    static shown := false
    if (ExitBtnHwnd && hwnd = ExitBtnHwnd) {
        if !shown {
            ToolTip("Saves your current settings, then exits SymbolKey")
            shown := true
        }
    } else if shown {
        ToolTip()
        shown := false
    }
}

JoinArr(arr, sep) {
    out := ""
    for i, v in arr
        out .= (i > 1 ? sep : "") v
    return out
}
