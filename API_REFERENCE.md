# API Reference

Complete function reference for all AutoHotkey and PowerShell components.

## AutoHotkey Functions (`monitor-toggle.ahk`)

### Core Profile Management

#### `SetConfig(profileKey, descriptor := "")`
Activates a monitor/audio profile.
- **profileKey**: Profile identifier ("1", "2", etc.)
- **descriptor**: Optional hotkey descriptor for logging
- **Behavior**: Invokes `switch_profile.ps1`, updates active profile marker
- **Example**: `SetConfig("1", "Left Alt+Left Shift+1")`

#### `ActivateAllDisplays(descriptor := "")`
Enables all connected displays (panic button).
- **descriptor**: Optional hotkey descriptor
- **Behavior**: Calls `switch_profile.ps1 -ActivateAll`

#### `CycleAudioDevice(descriptor := "")`
Cycles to next audio output device.
- **Behavior**: Invokes `cycle_audio.ps1`, shows device name notification

#### `OpenConfigurator(hk)`
Launches interactive profile configurator.
- **hk**: Hotkey that triggered action
- **Behavior**: Exports devices, launches `configure_profiles.ps1` in new window

### Configuration Loading

#### `LoadConfig()`
Loads and normalizes `config.json`.
- **Returns**: Map object with configuration
- **Side effects**: Creates default config if missing, sets `configWasCreated` flag

#### `GetDefaultConfig()`
Generates default configuration structure.
- **Returns**: Map with profiles, hotkeys, overlay, settings sections

#### `NormalizeConfigStructure(config)`
Normalizes and validates configuration.
- **config**: Configuration Map to normalize
- **Returns**: Map with keys `config` (normalized) and `changed` (boolean)
- **Operations**: Migrates legacy keys, adds defaults, removes invalid profiles

#### `WriteConfigToFile(config)`
Serializes configuration to JSON file.
- **config**: Configuration Map to save

#### `ValidateConfigAndNotify()`
Validates config and shows user-friendly errors.
- **Returns**: Boolean (true if valid)
- **Behavior**: Runs `Validate-Config.ps1`, shows MsgBox on errors

### Hotkey Management

#### `RegisterConfiguredHotkeys(hotkeys, maxIndex)`
Registers all configured hotkeys.
- **hotkeys**: Hotkeys Map from config
- **maxIndex**: Highest profile number to register

#### `CreateSetConfigHandler(profileKey, descriptor)`
Creates closure capturing profile key by value.
- **Returns**: Function handler for hotkey
- **Purpose**: Prevents closure bug

#### `ConvertDescriptorToAhkHotkey(descriptor)`
Converts "Left Alt+Left Shift+1" → "<!<+1".
- **descriptor**: Human-readable hotkey
- **Returns**: AHK syntax string

#### `ConvertAhkHotkeyToDescriptor(hotkey)`
Converts "<!<+1" → "Left Alt+Left Shift+1".
- **hotkey**: AHK syntax
- **Returns**: Human-readable descriptor

### UI Functions

#### `ToggleProfileOverlay(descriptor := "")`
Shows/hides profile summary overlay.
- **Behavior**: Builds summary, shows GUI with auto-hide timer

#### `ShowProfileOverlay(summaryText, durationMs := "")`
Displays overlay GUI.
- **summaryText**: Text to display
- **durationMs**: Optional duration override
- **Behavior**: Creates AlwaysOnTop GUI with configured styling

#### `ShowNotification(message)`
Shows temporary notification.
- **message**: Notification text
- **Behavior**: Uses overlay system with notification settings

#### `ShowFatalError(message)`
Displays error and terminates script.
- **message**: Error message
- **Behavior**: Shows MsgBox, logs error, calls ExitApp()

#### `BuildProfileSummary(config, maxIndex, hotkeySettings := "")`
Builds formatted profile summary text.
- **Returns**: String with formatted profile list

### Utility Functions

#### `GetMapValue(map, key, defaultValue := "")`
Safely retrieves value from Map/Object.
- **Returns**: Value at key or defaultValue

#### `GetProfiles(config)`, `GetHotkeySettings(config)`, `GetOverlaySettings(config)`
Extracts sections from config Map.

#### `GetHighestConfigIndex(configMap)`
Finds highest numeric profile key.
- **Returns**: Integer (0 if none)

#### `LogMessage(message)`
Appends timestamped message to log file.
- **Format**: `yyyy-MM-dd HH:mm:ss - message`

## PowerShell Functions

### switch_profile.ps1

#### Parameters
```powershell
-profileKey <String>  # Profile to activate
-ActivateAll          # Enable all displays
```

#### Key Functions

**`Write-Log -Message <String> [-Level <INFO|WARN|ERROR>]`**
Writes timestamped log entry.

**`Resolve-DisplayIdentifiers -DesiredDisplayNames <Array> -AvailableDisplays <Array>`**
Maps display names to hardware IDs. Returns array of IDs.

**`Set-DisplayState -Display <Object> -Enable <Boolean>`**
Enables or disables a display using DisplayConfig module.

**`Set-AudioDevice -DeviceName <String> -AvailableDevices <Array>`**
Switches default audio output.

**`Get-NormalizedDisplayName -Name <String>`**
Normalizes display name: lowercase, trim, remove special chars.

### configure_profiles.ps1

#### Main Menu Functions

**`Add-Profile`**
Interactive wizard to create new profile. Prompts for displays, audio, microphone.

**`Edit-Profile`**
Edit existing profile. Menu-driven interface.

**`Remove-Profile`**
Delete profile with confirmation. Option to renumber.

**`Show-Profiles`**
Display all configured profiles in formatted table.

#### Utility Functions

**`Get-DeviceInventory`**
Returns hashtable with displays, audioOutputs, audioInputs arrays.

**`Select-DisplayReferencesMultiple -Displays <Array> -Prompt <String>`**
Multi-select UI for choosing displays. Returns selected display objects.

**`Optimize-ProfileKeys -Profiles <Hashtable>`**
Renumbers profiles to remove gaps (1,3,7 → 1,2,3).

### export_devices.ps1

#### Parameters
```powershell
-OutputPath <String>  # Path for devices_snapshot.json
```

#### Functions

**`Get-DisplaySnapshot`**
Returns array of display objects with id, name, friendlyName, isActive.

**`Get-AudioSnapshot`**
Returns hashtable with output/input device arrays.

**`Get-PropertyValue -Object <Object> -Property <String> [-Default <Any>]`**
Safe property retrieval with fallback.

### Validate-Config.ps1

#### Parameters
```powershell
-ConfigPath <String>  # Path to config.json
```

#### Main Function

**`Test-ConfigStructure -ConfigPath <String>`**
Validates config structure, returns boolean.

**Validations**:
- Required keys exist
- Profile structure valid
- Overlay settings in range
- Hotkeys well-formed
- Profile keys numeric

**Exit Codes**: 0=valid, 1=invalid

### Common.ps1

Shared utilities for future refactoring.

**`Ensure-ModuleInstalled -ModuleName <String>`**
Checks and installs PowerShell module if missing.

**`Get-NormalizedDisplayName -Name <String>`**
Shared display name normalization.

## Data Structures

### Config JSON Schema
```json
{
  "profiles": {
    "1": {
      "activeDisplays": ["Display Name"],
      "disableDisplays": ["Other Display"],
      "audio": "Device Name",
      "microphone": "Mic Name"
    }
  },
  "hotkeys": {
    "profiles": {"1": "Left Alt+Left Shift+1"},
    "cycleAudio": "Left Alt+Left Shift+7",
    "enableAll": "Left Alt+Left Shift+8",
    "openConfigurator": "Left Alt+Left Shift+9",
    "toggleOverlay": "Left Alt+Left Shift+0"
  },
  "overlay": {
    "fontName": "Segoe UI",
    "fontSize": 16,
    "fontBold": true,
    "textColor": "Blue",
    "backgroundColor": "Black",
    "opacity": 220,
    "position": "top-left",
    "marginX": 10,
    "marginY": 10,
    "durationMs": 10000,
    "notificationPosition": "top-center",
    "notificationDuration": 5000
  },
  "settings": {
    "enableMicrophoneManagement": false
  }
}
```

### Devices Snapshot Schema
```json
{
  "displays": [
    {
      "id": "DISPLAY\\DEV1234\\...",
      "name": "Generic Display",
      "friendlyName": "Dell U2720Q",
      "isActive": true
    }
  ],
  "audio": {
    "output": [
      {
        "id": "{guid}",
        "name": "Speakers (USB Audio)",
        "default": true
      }
    ],
    "input": [...]
  }
}
```

## Exit Codes

| Code | Meaning | Used By |
|------|---------|---------|
| 0 | Success | All scripts |
| 1 | Error/validation failed | switch_profile.ps1, Validate-Config.ps1 |
| 2 | User cancelled | configure_profiles.ps1 (menu exit) |

## Error Handling

### AutoHotkey
- **Fatal**: `ShowFatalError()` → MsgBox → `ExitApp()`
- **Warnings**: `LogMessage()` → log file only

### PowerShell
- **Terminating**: `throw` → bubbles to AHK → MsgBox
- **Non-terminating**: `Write-Log -Level WARN` → continue

## See Also
- [ARCHITECTURE.md](ARCHITECTURE.md) - System design
- [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) - Contributing
- [CONFIGURATION.md](CONFIGURATION.md) - Config options
