# Architecture Documentation

## Overview

`monitor-manage` is a hybrid AutoHotkey + PowerShell system for managing display and audio profiles on Windows. The architecture separates concerns between:

- **AutoHotkey** (UI layer): Hotkey registration, overlay display, configuration loading
- **PowerShell** (Business logic): Device enumeration, profile switching, configuration management
- **PowerShell Modules** (Hardware layer): `DisplayConfig` and `AudioDeviceCmdlets` for low-level device control

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    USER INTERACTION                          │
│  (Hotkey Press, e.g., Left Alt+Left Shift+1)               │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              monitor-toggle.ahk (AutoHotkey v2)             │
│  • Hotkey registration and handling                         │
│  • Configuration loading and validation                     │
│  • Overlay UI management                                    │
│  • Logging                                                  │
└────────────────────┬────────────────────────────────────────┘
                     │ (Invokes via RunWait)
                     ▼
┌─────────────────────────────────────────────────────────────┐
│           scripts/ (PowerShell Layer)                       │
│  ┌──────────────────────────────────────────────────┐      │
│  │ switch_profile.ps1                               │      │
│  │  • Profile resolution                            │      │
│  │  • Display state management                      │      │
│  │  • Audio device switching                        │      │
│  └────────────┬─────────────────────────────────────┘      │
│               │                                             │
│  ┌────────────▼─────────────────────────────────────┐      │
│  │ configure_profiles.ps1                           │      │
│  │  • Interactive profile editor                    │      │
│  │  • Device selection UI                           │      │
│  │  • Config.json manipulation                      │      │
│  └────────────┬─────────────────────────────────────┘      │
│               │                                             │
│  ┌────────────▼─────────────────────────────────────┐      │
│  │ export_devices.ps1                               │      │
│  │  • Device snapshot generation                    │      │
│  │  • Metadata collection                           │      │
│  └──────────────────────────────────────────────────┘      │
└────────────────────┬────────────────────────────────────────┘
                     │ (Uses)
                     ▼
┌─────────────────────────────────────────────────────────────┐
│         PowerShell Modules (Hardware Abstraction)           │
│  ┌──────────────────────┐  ┌─────────────────────┐         │
│  │  DisplayConfig       │  │ AudioDeviceCmdlets  │         │
│  │  • Display topology  │  │ • Audio enumeration │         │
│  │  • State changes     │  │ • Default switching │         │
│  └──────────────────────┘  └─────────────────────┘         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│            Windows Display/Audio APIs                       │
│  • CCD (Connecting and Configuring Displays)               │
│  • MMDevice API                                             │
└─────────────────────────────────────────────────────────────┘
```

## Component Breakdown

### 1. AutoHotkey Layer (`monitor-toggle.ahk`)

**Purpose**: Lightweight UI and hotkey orchestration

**Responsibilities**:
- Register global hotkeys from configuration
- Load and validate `config.json`
- Display overlay with profile summaries
- Invoke PowerShell scripts via `RunWait()`
- Maintain activity log in `monitor-toggle.log`

**Key Functions**:
- `LoadConfig()` - Loads and normalizes configuration
- `RegisterConfiguredHotkeys()` - Binds hotkeys dynamically
- `SetConfig(profileKey)` - Invokes profile switch
- `ToggleProfileOverlay()` - Shows/hides profile summary
- `ValidateConfigAndNotify()` - Validates config structure

**Design Patterns**:
- **Closure Pattern**: `CreateSetConfigHandler()` creates closures to capture profile keys by value, preventing the "last profile wins" bug
- **Factory Pattern**: Hotkey handlers are created via factory functions
- **Singleton Pattern**: Global state management for overlay GUI

### 2. PowerShell Scripts Layer

#### `switch_profile.ps1`

**Purpose**: Core profile switching logic

**Workflow**:
1. **Refresh snapshot**: Calls `export_devices.ps1` to update device list
2. **Load configuration**: Reads `config.json` and parses profile definition
3. **Resolve displays**: Matches profile display names to current hardware
4. **Apply changes**:
   - Enable specified displays via `DisplayConfig`
   - Disable specified displays via `DisplayConfig`
   - Switch audio output via `AudioDeviceCmdlets`
5. **Log results**: Records success/warnings to `monitor-toggle.log`

**Key Functions**:
- `Update-DeviceSnapshotIfPossible()` - Refreshes device data
- `Resolve-DisplayIdentifiers()` - Maps names to display IDs
- `Set-DisplayState()` - Enables/disables displays
- `Set-AudioDevice()` - Switches default audio output
- `Get-NormalizedDisplayName()` - Normalizes display names for matching

**Error Handling**:
- Warnings (non-fatal): Missing displays, missing audio devices
- Errors (fatal): Module not found, config parse failure, invalid profile

#### `configure_profiles.ps1`

**Purpose**: Interactive configuration editor

**Workflow**:
1. Export current devices to `devices_snapshot.json`
2. Load existing `config.json` (or create default)
3. Present menu:
   - Add new profile
   - Edit existing profile
   - Delete profile
   - View profiles
   - Customize hotkeys
   - Customize overlay
4. Save updated configuration back to `config.json`

**Key Functions**:
- `Get-DeviceInventory()` - Retrieves available displays/audio devices
- `Add-Profile()` - Creates new profile interactively
- `Edit-Profile()` - Modifies existing profile
- `Remove-Profile()` - Deletes profile
- `Select-DisplayReferencesMultiple()` - Multi-select UI for displays
- `Optimize-ProfileKeys()` - Renumbers profiles to remove gaps

**Features**:
- Color-coded terminal UI
- Input validation
- Auto-renumbering of profiles
- Hotkey conflict detection

#### `export_devices.ps1`

**Purpose**: Device snapshot generation

**Workflow**:
1. Enumerate displays via `DisplayConfig` module
2. Enumerate audio devices via `AudioDeviceCmdlets` module
3. Extract metadata (IDs, names, states)
4. Serialize to JSON format
5. Write to `devices_snapshot.json`

**Key Functions**:
- `Get-DisplaySnapshot()` - Captures display metadata
- `Get-AudioSnapshot()` - Captures audio device metadata
- `Get-PropertyValue()` - Safe property extraction

**Output Schema**:
```json
{
  "displays": [
    {
      "id": "DISPLAY\\ABC123\\...",
      "name": "Generic Display",
      "friendlyName": "Dell U2720Q",
      "isActive": true
    }
  ],
  "audio": {
    "output": [
      {
        "id": "{device-guid}",
        "name": "Speakers (USB Audio)",
        "default": true
      }
    ]
  }
}
```

#### `Validate-Config.ps1`

**Purpose**: Configuration schema validation

**Validations**:
- Required top-level keys exist (`profiles`, `hotkeys`, `overlay`)
- Profile structure is valid (activeDisplays, disableDisplays, audio)
- Overlay settings are within valid ranges
- Hotkey descriptors are well-formed
- Profile keys are numeric

**Exit Codes**:
- `0` - Valid configuration
- `1` - Validation failed with errors

### 3. Shared Utilities (`Common.ps1`)

**Purpose**: Reusable functions to eliminate duplication

**Categories**:
- **Logging**: `Write-Log`, `Write-Verbose`
- **Module Management**: `Ensure-ModuleInstalled`, `Import-RequiredModules`
- **Display Utilities**: `Get-NormalizedDisplayName`, `ConvertTo-DisplayReferenceArray`
- **Property Access**: `Get-PropertyValue`, safe property extraction

## Data Flow

### Profile Switch Flow

```
User Presses Hotkey
       ↓
AHK: A_ThisHotkey triggered
       ↓
AHK: CreateSetConfigHandler closure called
       ↓
AHK: SetConfig(profileKey) executes
       ↓
AHK: RunWait("pwsh switch_profile.ps1 -profileKey X")
       ↓
PS: Load config.json
       ↓
PS: Refresh devices_snapshot.json
       ↓
PS: Parse profile X definition
       ↓
PS: Resolve display names → IDs
       ↓
PS: Call DisplayConfig module (enable/disable displays)
       ↓
PS: Call AudioDeviceCmdlets module (switch audio)
       ↓
PS: Write log entries
       ↓
PS: Exit with code (0=success, 1=error)
       ↓
AHK: Check exit code
       ↓
AHK: Show success/error notification
       ↓
AHK: Update scripts/active_profile marker
```

### Configuration Loading Flow

```
AHK Startup
       ↓
LoadConfig() called
       ↓
Check if config.json exists
       ↓
   No: Create default config with GetDefaultConfig()
       ↓
   Yes: Read and parse JSON (via jxon_load)
       ↓
NormalizeConfigStructure()
  • Add missing top-level keys
  • Merge default hotkeys
  • Merge default overlay settings
  • Migrate legacy "groups" → "profiles"
  • Remove non-numeric profile keys
  • Normalize hotkey descriptors
       ↓
WriteConfigToFile() if changed
       ↓
Return config Map object
```

## Configuration Schema

### Top-Level Structure

```json
{
  "profiles": { ... },      // Profile definitions (required)
  "hotkeys": { ... },       // Hotkey bindings (required)
  "overlay": { ... },       // Overlay appearance (required)
  "settings": { ... },      // Global settings (optional)
  "_documentation": { ... } // Inline help (ignored by code)
}
```

### Profile Schema

```json
{
  "profiles": {
    "1": {
      "activeDisplays": ["Display Name 1", "Display Name 2"],
      "disableDisplays": ["Display Name 3"],
      "audio": "Speakers (USB Audio)",
      "microphone": "Microphone (USB Audio)"  // Optional
    }
  }
}
```

### Hotkey Schema

```json
{
  "hotkeys": {
    "profiles": {
      "1": "Left Alt+Left Shift+1",
      "2": "Left Alt+Left Shift+2"
    },
    "cycleAudio": "Left Alt+Left Shift+7",
    "enableAll": "Left Alt+Left Shift+8",
    "openConfigurator": "Left Alt+Left Shift+9",
    "toggleOverlay": "Left Alt+Left Shift+0"
  }
}
```

## State Management

### File-Based State

1. **`config.json`** - Persistent configuration
   - Manually edited or via configurator
   - Validated on load and startup

2. **`devices_snapshot.json`** - Current hardware state
   - Regenerated before each profile switch
   - Used by configurator for device selection

{{ ... }}
   - Simple text file containing profile key (e.g., "3")
   - Updated after successful profile switch

4. **`monitor-toggle.log`** - Activity audit trail
   - Append-only log file
   - Timestamped entries with severity levels (INFO, WARN, ERROR)

### Runtime State (AutoHotkey)

- **Global Variables**:
  - `config` - Loaded configuration Map
  - `overlayVisible` - Boolean for overlay state
  - `overlayGui` - GUI object reference
  - `overlaySettingsCache` - Cached overlay settings

- **No Persistent Runtime State**: AutoHotkey script is stateless between hotkey invocations

## Error Handling Strategy

### AutoHotkey Layer

- **Fatal Errors**: Call `ShowFatalError()` → display MsgBox → `ExitApp()`
  - Config load failure
  - PowerShell script not found
  - JSON parse errors

- **Warnings**: Call `LogMessage()` → append to log file
  - Missing profile
  - Invalid hotkey descriptor
  - Module installation prompt

### PowerShell Layer

- **Terminating Errors**: Throw exception → bubbles to AHK → shown in MsgBox
  - Config file not found
  - Required module missing (after install attempt)
  - Invalid profile key

- **Non-Terminating Warnings**: Log to file, continue execution
  - Display not found (skip it)
  - Audio device not found (skip audio switch)
  - Snapshot refresh failed (use stale data)

## Performance Considerations

### Bottlenecks

1. **PowerShell Startup**: ~200-500ms per invocation
   - Mitigated by: Minimal invocations, user-initiated actions

2. **Module Import**: ~100-300ms first time
   - Mitigated by: PowerShell module caching, rare operation

3. **Device Enumeration**: ~50-200ms
   - Mitigated by: Snapshot caching between switches

4. **Display Changes**: ~500-2000ms (Windows CCD API)
   - Unavoidable: OS-level operation

### Optimizations

- **Lazy Loading**: Modules imported only when needed
- **Snapshot Reuse**: Devices exported once, reused for multiple lookups
- **Async Notifications**: Overlay shows immediately, config validation happens in background
- **Closure Binding**: Pre-bind profile handlers to avoid runtime lookup

## Security Considerations

### Execution Policy

- Scripts require `RemoteSigned` or `Bypass` execution policy
- User prompted on first run to install PowerShell modules
- No elevation required for normal operation

### File Access

- All file operations within project directory
- No registry modifications
- No system-wide changes (except optional startup shortcut)

### API Surface

- Uses official Microsoft Windows APIs via PowerShell modules
- No P/Invoke or DllCall (except WScript.Shell for validation)
- No network communication

## Extensibility Points

### Adding New Profile Types

1. Add fields to profile schema in `GetDefaultConfig()`
2. Update `configure_profiles.ps1` to handle new fields
3. Update `switch_profile.ps1` to apply new settings
4. Update validation in `Validate-Config.ps1`

### Adding New Hotkey Actions

1. Define handler function in `monitor-toggle.ahk`
2. Add default binding in `GetDefaultConfig()` hotkeys
3. Register in `RegisterConfiguredHotkeys()`
4. Document in README

### Custom Modules

To integrate a new device type:
1. Install PowerShell module
2. Create helper function in `Common.ps1`
3. Update `export_devices.ps1` snapshot format
4. Update `switch_profile.ps1` to apply changes

## Testing Architecture

### Unit Tests (PowerShell)

- **Location**: `tests/*.Tests.ps1`
- **Framework**: Pester v3/v4
- **Coverage**: 54 tests across 5 test files
- **Isolation**: Environment variables suppress main logic

### Integration Tests (AutoHotkey)

- **Location**: `tests/monitor-toggle.Tests.ahk`
- **Framework**: Custom test framework (`ahk-test-framework.ahk`)
- **Coverage**: Config loading, hotkey registration, closure bug prevention

### CI/CD

- **Platform**: GitHub Actions
- **Trigger**: Every push and pull request
- **Jobs**:
  - PowerShell syntax validation
  - Pester test execution
  - Config schema validation
  - AutoHotkey test execution (if AHK v2 available)

## Deployment Architecture

### Standalone Deployment

```
monitor-manage/
├── monitor-toggle.ahk          (Entry point)
├── _JXON.ahk                   (JSON library)
├── config.json                 (User config)
├── devices_snapshot.json       (Hardware state)
├── monitor-toggle.log          (Activity log)
└── scripts/
    ├── switch_profile.ps1
    ├── configure_profiles.ps1
    ├── export_devices.ps1
    ├── cycle_audio.ps1
    ├── Validate-Config.ps1
    └── Common.ps1
```

All paths are relative - entire folder is portable.

### Startup Integration

- **Manual**: User double-clicks `monitor-toggle.ahk`
- **Startup Shortcut**: `.lnk` file in `shell:startup` folder
- **Task Scheduler**: Not required (AutoHotkey runs in user session)