#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; Currency Switcher
; Cycle through your chosen currency symbols by repeatedly
; pressing the currency hotkey (default: Shift+4).
; ============================================================

SettingsFile := A_ScriptDir "\settings.ini"
CycleTimeoutMs := 3000          ; cycle resets after this much inactivity

; Built-in symbols: [symbol, description]
DefaultSymbols := [
    ["$", "US Dollar"],
    ["€", "Euro"],
    ["£", "British Pound"],
    ["₹", "Indian Rupee"],
    ["¥", "Chinese Yuan (Renminbi)"],
    ["¥", "Japanese Yen"],
]

; Runtime state
ActiveSymbols := []             ; symbols enabled for cycling, in order
CurrentHotkey := ""             ; currently registered hotkey
CycleIndex := 0                 ; 0 = not cycling
LastPressTick := 0

; GUI globals
SettingsGui := 0
LV := 0
HkCtrl := 0
CustomEdit := 0

LoadSettings()
ApplyHotkey(IniRead(SettingsFile, "General", "Hotkey", "+4"))

A_TrayMenu.Delete()
A_TrayMenu.Add("Settings", (*) => ShowSettingsGui())
A_TrayMenu.Add("Reload", (*) => Reload())
A_TrayMenu.Add("Exit", (*) => ExitApp())
A_TrayMenu.Default := "Settings"
A_IconTip := "Currency Switcher"

; Show the GUI on first run (no settings saved yet)
if !FileExist(SettingsFile)
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
        Hotkey(newHotkey, OnCurrencyKey, "On")
}

OnCurrencyKey(*) {
    global CycleIndex, LastPressTick, ActiveSymbols
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
        Send("{BS " StrLen(prev) "}")
        CycleIndex := Mod(CycleIndex, ActiveSymbols.Length) + 1
    }
    SendText(ActiveSymbols[CycleIndex])
    LastPressTick := now
}

PassThrough() {
    global CurrentHotkey
    ; Re-send the hotkey's own key so it behaves normally
    key := RegExReplace(CurrentHotkey, "^[#!^+<>*~$]+")
    mods := SubStr(CurrentHotkey, 1, StrLen(CurrentHotkey) - StrLen(key))
    mods := RegExReplace(mods, "[*~$<>]")   ; strip non-modifier prefixes
    Send("{Blind}" mods "{" key "}")
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

SaveSettings(symbols, hotkeyStr, customSymbols) {
    global SettingsFile
    try FileDelete(SettingsFile)
    IniWrite(hotkeyStr, SettingsFile, "General", "Hotkey")
    for i, sym in symbols
        IniWrite(sym, SettingsFile, "Symbols", "Symbol" i)
    for i, entry in customSymbols
        IniWrite(entry[1] "|" entry[2], SettingsFile, "Custom", "Custom" i)
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

; ------------------------------------------------------------
; Settings GUI
; ------------------------------------------------------------

ShowSettingsGui() {
    global SettingsGui, LV, HkCtrl, CustomEdit
    global DefaultSymbols, ActiveSymbols, CurrentHotkey, SettingsFile

    if (SettingsGui is Gui) {
        SettingsGui.Show()
        return
    }

    SettingsGui := Gui(, "Currency Switcher – Settings")
    SettingsGui.OnEvent("Close", (*) => (SettingsGui.Destroy(), SettingsGui := 0))

    SettingsGui.Add("Text", , "Check the symbols to cycle through and set their order:")
    LV := SettingsGui.Add("ListView", "w360 r10 Checked -Multi NoSortHdr", ["Symbol", "Currency"])
    LV.ModifyCol(1, 80)
    LV.ModifyCol(2, 250)

    ; Build row list: saved order first (enabled), then remaining known symbols
    rows := []          ; [symbol, description, enabled]
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
    for row in rows
        LV.Add(row[3] ? "Check" : "", row[1], row[2])

    SettingsGui.Add("Button", "xm w80", "Move Up").OnEvent("Click", (*) => MoveRow(-1))
    SettingsGui.Add("Button", "x+10 w80", "Move Down").OnEvent("Click", (*) => MoveRow(1))
    SettingsGui.Add("Button", "x+10 w110", "Remove Custom").OnEvent("Click", RemoveCustom)

    SettingsGui.Add("Text", "xm y+15", "Add a custom symbol:")
    CustomEdit := SettingsGui.Add("Edit", "x+10 w80 Limit10")
    SettingsGui.Add("Button", "x+10 w60", "Add").OnEvent("Click", AddCustom)

    SettingsGui.Add("Text", "xm y+15", "Hotkey:")
    HkCtrl := SettingsGui.Add("Hotkey", "x+10 w150", CurrentHotkey)
    SettingsGui.Add("Text", "xm", "(Default is Shift+4. Leave as-is unless you want a different key.)")

    SettingsGui.Add("Button", "xm y+15 w100 Default", "Save").OnEvent("Click", SaveClicked)
    SettingsGui.Add("Button", "x+10 w100", "Cancel").OnEvent("Click", (*) => (SettingsGui.Destroy(), SettingsGui := 0))
    SettingsGui.Show()
}

MoveRow(dir) {
    global LV
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
}

RowChecked(row) {
    global LV
    return LV.GetNext(row - 1, "Checked") = row
}

AddCustom(*) {
    global LV, CustomEdit
    sym := Trim(CustomEdit.Value)
    if (sym = "") {
        MsgBox("Enter a symbol first.", "Currency Switcher", "Iconi")
        return
    }
    loop LV.GetCount() {
        if (LV.GetText(A_Index, 1) = sym && LV.GetText(A_Index, 2) = "Custom") {
            MsgBox("That symbol is already in the list.", "Currency Switcher", "Iconi")
            return
        }
    }
    LV.Add("Check", sym, "Custom")
    CustomEdit.Value := ""
}

RemoveCustom(*) {
    global LV
    row := LV.GetNext(0, "Focused")
    if (!row)
        return
    if (LV.GetText(row, 2) != "Custom") {
        MsgBox("Only custom symbols can be removed. Uncheck built-in symbols to disable them.", "Currency Switcher", "Iconi")
        return
    }
    LV.Delete(row)
}

SaveClicked(*) {
    global LV, HkCtrl, SettingsGui, ActiveSymbols, CycleIndex
    symbols := []
    customs := []
    loop LV.GetCount() {
        sym := LV.GetText(A_Index, 1)
        if (LV.GetText(A_Index, 2) = "Custom")
            customs.Push([sym, "Custom"])
        if RowChecked(A_Index)
            symbols.Push(sym)
    }
    if (symbols.Length = 0) {
        MsgBox("Select at least one symbol.", "Currency Switcher", "Icon!")
        return
    }
    hk := HkCtrl.Value != "" ? HkCtrl.Value : "+4"
    try {
        ApplyHotkey(hk)
    } catch as e {
        MsgBox("Could not register that hotkey: " e.Message, "Currency Switcher", "Icon!")
        return
    }
    ActiveSymbols := symbols
    CycleIndex := 0
    SaveSettings(symbols, hk, customs)
    SettingsGui.Destroy()
    SettingsGui := 0
    TrayTip("Settings saved. Press your hotkey to cycle: " JoinArr(symbols, " "), "Currency Switcher")
}

JoinArr(arr, sep) {
    out := ""
    for i, v in arr
        out .= (i > 1 ? sep : "") v
    return out
}
