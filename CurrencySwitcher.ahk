#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; Currency Switcher
; Cycle through your chosen currency symbols by repeatedly
; pressing the currency hotkey (default: Shift+4).
; ============================================================

SettingsFile := A_ScriptDir "\CurrencySwitcher.ini"
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
RowKeys := []                   ; parallel to LV rows: original (unrenamed) name of each row
ExitBtnHwnd := 0                ; used to show a hover tooltip on the Exit Script button

OnMessage(0x0200, WM_MOUSEMOVE)   ; WM_MOUSEMOVE: hover tooltip
OnMessage(0x002B, WM_DRAWITEM)    ; WM_DRAWITEM: paint the red Exit Script button

LoadSettings()
ApplyHotkey(IniRead(SettingsFile, "General", "Hotkey", "+4"))

A_TrayMenu.Delete()
A_TrayMenu.Add("Settings", (*) => ShowSettingsGui())
A_TrayMenu.Add("Reload", (*) => Reload())
A_TrayMenu.Add("Exit", (*) => ExitApp())
A_TrayMenu.Default := "Settings"
A_IconTip := "Currency Switcher"

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
; even though two default symbols can share the same glyph (e.g. ¥).
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
    global SettingsGui, LV, HkCtrl, CustomEdit, RowKeys, ExitBtnHwnd
    global DefaultSymbols, ActiveSymbols, CurrentHotkey, SettingsFile

    if (SettingsGui is Gui) {
        SettingsGui.Show()
        return
    }

    SettingsGui := Gui(, "Currency Switcher – Settings")
    SettingsGui.OnEvent("Close", (*) => (SettingsGui.Destroy(), SettingsGui := 0))

    SettingsGui.Add("Text", , "Check the symbols to cycle through and set their order. Double-click a name to rename it:")
    LV := SettingsGui.Add("ListView", "w360 r10 Checked -Multi NoSortHdr", ["Symbol", "Name"])
    LV.ModifyCol(1, 80)
    LV.ModifyCol(2, 250)
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

    SettingsGui.Add("Button", "xm w80", "Move Up").OnEvent("Click", (*) => MoveRow(-1))
    SettingsGui.Add("Button", "x+10 w80", "Move Down").OnEvent("Click", (*) => MoveRow(1))
    SettingsGui.Add("Button", "x+10 w80", "Rename").OnEvent("Click", RenameClicked)
    SettingsGui.Add("Button", "x+10 w80", "Delete").OnEvent("Click", DeleteRow)

    SettingsGui.Add("Text", "xm y+15", "Add a custom symbol:")
    CustomEdit := SettingsGui.Add("Edit", "x+10 w80 Limit10")
    SettingsGui.Add("Button", "x+10 w60", "Add").OnEvent("Click", AddCustom)

    SettingsGui.Add("Text", "xm y+15", "Hotkey:")
    HkCtrl := SettingsGui.Add("Hotkey", "x+10 w150", CurrentHotkey)
    SettingsGui.Add("Text", "xm", "(Default is Shift+4. Leave as-is unless you want a different key.)")

    SettingsGui.Add("Button", "xm y+15 w100 Default", "Save").OnEvent("Click", SaveClicked)
    CancelBtn := SettingsGui.Add("Button", "x+10 w100", "Cancel")
    CancelBtn.OnEvent("Click", (*) => (SettingsGui.Destroy(), SettingsGui := 0))

    ; Plain Win32 push buttons ignore any custom text/background color, themed or not -
    ; only owner-drawn buttons actually let us paint red text/border ourselves (see
    ; WM_DRAWITEM below). Right-aligned to the ListView's right edge.
    CancelBtn.GetPos(&cbY,, , &cbH)
    LV.GetPos(&lvX,, &lvW)
    exitX := lvX + lvW - 100
    ExitBtn := SettingsGui.Add("Button", "x" exitX " y" cbY " w100 h" cbH " +0x0B", "Exit Script")
    ExitBtn.OnEvent("Click", ExitClicked)
    ExitBtnHwnd := ExitBtn.Hwnd
    SettingsGui.Show()
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
    ib := InputBox("Enter a name for " sym ":", "Currency Switcher", "w300 h120", current)
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
        MsgBox("Select a row to rename first.", "Currency Switcher", "Iconi")
        return
    }
    RenameRow(0, row)
}

AddCustom(*) {
    global LV, CustomEdit, RowKeys
    sym := Trim(CustomEdit.Value)
    if (sym = "") {
        MsgBox("Enter a symbol first.", "Currency Switcher", "Iconi")
        return
    }
    loop LV.GetCount() {
        if (LV.GetText(A_Index, 1) = sym && RowKeys[A_Index] = "Custom") {
            MsgBox("That symbol is already in the list.", "Currency Switcher", "Iconi")
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
        MsgBox("Select a row to delete first.", "Currency Switcher", "Iconi")
        return
    }
    LV.Delete(row)
    RowKeys.RemoveAt(row)
}

SaveClicked(*) {
    global SettingsGui, ActiveSymbols
    if !ApplySettingsFromGui()
        return
    SettingsGui.Destroy()
    SettingsGui := 0
    TrayTip("Settings saved. Press your hotkey to cycle: " JoinArr(ActiveSymbols, " "), "Currency Switcher")
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
    global LV, HkCtrl, ActiveSymbols, CycleIndex, RowKeys
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
        MsgBox("Select at least one symbol.", "Currency Switcher", "Icon!")
        return false
    }
    hk := HkCtrl.Value != "" ? HkCtrl.Value : "+4"
    try {
        ApplyHotkey(hk)
    } catch as e {
        MsgBox("Could not register that hotkey: " e.Message, "Currency Switcher", "Icon!")
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
            ToolTip("Saves your current settings, then exits Currency Switcher")
            shown := true
        }
    } else if shown {
        ToolTip()
        shown := false
    }
}

; Custom-paints the owner-drawn Exit Script button with a red border/text,
; since regular push buttons ignore custom colors entirely.
WM_DRAWITEM(wParam, lParam, msg, hwnd) {
    global ExitBtnHwnd
    if !ExitBtnHwnd
        return

    hwndItem := NumGet(lParam, 24, "ptr")
    if (hwndItem != ExitBtnHwnd)
        return

    hDC := NumGet(lParam, 32, "ptr")
    left := NumGet(lParam, 40, "int")
    top := NumGet(lParam, 44, "int")
    right := NumGet(lParam, 48, "int")
    bottom := NumGet(lParam, 52, "int")
    itemState := NumGet(lParam, 16, "uint")
    pressed := itemState & 0x0001   ; ODS_SELECTED

    rect := Buffer(16, 0)
    NumPut("int", left, rect, 0), NumPut("int", top, rect, 4)
    NumPut("int", right, rect, 8), NumPut("int", bottom, rect, 12)

    fillColor := pressed ? 0xE0C0C0 : 0xF6DEDE
    hBrush := DllCall("gdi32\CreateSolidBrush", "uint", BGR(fillColor), "ptr")
    DllCall("user32\FillRect", "ptr", hDC, "ptr", rect, "ptr", hBrush)
    DllCall("gdi32\DeleteObject", "ptr", hBrush)

    hPen := DllCall("gdi32\CreatePen", "int", 0, "int", 2, "uint", BGR(0xC00000), "ptr")
    hNullBrush := DllCall("gdi32\GetStockObject", "int", 5, "ptr")   ; NULL_BRUSH
    hOldPen := DllCall("gdi32\SelectObject", "ptr", hDC, "ptr", hPen, "ptr")
    hOldBrush := DllCall("gdi32\SelectObject", "ptr", hDC, "ptr", hNullBrush, "ptr")
    DllCall("gdi32\Rectangle", "ptr", hDC, "int", left, "int", top, "int", right, "int", bottom)
    DllCall("gdi32\SelectObject", "ptr", hDC, "ptr", hOldPen)
    DllCall("gdi32\SelectObject", "ptr", hDC, "ptr", hOldBrush)
    DllCall("gdi32\DeleteObject", "ptr", hPen)

    DllCall("gdi32\SetTextColor", "ptr", hDC, "uint", BGR(0xC00000))
    DllCall("gdi32\SetBkMode", "ptr", hDC, "int", 1)   ; TRANSPARENT
    DllCall("user32\DrawText", "ptr", hDC, "str", "Exit Script", "int", -1, "ptr", rect, "uint", 0x25)   ; DT_CENTER|DT_VCENTER|DT_SINGLELINE

    return true
}

; Converts 0xRRGGBB to a Win32 COLORREF (0x00BBGGRR).
BGR(rgb) {
    return ((rgb & 0xFF) << 16) | (rgb & 0xFF00) | ((rgb >> 16) & 0xFF)
}

JoinArr(arr, sep) {
    out := ""
    for i, v in arr
        out .= (i > 1 ? sep : "") v
    return out
}
