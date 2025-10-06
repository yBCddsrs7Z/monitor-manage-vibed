# monitor-manage

AutoHotkey automation that presents hotkeys for switching between display/audio layouts, with an optional overlay showing layouts and hotkeys.

**Original code** by [Matt Drayton](https://github.com/matt-drayton)  
Vibed with Claude Sonnet 4.5 Thinking

## Overview
`monitor-manage` lets you toggle between customizable monitor and audio "profiles" with AutoHotkey hotkeys. The AutoHotkey entry point (`monitor-toggle.ahk`) invokes the PowerShell helpers in `scripts/` to capture the current device inventory, resolve the displays you named in `config.json`, and call the `DisplayConfig` / `AudioDeviceCmdlets` modules to apply the requested state. Each switch now refreshes `devices_snapshot.json` automatically so the configuration survives changing display identifiers and lid-close scenarios.

## Requirements
- **Windows**: Windows 10/11 with either PowerShell 5.1 or PowerShell 7+
- **AutoHotkey**: AutoHotkey v2 (required by `monitor-toggle.ahk`)
- **Execution policy**: Allow the bundled PowerShell scripts to run (for example `Set-ExecutionPolicy RemoteSigned`)
- **Modules**: The first execution of the PowerShell helpers will prompt to install `DisplayConfig` and `AudioDeviceCmdlets` for the current user if they are missing

## Project Layout
- **`monitor-toggle.ahk`** – AutoHotkey runner that binds hotkeys, writes `monitor-toggle.log`, and invokes the PowerShell helpers
- **`scripts/`** – PowerShell helpers (`switch_profile.ps1`, `configure_profiles.ps1`, `export_devices.ps1`, etc.)
- **`config.json`** – profile definitions (enabled / disabled display names plus audio device)
- **`monitor-toggle.log`** – Rolling log with switch attempts, warnings, and installer prompts
- **`tests/`** – Pester test harnesses (`RunTests.ps1`, `InspectMerge.ps1`, …) for development verification

Keep all of these files in the same directory (for example `C:\Progs\monitor-manage`). All paths resolve relative to the AutoHotkey script.

## Installation and Setup

### Prerequisites

**Required:**
- Windows 10/11
- PowerShell 5.1+ (built-in) or PowerShell 7+ (recommended)
- AutoHotkey v2 - [Download here](https://www.autohotkey.com/v2/)

**Auto-installed:**
- `DisplayConfig` PowerShell module (installs on first run)
- `AudioDeviceCmdlets` PowerShell module (installs on first run)

### Quick Install

1. **Download the project:**
   ```powershell
   git clone https://github.com/yBCddsrs7Z/monitor-manage-vibed.git
   cd monitor-manage-vibed
   ```
   
   Or download as ZIP and extract to a folder like `C:\Progs\monitor-manage`

2. **Check requirements:**
   ```powershell
   pwsh -File scripts/check_requirements.ps1
   ```
   
3. **Install required modules** (if not auto-installing):
   ```powershell
   Install-Module -Name DisplayConfig -Scope CurrentUser -Force
   Install-Module -Name AudioDeviceCmdlets -Scope CurrentUser -Force
   ```

4. **Set execution policy** (if needed):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

5. **Run the script:**
   - Double-click `monitor-toggle.ahk` to start
   - Or right-click → Run with AutoHotkey v2

### First-Time Setup Guide

Once `monitor-toggle.ahk` is running:

1. **Export your devices:**
   ```powershell
   pwsh -File scripts/export_devices.ps1
   ```
   This creates `devices_snapshot.json` with your current displays and audio devices.

2. **Open the configurator:**
   - Press `Left Alt+Left Shift+9`
   - Or run: `pwsh -File scripts/configure_profiles.ps1`

3. **Create your first profile:**
   - Choose option **1** (Add new profile)
   - Select which displays should be **active** (enabled)
   - Select which displays should be **disabled**
   - Choose your audio output device (optional)
   - Repeat for additional profiles

4. **Test your profiles:**
   - Press `Left Alt+Left Shift+1` to activate Profile 1
   - Press `Left Alt+Left Shift+2` to activate Profile 2
   - etc.

5. **View your profiles:**
   - Press `Left Alt+Left Shift+0` to toggle the overlay
   - Shows all configured profiles and their hotkeys

### Default Hotkeys

| Hotkey | Action |
|--------|--------|
| `Left Alt+Left Shift+1-6` | Switch to profile 1-6 |
| `Left Alt+Left Shift+7` | Cycle audio output device |
| `Left Alt+Left Shift+8` | Enable all displays (panic button) |
| `Left Alt+Left Shift+9` | Open configurator |
| `Left Alt+Left Shift+0` | Toggle profile overlay |

### Verify Installation

Check everything works:
```powershell
# Verify modules are installed
Get-Module -ListAvailable DisplayConfig, AudioDeviceCmdlets

# Validate your config
pwsh -File scripts/Validate-Config.ps1

# Run tests (optional)
pwsh -File tests/run-all-tests.ps1
```

## Configuring profiles
- **Interactive workflow:** Press `Left Alt+Left Shift+9` (or run `scripts/configure_profiles.ps1`) to edit groups interactively. The script loads the current configuration, lists detected displays from `devices_snapshot.json`, and lets you add/edit/remove groups without touching JSON by hand.
- **Quick reference:** Press `Left Alt+Left Shift+0` to toggle an on-screen overlay (upper-left, blue text) that lists every profile, the displays each enables/disables, and the audio output that will be selected.
- **Storage:** Saved profiles live in `config.json`. Each entry contains `activeDisplays`, `disableDisplays`, and an optional `audio` friendly name.

## Switching Behaviour
- **Name-first resolution:** profiles are matched via the display names captured in the snapshot. Stored `displayId` values are kept in `config.json` for reference but the switching script no longer reuses stale IDs—it always relies on the latest export or snapshot data.
- **Automatic snapshot regeneration:** `switch_profile.ps1` calls `export_devices.ps1` before every operation, so changes such as docking/undocking or lid actions are accounted for automatically.
- **Logging:** Every switch attempt appends entries to `monitor-toggle.log` (created beside the scripts). Warnings are emitted when a requested display or audio device is not detected. The summary window (`Left Alt+Left Shift+0`) is generated on demand from the current `config.json`.

## Troubleshooting
- **Display missing from a group:** Ensure Windows sees the display (open Display Settings), then press `Left Alt+Left Shift+9` to open the configurator which will rebuild the snapshot. The switch script already refreshes snapshots automatically, but re-exporting ensures the fallback file is accurate.
- **Modules fail to load:** From an elevated PowerShell prompt run `Import-Module DisplayConfig` and `Import-Module AudioDeviceCmdlets` to confirm the modules are available. Re-run the helper to trigger installation prompts if needed.
- **Logs & diagnostics:** Inspect `monitor-toggle.log` for the exact IDs and warnings emitted during a switch. When filing an issue, include the relevant snippet along with your `config.json` entries.
- **Testing the helpers:** Run `pwsh -File tests/RunTests.ps1` to execute the Pester suite and validate recent code changes.

## Testing

This project has comprehensive test coverage including **PowerShell** and **AutoHotkey** tests with automated CI/CD.

- **Quick Start**: `pwsh -File tests/run-all-tests.ps1`
- **Complete Guide**: See [TESTING.md](TESTING.md) for full testing documentation
- **Test Coverage**: See [tests/README.md](tests/README.md) for detailed test breakdown
- **CI/CD**: Automated testing via GitHub Actions on every push/PR
- **Performance**: Profile with `pwsh -File tests/Profile-Performance.ps1`

**PowerShell Tests**: 54/54 passing ✅
- ConfigureProfiles: 21/21 (device inventory, merging, auto-renumbering)
- ConfigureProfilesIntegration: 9/9 (array unwrapping, _documentation filtering)
- SwitchProfile: 13/13 (resolution, normalization, edge cases)
- ExportDevices: 4/4 (property retrieval, JSON validation)
- ValidateConfig: 7/7 (schema validation, error detection)

**AutoHotkey Tests**: NEW ✅
- Config loading and parsing
- Hotkey registration and closure bug prevention
- Helper function validation

## Configuration Reference

### Profiles (`profiles`)
Six empty profiles (`"1"`-`"6"`) are provided by default. Add additional numeric keys if you need more saved layouts.

### Hotkeys (`hotkeys`)
- **`profiles`**: Provide readable descriptors such as `Alt+Shift+1`, `Ctrl+Alt+F1`, or `Left Win+Shift+P`. Modifiers support `Alt`, `Shift`, `Ctrl`, `Win`, optionally prefixed with `Left`/`Right`.
- **`cycleAudio` / `enableAll` / `openConfigurator` / `toggleOverlay`**: Set to any descriptor. Defaults remain `Alt+Shift+7`, `Alt+Shift+8`, `Alt+Shift+9`, and `Alt+Shift+0` respectively.

### Overlay (`overlay`)
- **`position`**: Accepts `top-left`, `top-right`, `bottom-left`, or `bottom-right`.
- **`backgroundColor` / `textColor`**: Any AutoHotkey-supported color name (e.g., `Black`, `White`, `Silver`) or hex value (`#RRGGBB`).
- **`fontName`**: System font family (e.g., `Segoe UI`, `Consolas`).
- **`fontSize`**: Point size (integer).
- **`fontBold`**: `true`/`false` (or `1`/`0`) to toggle bold text.
- **`marginX`, `marginY`**: Pixel offsets from the chosen screen edge.
- **`durationMs`**: How long the overlay remains visible before auto-hide.
- **`opacity`**: 0-255 (lower is more transparent).

## Startup (Optional)
If you want the hotkeys available after login:
- **Create a shortcut** to `monitor-toggle.ahk`
- **Open** the Startup folder (`Win + R`, then `shell:startup`)
- **Place the shortcut** in the folder so AutoHotkey launches automatically with Windows

You can also map the hotkeys through Steam Input or other automation tools once `monitor-toggle.ahk` is running.

