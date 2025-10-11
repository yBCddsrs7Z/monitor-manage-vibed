#Requires AutoHotkey v2.0

; ==============================================================================
; monitor-toggle.ahk
; ==============================================================================
; Entry-point script that wires global hotkeys to monitor/audio profile toggles.
; Relies on the bundled PowerShell helpers plus the DisplayConfig and
; AudioDeviceCmdlets PowerShell modules to perform the underlying device
; changes and to export current hardware metadata for configuration.
; ==============================================================================

#Include %A_LineFile%\..\_JXON.ahk

; Establish core paths relative to the script directory so the project remains
; portable regardless of where it is checked out.
global baseDir := A_ScriptDir
global scriptsDir := baseDir "\scripts"
global active_profile := scriptsDir "\active_profile"
global config_file := baseDir "\config.json"
global log_file := baseDir "\monitor-toggle.log"
global devices_file := baseDir "\devices_snapshot.json"
global repoRoot := baseDir  ; Same as baseDir for error file location
global configWasCreated := false  ; Track if this is first run
overlayVisible := false
overlayGui := 0
overlaySettingsCache := ""

EnsureScriptsDirectory()

; Show startup notification
ShowNotification("Starting up...")

; Load the configuration from the JSON file.
config := LoadConfig()
if !IsObject(config) {
    ShowFatalError("Unable to load configuration data.")
}

; Validate configuration
ShowNotification("Verifying config...")
isValid := ValidateConfigAndNotify()

if isValid {
    ShowNotification("Verification complete")
    Sleep(1000)
    
    ; Show appropriate message based on whether this is first run
    if configWasCreated {
        ; First time user
        ShowNotification("Looks like you're using this script for the first time!`n`nPress Left Alt+Left Shift+9 to configure your profiles")
    } else {
        ; Regular user - show ready message then overlay
        ShowNotification("Script ready to be used")
        Sleep(1500)
        ; Show the profile overlay (Alt+Shift+0 equivalent)
        ToggleProfileOverlay()
    }
}

ConvertAhkHotkeyToDescriptor(hotkey) {
    if (hotkey = "") {
        return ""
    }

    modifiers := []
    key := ""
    index := 1
    len := StrLen(hotkey)
    sidePrefix := ""

    while (index <= len) {
        char := SubStr(hotkey, index, 1)
        if (char = "<" || char = ">") {
            sidePrefix := (char = "<") ? "Left " : "Right "
            index++
            continue
        }

        switch char
        {
            case "!":
                modifiers.Push(sidePrefix . "Alt")
            case "+":
                modifiers.Push(sidePrefix . "Shift")
            case "^":
                modifiers.Push(sidePrefix . "Ctrl")
            case "#":
                modifiers.Push(sidePrefix . "Win")
            default:
                key := SubStr(hotkey, index)
                index := len  ; exit loop after capturing key
        }
        sidePrefix := ""
        index++
    }

    descriptor := ""
    if (modifiers.Length) {
        descriptor := StrJoin(modifiers, "+")
    }

    if (key != "") {
        if (descriptor != "") {
            descriptor .= "+"
        }
        descriptor .= key
    }

    return descriptor
}

StrJoin(values, delimiter := "") {
    if !IsObject(values) {
        return values
    }

    result := ""
    for index, value in values {
        if (index > 1) {
            result .= delimiter
        }
        result .= value
    }

    return result
}

hotkeySettings := GetHotkeySettings(config)
overlaySettings := GetOverlaySettings(config)
profiles := GetProfiles(config)

configCount := GetHighestConfigIndex(profiles)
if (configCount < 1) {
    LogMessage("Configuration contains no profiles; overlay hotkeys will be disabled until configured.")
}
RegisterConfiguredHotkeys(hotkeySettings, configCount)

ActivateAllDisplays(descriptor := "") {
    global scriptsDir

    currentHotkey := A_ThisHotkey
    if (!currentHotkey && descriptor != "") {
        currentHotkey := ConvertDescriptorToAhkHotkey(descriptor)
    }

    if (currentHotkey) {
        LogMessage("Hotkey " currentHotkey " requested enable-all sequence")
    } else if (descriptor) {
        LogMessage("Enable-all sequence requested via " descriptor)
    } else {
        LogMessage("Enable-all sequence requested")
    }

    ; Show confirmation notification
    ShowNotification("Activating all displays...")

    psScript := scriptsDir "\switch_profile.ps1"
    if !FileExist(psScript) {
        ShowFatalError("PowerShell script not found at '" psScript "'.")
    }

    command := Format('powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{1}" -ActivateAll', psScript)

    try {
        RunWait(command, , "Hide")
    } catch Error as err {
        LogMessage("Activate-all helper failed: " err.Message)
        ShowFatalError("Failed to execute PowerShell helper.`r`n" err.Message)
    }

    LogMessage("Completed activation of all displays")
}

; ----------------------------------------------------------------------------
; CycleAudioDevice
; Cycles to the next available audio output device
; ----------------------------------------------------------------------------
CycleAudioDevice(descriptor := "") {
    global scriptsDir

    currentHotkey := A_ThisHotkey
    if (!currentHotkey && descriptor != "") {
        currentHotkey := ConvertDescriptorToAhkHotkey(descriptor)
    }

    if (currentHotkey) {
        LogMessage("Hotkey " currentHotkey " requested audio cycle")
    } else if (descriptor) {
        LogMessage("Audio cycle requested via " descriptor)
    } else {
        LogMessage("Audio cycle requested")
    }

    psScript := scriptsDir "\cycle_audio.ps1"
    if !FileExist(psScript) {
        ShowFatalError("PowerShell script not found at '" psScript "'.")
    }

    command := Format('powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{1}"', psScript)

    try {
        output := ""
        RunWait(command, , "Hide", &output)
        
        ; The PowerShell script outputs the selected device name
        if (output != "") {
            ShowNotification("Audio: " Trim(output))
        }
    } catch Error as err {
        LogMessage("Audio cycle helper failed: " err.Message)
        ShowFatalError("Failed to execute PowerShell helper.`r`n" err.Message)
    }

    LogMessage("Completed audio cycle")
}

; ----------------------------------------------------------------------------
; ExportDevices
; Hotkey handler for Alt+Shift+0. Invokes the PowerShell helper to snapshot all
; ----------------------------------------------------------------------------
ExportDevices(hk := "", showNotification := true) {
    global scriptsDir, devices_file
    psScript := scriptsDir "\export_devices.ps1"
    if !FileExist(psScript) {
        ShowFatalError("PowerShell device export script not found at '" psScript "'.")
    }

    LogMessage("Starting device export to " devices_file)
    command := Format('powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{1}" -OutputPath "{2}"', psScript, devices_file)

    try {
        RunWait(command, , "Hide")
    } catch Error as err {
        LogMessage("Device export failed: " err.Message)
        ShowFatalError("Failed to execute PowerShell helper.`r`n" err.Message)
    }

    if !FileExist(devices_file) {
        LogMessage("Device export did not produce an output file at " devices_file)
        ShowFatalError("Device export did not produce an output file. Check logs for details.")
    }

    LogMessage("Completed device export to " devices_file)
    if (showNotification) {
        MsgBox("Device inventory saved to:`r`n" devices_file, "Monitor Toggle", "Iconi")
    }
}

CreateSetConfigHandler(profileKey, descriptor) {
    ; Create a closure that captures profileKey by VALUE not reference
    return (params*) => SetConfig(profileKey, descriptor)
}

RegisterConfiguredHotkeys(hotkeys, maxIndex) {
    if !IsObject(hotkeys) {
        hotkeys := GetDefaultConfig()["hotkeys"]
    }

    Loop maxIndex {
        keyStr := String(A_Index)
        descriptor := GetProfileHotkeyDescriptor(hotkeys, keyStr)
        hotkeyStr := ConvertDescriptorToAhkHotkey(descriptor)
        if (hotkeyStr = "") {
            LogMessage("No valid hotkey configured for profile " keyStr "; skipping hotkey registration.")
            continue
        }
        ; Capture keyStr value immediately to avoid closure bug
        handler := CreateSetConfigHandler(keyStr, descriptor)
        RegisterHotkey("profile " keyStr, hotkeyStr, handler)
    }

    cycleAudioDescriptor := GetMapValue(hotkeys, "cycleAudio", GetDefaultCycleAudioDescriptor())
    RegisterHotkeyWithDescriptor("cycle-audio", cycleAudioDescriptor, CycleAudioDevice)

    enableAllDescriptor := GetMapValue(hotkeys, "enableAll", GetDefaultEnableAllDescriptor())
    RegisterHotkeyWithDescriptor("enable-all", enableAllDescriptor, ActivateAllDisplays)

    configuratorDescriptor := GetMapValue(hotkeys, "openConfigurator", GetDefaultConfiguratorDescriptor())
    RegisterHotkeyWithDescriptor("configurator", configuratorDescriptor, OpenConfigurator)

    overlayDescriptor := GetMapValue(hotkeys, "toggleOverlay", GetDefaultOverlayToggleDescriptor())
    RegisterHotkeyWithDescriptor("overlay", overlayDescriptor, ToggleProfileOverlay)
}

RegisterHotkey(label, hotkeyStr, handler) {
    if (hotkeyStr = "") {
        LogMessage("Skipping registration for " label " hotkey because it is unassigned.")
        return
    }

    try {
        Hotkey(hotkeyStr, handler)
        LogMessage("Registered " label " hotkey: " hotkeyStr)
    } catch Error as err {
        LogMessage("Failed to register " label " hotkey ('" hotkeyStr "'): " err.Message)
    }
}

RegisterHotkeyWithDescriptor(label, descriptor, handlerFunc) {
    hotkeyStr := ConvertDescriptorToAhkHotkey(descriptor)
    if (hotkeyStr = "") {
        LogMessage("Skipping registration for " label " hotkey because descriptor '" descriptor "' is invalid.")
        return
    }

    bound := handlerFunc.Bind(descriptor)
    handler := (params*) => bound()
    RegisterHotkey(label, hotkeyStr, handler)
}

ConvertDescriptorToAhkHotkey(descriptor) {
    if (descriptor = "") {
        return ""
    }

    tokens := StrSplit(descriptor, "+")
    if (tokens.Length = 0) {
        return ""
    }

    modMap := Map(
        "alt", "!",
        "shift", "+",
        "ctrl", "^",
        "control", "^",
        "win", "#",
        "lalt", "<!",
        "leftalt", "<!",
        "ralt", ">!",
        "rightalt", ">!",
        "lshift", "<+",
        "leftshift", "<+",
        "rshift", ">+",
        "rightshift", ">+",
        "lctrl", "<^",
        "leftctrl", "<^",
        "rctrl", ">^",
        "rightctrl", ">^",
        "lwin", "<#",
        "leftwin", "<#",
        "rwin", ">#",
        "rightwin", ">#"
    )

    hotkey := ""
    keyToken := ""

    Loop tokens.Length {
        token := Trim(tokens[A_Index])
        if (token = "") {
            continue
        }

        lower := StrLower(token)
        normalized := RegExReplace(lower, "\s+")
        if modMap.Has(normalized) {
            hotkey .= modMap[normalized]
        } else if modMap.Has(lower) {
            hotkey .= modMap[lower]
        } else {
            keyToken := token
        }
    }

    if (keyToken = "") {
        return ""
    }

    key := ConvertDescriptorKeyName(keyToken)
    if (key = "") {
        return ""
    }

    return hotkey . key
}

ConvertDescriptorKeyName(token) {
    if (StrLen(token) = 1) {
        return token
    }

    lower := StrLower(token)
    specialMap := Map(
        "enter", "Enter",
        "return", "Enter",
        "escape", "Esc",
        "esc", "Esc",
        "space", "Space",
        "tab", "Tab",
        "backspace", "Backspace",
        "delete", "Delete",
        "del", "Delete",
        "insert", "Insert",
        "home", "Home",
        "end", "End",
        "pgup", "PgUp",
        "pageup", "PgUp",
        "pgdn", "PgDn",
        "pagedown", "PgDn",
        "left", "Left",
        "right", "Right",
        "up", "Up",
        "down", "Down"
    )

    if specialMap.Has(lower) {
        return specialMap[lower]
    }

    if RegExMatch(lower, "^f[0-9]{1,2}$") {
        return StrUpper(token)
    }

    return token
}

NormalizeHotkeyDescriptor(descriptor) {
    if (descriptor = "") {
        return ""
    }

    ahk := ConvertDescriptorToAhkHotkey(descriptor)
    if (ahk = "") {
        return ""
    }

    return ConvertAhkHotkeyToDescriptor(ahk)
}

OpenConfigurator(hk) {
    global scriptsDir

    configScript := scriptsDir "\configure_profiles.ps1"
    if !FileExist(configScript) {
        ShowFatalError(Format('Interactive configuration script not found at "{}".', configScript))
    }

    LogMessage(Format('Launching configuration helper via {}', hk ? hk : "manual invocation"))

    ; Show confirmation notification
    ShowNotification("Opening configurator...")

    ExportDevices("", false)

    command := Format('powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -NoExit -File "{1}"', configScript)
    try {
        Run(command, , "")
        LogMessage(Format('Started configuration helper process: {}', command))
    } catch Error as err {
        LogMessage(Format('Failed to launch configuration helper: {}', err.Message))
        ShowFatalError("Unable to launch configuration helper.`r`n" err.Message)
    }
}

SetConfig(profileKey, descriptor := "") {
    currentHotkey := A_ThisHotkey
    if (!currentHotkey && descriptor != "") {
        currentHotkey := ConvertDescriptorToAhkHotkey(descriptor)
    }

    if (currentHotkey) {
        LogMessage("Hotkey " currentHotkey " requested profile " profileKey)
    } else if (descriptor) {
        LogMessage("Requested profile " profileKey " via " descriptor)
    } else {
        LogMessage("Requested profile " profileKey)
    }

    ; Show "Activating" notification
    ShowNotification("Activating profile " profileKey "...")

    ; Resolve and validate the PowerShell helper responsible for applying
    ; monitor/audio configuration changes.
    psScript := scriptsDir "\switch_profile.ps1"
    if !FileExist(psScript) {
        ShowFatalError("PowerShell script not found at `"" psScript "`"`.")
    }

    command := Format('powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{1}" -profileKey "{2}"', psScript, profileKey)

    try {
        exitCode := RunWait(command, , "Hide")    ; Wait for the helper to finish for error propagation.
        
        ; Check if PowerShell script failed
        if (exitCode != 0) {
            LogMessage("Switch helper exited with code " exitCode " - error saved for overlay display")
            
            ; Close any notification overlay
            global overlayVisible, overlayGui
            if (overlayVisible && IsObject(overlayGui)) {
                try {
                    overlayGui.Hide()
                    overlayVisible := false
                } catch {
                    ; Overlay already closed, ignore
                }
            }
            
            return
        }
    } catch Error as err {
        LogMessage("Switch helper failed: " err.Message)
        ShowFatalError("Failed to execute PowerShell helper.`r`n" err.Message)
    }
    
    ; Show success notification
    ShowNotification("Successfully activated profile " profileKey)

    LogMessage("Completed switch helper for profile " profileKey)

    try {
        if FileExist(active_profile) {
            FileDelete(active_profile)
        }
        FileAppend(profileKey, active_profile, "UTF-8")
        LogMessage("Updated active profile marker to profile " profileKey)
    } catch Error as err {
        ShowFatalError("Failed to update active profile marker.`r`n" err.Message)
    }
}

ToggleProfileOverlay(descriptor := "") {
    hk := descriptor ? ConvertDescriptorToAhkHotkey(descriptor) : A_ThisHotkey
    if (hk) {
        LogMessage("Hotkey " hk " requested profile overlay")
    } else {
        LogMessage("Requested profile overlay")
    }

    config := LoadConfig()
    profiles := GetProfiles(config)
    maxIndex := GetHighestConfigIndex(profiles)
    overlaySettings := GetOverlaySettings(config)
    overlaySettingsCache := overlaySettings
    hotkeySettings := GetHotkeySettings(config)

    ; Check for error from last switch attempt
    errorFile := repoRoot "\last_error.txt"
    errorText := ""
    if FileExist(errorFile) {
        try {
            errorText := FileRead(errorFile, "UTF-8")
        } catch {
            errorText := ""
        }
    }

    if (maxIndex <= 0) {
        summary := BuildEmptySummary(hotkeySettings)
        if (errorText != "") {
            summary := errorText "`n`n" summary
        }
        ShowProfileOverlay(summary)
        return
    }

    summaryText := BuildProfileSummary(profiles, maxIndex, hotkeySettings)
    
    ; Prepend error if present
    if (errorText != "") {
        summaryText := errorText "`n`n" summaryText
    }
    
    ShowProfileOverlay(summaryText)
}

GetHighestConfigIndex(configMap := "") {
    if !IsObject(configMap) {
        configMap := LoadConfig()
    }

    maxKey := 0
    for key, value in configMap {
        try num := Integer(key)
        catch {
            continue
        }
        if (num > maxKey)
            maxKey := num
    }
    return maxKey
}

EnsureScriptsDirectory() {
    global scriptsDir
    try {
        DirCreate(scriptsDir)  ; AutoHotkey v2 DirCreate accepts a single path argument.
    } catch Error {
        ; Directory may already exist or be read-only; ignore errors here.
    }
}

GetDefaultConfig() {
    profileHotkeys := Map()
    Loop 6 {
        profileKey := String(A_Index)
        profileHotkeys[profileKey] := NormalizeHotkeyDescriptor(GetDefaultProfileHotkeyDescriptor(profileKey))
    }

    hotkeys := Map(
        "profiles", profileHotkeys,
        "cycleAudio", NormalizeHotkeyDescriptor(GetDefaultCycleAudioDescriptor()),
        "enableAll", NormalizeHotkeyDescriptor(GetDefaultEnableAllDescriptor()),
        "openConfigurator", NormalizeHotkeyDescriptor(GetDefaultConfiguratorDescriptor()),
        "toggleOverlay", NormalizeHotkeyDescriptor(GetDefaultOverlayToggleDescriptor())
    )

    overlay := Map(
        "fontName", "Segoe UI",
        "fontSize", 16,
        "fontBold", true,
        "textColor", "Blue",
        "backgroundColor", "Black",
        "opacity", 220,
        "position", "top-left",
        "marginX", 10,
        "marginY", 10,
        "durationMs", 10000,
        "notificationPosition", "top-center",
        "notificationDuration", 5000
    )

    settings := Map(
        "enableMicrophoneManagement", false
    )

    profiles := Map()
    Loop 6 {
        profileKey := String(A_Index)
        profiles[profileKey] := Map(
            "activeDisplays", Array(),
            "disableDisplays", Array(),
            "audio", "",
            "microphone", ""
        )
    }

    documentation := Map(
        "profiles", Map(
            "_overview", "Six empty profiles (keys '1'-'6') are provided by default. Add additional numeric keys if you need more saved layouts. Alt+Shift+7 is reserved for audio cycling.",
            "fields", Map(
                "activeDisplays", Array(
                    "List the display names that should remain enabled when this profile is activated.",
                    "Accepts a single string (for one display) or an array of strings.",
                    "Names should match the friendly names captured in devices_snapshot.json (e.g., 'Generic Display')."
                ),
                "disableDisplays", Array(
                    "Displays to explicitly turn off while this profile is active.",
                    "Accepts a string or array, just like activeDisplays.",
                    "Leave empty ({} or []) to disable none explicitly."
                ),
                "audio", "Optional friendly audio device name to set as the default output (e.g., 'Speakers (USB Audio)')."
            ),
            "editing", Array(
                "Use scripts/configure_profiles.ps1 to manage profiles interactively without hand-editing JSON.",
                "Press Alt+Shift+0 (toggle overlay) followed by Alt+Shift+9 (open configurator) for the guided workflow.",
                "The configurator populates activeDisplays/disableDisplays/audio fields based on the selections you make from the detected devices."
            )
        ),
        "hotkeys", Map(
            "_overview", "Hotkey descriptors use human-readable syntax like 'Alt+Shift+1' or 'Left Ctrl+Alt+F3'.",
            "profiles", Array(
                "Each entry maps a profile key to a descriptor (e.g., 'Alt+Shift+1').",
                "Supported modifiers: Alt, Shift, Ctrl, Win (optionally prefixed with Left/Right).",
                "Keys may be single characters, numbers, function keys (F1-F24), or named keys (Enter, Esc, Tab, etc.)."
            ),
            "enableAll", "Defaults to 'Alt+Shift+8'. Update to any descriptor to change the binding.",
            "openConfigurator", "Defaults to 'Alt+Shift+9'. Invokes the PowerShell configurator.",
            "toggleOverlay", "Defaults to 'Alt+Shift+0'. Shows or hides the profile summary overlay."
        ),
        "overlay", Map(
            "position", "Accepts 'top-left', 'top-right', 'bottom-left', or 'bottom-right'.",
            "colors", "Use AutoHotkey color names (e.g., Black, White, Silver) or hex strings like '#202020'.",
            "font", Array(
                "'fontName' selects the typeface (e.g., 'Segoe UI', 'Consolas').",
                "'fontSize' is an integer point size.",
                "'fontBold' toggles bold text (true/false or 1/0)."
            ),
            "layout", Array(
                "'marginX' and 'marginY' control pixel offsets from the chosen screen edge.",
                "'opacity' ranges 0-255 (lower is more transparent).",
                "'durationMs' determines how long the overlay remains visible before auto-hide (default 10000 ms = 10 seconds)."
            )
        )
    )

    return Map(
        "_documentation", documentation,
        "hotkeys", hotkeys,
        "overlay", overlay,
        "settings", settings,
        "profiles", profiles
    )
}

MergeMissingDefaults(target, defaults) {
    changed := false

    for key, defVal in defaults {
        if !IsObject(target) {
            continue
        }

        if !target.Has(key) {
            target[key] := defVal
            changed := true
        } else if IsObject(defVal) && IsObject(target[key]) {
            if MergeMissingDefaults(target[key], defVal) {
                changed := true
            }
        }
    }

    return changed
}

NormalizeConfigStructure(config) {
    changed := false

    if !IsObject(config) {
        config := Map()
        changed := true
    }

    defaults := GetDefaultConfig()

    if !config.Has("profiles") {
        config["profiles"] := Map()
        changed := true
    }

    profiles := config["profiles"]
    if !IsObject(profiles) {
        profiles := Map()
        config["profiles"] := profiles
        changed := true
    }

    ; Remove non-numeric profile keys (profiles must be numbered)
    invalidKeys := []
    for key, value in profiles {
        ; Skip metadata keys (allowed non-numeric)
        if (SubStr(key, 1, 1) = "_") {
            continue
        }
        ; Check if key is numeric
        if !(key is Integer || RegExMatch(key, "^\d+$")) {
            invalidKeys.Push(key)
            LogMessage("Warning: Removing non-numeric profile key '" key "'. Profile keys must be numbers.")
        }
    }
    
    ; Remove invalid keys
    for _, key in invalidKeys {
        profiles.Delete(key)
        changed := true
    }

    ; Move legacy top-level profile keys into the profiles section
    ; (but exclude metadata keys like _documentation and settings)
    legacyKeys := []
    for key, value in config {
        if (key != "hotkeys" && key != "overlay" && key != "profiles" && key != "_documentation" && key != "settings") {
            legacyKeys.Push(key)
        }
    }

    for _, key in legacyKeys {
        profiles[key] := config[key]
        config.Delete(key)
        changed := true
    }

    if !config.Has("hotkeys") {
        config["hotkeys"] := defaults["hotkeys"]
        changed := true
    }
    if !config.Has("overlay") {
        config["overlay"] := defaults["overlay"]
        changed := true
    }

    hotkeys := config["hotkeys"]
    if !IsObject(hotkeys) {
        hotkeys := defaults["hotkeys"]
        config["hotkeys"] := hotkeys
        changed := true
    }

    if !hotkeys.Has("profiles") || !IsObject(hotkeys["profiles"]) {
        hotkeys["profiles"] := Map()
        changed := true
    }

    profileHotkeys := hotkeys["profiles"]

    ; Normalize existing profile hotkeys
    for profileKey, existing in profileHotkeys {
        normalized := NormalizeHotkeyDescriptor(existing)
        if (normalized != existing) {
            profileHotkeys[profileKey] := normalized
            changed := true
        }
    }

    ; Ensure default profile hotkeys 1-6 exist
    ; (Users can add profiles 7, 8, etc. but must configure hotkeys manually)
    Loop 6 {
        key := String(A_Index)
        if !profileHotkeys.Has(key) {
            profileHotkeys[key] := NormalizeHotkeyDescriptor(GetDefaultProfileHotkeyDescriptor(key))
            changed := true
        }
    }

    descriptors := ["enableAll", "openConfigurator", "toggleOverlay"]
    for _, option in descriptors {
        existing := GetMapValue(hotkeys, option, "")
        normalized := NormalizeHotkeyDescriptor(existing)
        if (normalized != existing) {
            hotkeys[option] := normalized
            changed := true
        }
        if (normalized = "") {
            defaultValue := GetMapValue(defaults["hotkeys"], option, "")
            if (defaultValue != "") {
                hotkeys[option] := NormalizeHotkeyDescriptor(defaultValue)
                changed := true
            }
        }
    }

    if hotkeys.Has("profilePrefix") {
        hotkeys.Delete("profilePrefix")
        changed := true
    }

    if MergeMissingDefaults(hotkeys, defaults["hotkeys"]) {
        changed := true
    }
    if MergeMissingDefaults(config["overlay"], defaults["overlay"]) {
        changed := true
    }

    result := Map()
    result["config"] := config
    result["changed"] := changed
    return result
}

WriteConfigToFile(config) {
    global config_file

    json := Jxon_Dump(config, 4)
    try {
        FileDelete(config_file)
    } catch {
        ; ignore deletion failures; will overwrite
    }
    FileAppend(json, config_file, "UTF-8")
}

GetProfiles(config) {
    return GetMapValue(config, "profiles", Map())
}

GetHotkeySettings(config) {
    return GetMapValue(config, "hotkeys", Map())
}

GetOverlaySettings(config) {
    return GetMapValue(config, "overlay", Map())
}

GetDefaultProfileHotkeyDescriptor(profileKey) {
    return "Left Alt+Left Shift+" . profileKey
}

GetDefaultCycleAudioDescriptor() {
    return "Left Alt+Left Shift+7"
}

GetDefaultEnableAllDescriptor() {
    return "Left Alt+Left Shift+8"
}

GetDefaultConfiguratorDescriptor() {
    return "Left Alt+Left Shift+9"
}

GetDefaultOverlayToggleDescriptor() {
    return "Left Alt+Left Shift+0"
}

DescribeHotkey(hotkey) {
    if (hotkey = "") {
        return "(unassigned)"
    }

    modifiers := Map("!", "Alt", "+", "Shift", "^", "Ctrl", "#", "Win")
    parts := []
    index := 1
    len := StrLen(hotkey)

    while (index <= len) {
        char := SubStr(hotkey, index, 1)
        prefix := ""
        if (char = "<" || char = ">") {
            prefix := (char = "<") ? "Left " : "Right "
            index++
            if (index > len) {
                break
            }
            char := SubStr(hotkey, index, 1)
        }

        if modifiers.Has(char) {
            parts.Push(prefix . modifiers[char])
            index++
            continue
        }
        break
    }

    key := SubStr(hotkey, index)
    if (key = "") {
        key := "(key)"
    }

    result := ""
    for idx, part in parts {
        result .= (idx = 1 ? "" : "+") . part
    }

    return result
}

CalculateOverlayPosition(settings, width, height) {
    marginX := Integer(GetMapValue(settings, "marginX", 10))
    marginY := Integer(GetMapValue(settings, "marginY", 10))
    position := StrLower(GetMapValue(settings, "position", "top-left"))

    screenW := A_ScreenWidth
    screenH := A_ScreenHeight

    x := marginX
    y := marginY

    switch position {
        case "top-right":
            x := screenW - width - marginX
            y := marginY
        case "top-center":
            x := (screenW - width) // 2
            y := marginY
        case "bottom-left":
            x := marginX
            y := screenH - height - marginY
        case "bottom-center":
            x := (screenW - width) // 2
            y := screenH - height - marginY
        case "bottom-right":
            x := screenW - width - marginX
            y := screenH - height - marginY
        case "center":
            x := (screenW - width) // 2
            y := (screenH - height) // 2
        default:
            ; top-left
            x := marginX
            y := marginY
    }

    if (x < 0) {
        x := 0
    }
    if (y < 0) {
        y := 0
    }

    return Map("x", x, "y", y)
}

LogMessage(message) {
    global log_file
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    ; Logging failures are intentionally swallowed to avoid interrupting hotkey flow.
    try FileAppend(timestamp " - " message "`n", log_file, "UTF-8")
}

ShowFatalError(message) {
    LogMessage("ERROR: " message)
    MsgBox("Monitor toggle error:`r`n`r`n" message, "Monitor Toggle", "IconX")
    ExitApp()
}
LoadConfig() {
    global config_file, configWasCreated

    created := false

    if !FileExist(config_file) {
        defaultConfig := GetDefaultConfig()
        LogMessage("Configuration file missing; creating default config at '" config_file "'.")
        try {
            WriteConfigToFile(defaultConfig)
            created := true
            configWasCreated := true  ; Set global flag for first-time use detection
        } catch Error as err {
            ShowFatalError("Unable to create configuration file.`r`n" err.Message)
        }
    }

    try config_data := FileRead(config_file, "UTF-8")
    catch Error as err {
        ShowFatalError("Failed to read configuration file.`r`n" err.Message)
    }

    try config := jxon_load(&config_data)
    catch Error as err {
        ShowFatalError("Failed to parse config.json.`r`n" err.Message)
    }

    if !IsObject(config) {
        config := Map()
    }

    normalizeResult := NormalizeConfigStructure(config)
    config := normalizeResult["config"]
    changed := normalizeResult["changed"]

    if (created || changed) {
        try {
            WriteConfigToFile(config)
        } catch Error as err {
            LogMessage("Failed to persist normalized configuration: " err.Message)
        }
    }

    return config
}

GetDisplayNames(spec) {
    names := []

    if !IsObject(spec) {
        name := GetDisplayNameFromValue(spec)
        if (name != "")
            names.Push(name)
        return names
    }

    if (Type(spec) = "Array") {
        for item in spec {
            name := GetDisplayNameFromValue(item)
            if (name != "")
                names.Push(name)
        }
    } else {
        name := GetDisplayNameFromValue(spec)
        if (name != "")
            names.Push(name)
    }

    return names
}

GetDisplayNameFromValue(value) {
    if value = "" {
        return ""
    }

    if !IsObject(value) {
        return String(value)
    }

    if (Type(value) = "Array") {
        for item in value {
            name := GetDisplayNameFromValue(item)
            if (name != "") {
                return name
            }
        }
        return ""
    }

    for key in ["name", "Name", "displayName", "DisplayName"] {
        candidate := GetMapValue(value, key)
        if (candidate != "") {
            return String(candidate)
        }
    }

    if value.HasOwnProp("Value") {
        candidate := value.Value
        if (candidate != "") {
            return GetDisplayNameFromValue(candidate)
        }
    }

    return ""
}

JoinNameList(list) {
    if !(IsObject(list) && Type(list) = "Array" && list.Length > 0) {
        return "(none)"
    }

    result := ""
    for index, item in list {
        result .= (index = 1 ? "" : ", ") item
    }
    return result
}

GetMapValue(map, key, defaultValue := "") {
    if IsObject(map) {
        try {
            if (map.Has(key)) {
                return map[key]
            }
        } catch {
            ; map may not expose Has(); ignore
        }

        try {
            if map.HasOwnProp(key) {
                return map.%key%
            }
        } catch {
            ; property access failed; ignore
        }

        try {
            return map[key]
        } catch {
            ; final attempt failed; fall through
        }
    }
    return defaultValue
}

GetProfileHotkeyDescriptor(hotkeySettings, profileKey) {
    if !IsObject(hotkeySettings) {
        return GetDefaultProfileHotkeyDescriptor(profileKey)
    }

    profileMap := GetMapValue(hotkeySettings, "profiles", Map())
    if IsObject(profileMap) {
        descriptor := GetMapValue(profileMap, profileKey, "")
        if (descriptor != "") {
            return descriptor
        }
    }

    return GetDefaultProfileHotkeyDescriptor(profileKey)
}

BuildProfileSummary(config, maxIndex, hotkeySettings := "") {
    lines := []
    
    ; Check if microphone management is enabled
    fullConfig := LoadConfig()
    settings := GetMapValue(fullConfig, "settings", Map())
    micEnabled := GetMapValue(settings, "enableMicrophoneManagement", false)

    Loop maxIndex {
        keyStr := String(A_Index)
        profile := GetMapValue(config, keyStr, Map())

        if !IsObject(profile) {
            continue
        }

        activeSpec := GetMapValue(profile, "activeDisplays")
        disableSpec := GetMapValue(profile, "disableDisplays")

        activeNames := JoinNameList(GetDisplayNames(activeSpec))
        disableNames := JoinNameList(GetDisplayNames(disableSpec))

        audioName := GetMapValue(profile, "audio", "(none)")
        if (audioName = "") {
            audioName := "(none)"
        }

        hotkeyLabel := GetProfileHotkeyDescriptor(hotkeySettings, keyStr)
        
        ; Build profile summary with optional microphone info
        if (micEnabled) {
            micName := GetMapValue(profile, "microphone", "(none)")
            if (micName = "") {
                micName := "(none)"
            }
            lines.Push(Format("{1}  →  profile {2}`n    Enable:  {3}`n    Disable: {4}`n    Audio:   {5}`n    Mic:     {6}", hotkeyLabel, keyStr, activeNames, disableNames, audioName, micName))
        } else {
            lines.Push(Format("{1}  →  profile {2}`n    Enable:  {3}`n    Disable: {4}`n    Audio:   {5}", hotkeyLabel, keyStr, activeNames, disableNames, audioName))
        }
    }

    enableHotkey := GetMapValue(hotkeySettings, "enableAll", GetDefaultEnableAllDescriptor())
    configHotkey := GetMapValue(hotkeySettings, "openConfigurator", GetDefaultConfiguratorDescriptor())
    overlayHotkey := GetMapValue(hotkeySettings, "toggleOverlay", GetDefaultOverlayToggleDescriptor())

    lines.Push(enableHotkey "  →  Enable all displays")
    lines.Push(configHotkey "  →  Open configuration helper")
    lines.Push(overlayHotkey "  →  Toggle this overlay")

    summary := ""
    for index, line in lines {
        summary .= (index = 1 ? "" : "`n`n") line
    }

    return summary
}

BuildEmptySummary(hotkeySettings := "") {
    enableHotkey := GetMapValue(hotkeySettings, "enableAll", GetDefaultEnableAllDescriptor())
    configHotkey := GetMapValue(hotkeySettings, "openConfigurator", GetDefaultConfiguratorDescriptor())
    overlayHotkey := GetMapValue(hotkeySettings, "toggleOverlay", GetDefaultOverlayToggleDescriptor())

    lines := []
    lines.Push("No profiles are configured.")
    lines.Push("")
    lines.Push(GetProfileHotkeyDescriptor(hotkeySettings, "1") "  →  Profile 1")
    lines.Push(enableHotkey "  →  Enable all displays")
    lines.Push(configHotkey "  →  Open configuration helper")
    lines.Push(overlayHotkey "  →  Toggle this overlay")

    summary := ""
    for index, line in lines {
        summary .= (index = 1 ? "" : "`n") line
    }

    return summary
}

ShowProfileOverlay(summaryText, durationMs := "") {
    global overlayVisible, overlayGui, overlaySettingsCache

    HideProfileOverlay()

    overlaySettings := overlaySettingsCache
    if !IsObject(overlaySettings) {
        overlaySettings := GetDefaultConfig()["overlay"]
    }

    if (durationMs = "") {
        durationMs := Integer(GetMapValue(overlaySettings, "durationMs", 10000))
    }

    fontName := GetMapValue(overlaySettings, "fontName", "Segoe UI")
    fontSize := Integer(GetMapValue(overlaySettings, "fontSize", 20))
    fontBold := GetMapValue(overlaySettings, "fontBold", true)
    textColor := GetMapValue(overlaySettings, "textColor", "Blue")
    backgroundColor := GetMapValue(overlaySettings, "backgroundColor", "Black")
    opacity := Integer(GetMapValue(overlaySettings, "opacity", 220))

    fontOptions := "s" fontSize
    if fontBold {
        fontOptions .= " bold"
    }

    overlayGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "Monitor Toggle Summary")
    overlayGui.BackColor := backgroundColor

    overlayGui.SetFont(fontOptions, fontName)
    overlayGui.AddText("c" textColor " BackgroundTrans", summaryText)

    overlayGui.Opt("+LastFound")
    WinSetTransparent(opacity)

    guiWidth := overlayGui.MarginX * 2
    guiHeight := overlayGui.MarginY * 2

    overlayGui.Show("Hide")
    overlayGui.GetPos(&x, &y, &w, &h)

    position := CalculateOverlayPosition(overlaySettings, w, h)
    overlayGui.Show(Format("x{1} y{2}", position["x"], position["y"]))
    overlayVisible := true

    if (durationMs > 0) {
        SetTimer(HideProfileOverlay, -durationMs)
    }
}

HideProfileOverlay() {
    global overlayVisible, overlayGui

    if IsObject(overlayGui) {
        overlayGui.Destroy()
        overlayGui := 0
    }
    overlayVisible := false
}

ShowTransientOverlay(message, overlaySettings := "") {
    global overlaySettingsCache
    duration := ""
    if IsObject(overlaySettings) {
        duration := Integer(GetMapValue(overlaySettings, "durationMs", 10000))
        overlaySettingsCache := overlaySettings
        overlaySettingsCache["durationMs"] := duration
    } else {
        overlaySettingsCache := ""
    }
    ShowProfileOverlay(message)
}

ShowNotification(message) {
    ; Show a temporary notification overlay using notification settings
    global overlaySettingsCache
    
    ; Load overlay settings from config
    config := LoadConfig()
    overlaySettings := GetMapValue(config, "overlay", Map())
    
    ; Get notification-specific settings
    notificationPos := GetMapValue(overlaySettings, "notificationPosition", "top-center")
    notificationDuration := Integer(GetMapValue(overlaySettings, "notificationDuration", 5000))
    
    ; Create temporary settings for notification
    tempSettings := Map()
    tempSettings["fontName"] := GetMapValue(overlaySettings, "fontName", "Segoe UI")
    tempSettings["fontSize"] := Integer(GetMapValue(overlaySettings, "fontSize", 16))
    tempSettings["fontBold"] := GetMapValue(overlaySettings, "fontBold", true)
    tempSettings["textColor"] := GetMapValue(overlaySettings, "textColor", "Blue")
    tempSettings["backgroundColor"] := GetMapValue(overlaySettings, "backgroundColor", "Black")
    tempSettings["opacity"] := Integer(GetMapValue(overlaySettings, "opacity", 220))
    tempSettings["position"] := notificationPos
    tempSettings["marginX"] := Integer(GetMapValue(overlaySettings, "marginX", 10))
    tempSettings["marginY"] := Integer(GetMapValue(overlaySettings, "marginY", 10))
    tempSettings["durationMs"] := notificationDuration
    
    ; Save original cache and apply temp settings
    originalCache := overlaySettingsCache
    overlaySettingsCache := tempSettings
    
    ; Show the notification
    ShowProfileOverlay(message, notificationDuration)
    
    ; Restore original cache
    overlaySettingsCache := originalCache
}

ValidateConfigAndNotify() {
    global config_file, scriptsDir
    
    ; Run validation script
    validateScript := scriptsDir . "\Validate-Config.ps1"
    if !FileExist(validateScript) {
        LogMessage("Warning: Validate-Config.ps1 not found, skipping validation")
        return true  ; Assume valid if validator not found
    }
    
    ; Execute validation and capture output
    command := 'pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "' validateScript '" -ConfigPath "' config_file '" 2>&1'
    try {
        output := ComObject("WScript.Shell").Exec(command).StdOut.ReadAll()
    } catch Error as err {
        LogMessage("Failed to run validation: " err.Message)
        return true  ; Assume valid if validation failed to run
    }
    
    ; Check if validation failed (contains "✗" or "Configuration is invalid")
    if (InStr(output, "✗") || InStr(output, "invalid")) {
        LogMessage("Config validation failed:`n" output)
        
        errorMsg := "⚠️ Configuration Errors Detected`n`n"
        errorMsg .= "Your config.json has validation issues.`n`n"
        errorMsg .= "Issues found:`n" SubStr(output, 1, 500)
        
        if (StrLen(output) > 500) {
            errorMsg .= "`n... (see monitor-toggle.log for full details)"
        }
        
        errorMsg .= "`n`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n"
        errorMsg .= "🔧 To fix:`n"
        errorMsg .= "1. Delete config.json and restart (will create fresh config)`n"
        errorMsg .= "2. Or manually fix the issues in config.json`n"
        errorMsg .= "3. Or press Alt+Shift+9 to open configurator`n`n"
        errorMsg .= "Check monitor-toggle.log for full validation details."
        
        result := MsgBox(errorMsg, "Configuration Validation Failed", "Icon! OKCancel")
        
        if (result = "OK") {
            ; User acknowledged, log it
            LogMessage("User acknowledged validation errors - continuing with caution")
            return false  ; Validation failed but user acknowledged
        } else {
            ; User cancelled - exit
            LogMessage("User cancelled after validation errors - exiting")
            ExitApp()
        }
    } else if (InStr(output, "✓") || InStr(output, "valid")) {
        LogMessage("Config validation passed")
        return true
    }
    
    ; Default to valid if output unclear
    return true
}



