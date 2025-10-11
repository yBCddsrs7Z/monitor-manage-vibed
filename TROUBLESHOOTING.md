# Troubleshooting Guide

Solutions to common issues and problems with monitor-manage.

## Table of Contents
- [Installation Issues](#installation-issues)
- [Display Issues](#display-issues)
- [Audio Issues](#audio-issues)
- [Hotkey Issues](#hotkey-issues)
- [Configuration Issues](#configuration-issues)
- [Performance Issues](#performance-issues)
- [Logging and Diagnostics](#logging-and-diagnostics)

## Installation Issues

### AutoHotkey not found

**Symptom**: "AutoHotkey v2 not found" or script won't run

**Solutions**:
1. Install AutoHotkey v2 from [autohotkey.com/v2](https://www.autohotkey.com/v2/)
2. Verify installation:
   ```powershell
   Get-ChildItem "C:\Program Files\AutoHotkey\v2\" -Filter "*.exe"
   ```
3. Right-click `monitor-toggle.ahk` → "Run with AutoHotkey v2"

### PowerShell Module Installation Fails

**Symptom**: "Module 'DisplayConfig' could not be installed"

**Solutions**:

**Solution 1**: Manual installation
```powershell
# Run as Administrator
Install-Module -Name DisplayConfig -Scope AllUsers -Force
Install-Module -Name AudioDeviceCmdlets -Scope AllUsers -Force
```

**Solution 2**: Current user only
```powershell
Install-Module -Name DisplayConfig -Scope CurrentUser -Force
Install-Module -Name AudioDeviceCmdlets -Scope CurrentUser -Force
```

**Solution 3**: Check PowerShell Gallery connection
```powershell
# Test connection
Find-Module DisplayConfig

# Set TLS 1.2 (required for Gallery)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```

**Solution 4**: NuGet provider missing
```powershell
Install-PackageProvider -Name NuGet -Force
```

### Execution Policy Blocks Scripts

**Symptom**: "...cannot be loaded because running scripts is disabled"

**Solutions**:

**Solution 1**: Set execution policy for current user
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Solution 2**: Bypass for single script
```powershell
powershell -ExecutionPolicy Bypass -File scripts\switch_profile.ps1
```

**Solution 3**: Unblock scripts
```powershell
Get-ChildItem -Path scripts\*.ps1 | Unblock-File
```

## Display Issues

### Display Not Found

**Symptom**: "Display 'Monitor Name' not found" in log file

**Diagnosis**:
1. Check if display is powered on and connected
2. Verify display name:
   ```powershell
   pwsh -File scripts\export_devices.ps1
   # Open devices_snapshot.json and check display names
   ```

**Solutions**:

**Solution 1**: Update device snapshot
```powershell
pwsh -File scripts\export_devices.ps1
```
Then reconfigure profile with updated names.

**Solution 2**: Use configurator
Press `Left Alt+Left Shift+9`, edit profile, select correct display from list.

**Solution 3**: Check name matching
Display names in config.json must match **exactly** with names in devices_snapshot.json (case-sensitive).

### Display Remains Off After Profile Switch

**Symptom**: Display listed in `activeDisplays` stays black

**Solutions**:

**Solution 1**: Enable-all panic button
Press `Left Alt+Left Shift+8` to enable all displays.

**Solution 2**: Manual Windows activation
1. Right-click desktop → Display settings
2. Scroll down to "Multiple displays"
3. Click "Detect" button
4. Select display and choose "Extend" or "Duplicate"

**Solution 3**: Check DisplayConfig module
```powershell
Import-Module DisplayConfig
Get-Command -Module DisplayConfig
```

**Solution 4**: Restart graphics driver
Press `Win+Ctrl+Shift+B` (Windows shortcut to restart graphics driver).

### Wrong Display Enabled

**Symptom**: Different display than expected turns on

**Diagnosis**:
```powershell
# View current display IDs
pwsh -File scripts\export_devices.ps1
Get-Content devices_snapshot.json | ConvertFrom-Json | 
    Select-Object -ExpandProperty displays | 
    Format-Table id, name, friendlyName
```

**Solutions**:

**Solution 1**: Clear stale references
1. Delete `devices_snapshot.json`
2. Restart `monitor-toggle.ahk`
3. Reconfigure profiles

**Solution 2**: Use display IDs
Manually edit config.json to use display `id` instead of `name`.

### Laptop Screen Won't Disable

**Symptom**: Built-in display stays on despite being in `disableDisplays`

**Common Causes**:
- Laptop settings prevent disabling internal display
- Display is set as "primary" in Windows

**Solutions**:

**Solution 1**: Set external monitor as primary
1. Display settings → Select external monitor
2. Check "Make this my main display"
3. Try profile again

**Solution 2**: Physically close laptop lid
Some laptops require lid closed to disable internal display.

**Solution 3**: Use Windows display modes
Instead of disabling, set to "Show only on 2" (external only).

## Audio Issues

### Audio Device Not Switching

**Symptom**: Default audio device doesn't change after profile activation

**Diagnosis**:
```powershell
# Check available audio devices
pwsh -File scripts\export_devices.ps1
Get-Content devices_snapshot.json | ConvertFrom-Json | 
    Select-Object -ExpandProperty audio | 
    Select-Object -ExpandProperty output | 
    Format-Table name, default
```

**Solutions**:

**Solution 1**: Verify device name
Audio device name in config.json must match **exactly** with name in devices_snapshot.json.

**Solution 2**: Check AudioDeviceCmdlets module
```powershell
Import-Module AudioDeviceCmdlets
Get-AudioDevice -List
```

**Solution 3**: Update snapshot
```powershell
pwsh -File scripts\export_devices.ps1
```
Then reconfigure audio device in profile.

**Solution 4**: Test manually
```powershell
Import-Module AudioDeviceCmdlets
$device = Get-AudioDevice -List | Where-Object Name -eq "Your Device Name"
Set-AudioDevice -Index $device.Index
```

### Audio Cycles to Wrong Device

**Symptom**: `Left Alt+Left Shift+7` cycles to unexpected device

**Cause**: `cycle_audio.ps1` cycles through all detected output devices.

**Solutions**:

**Solution 1**: Use profiles instead
Define specific audio device in each profile rather than cycling.

**Solution 2**: Disable unwanted devices
Windows Settings → Sound → Disable devices you don't want in cycle.

## Hotkey Issues

### Hotkey Not Working

**Symptom**: Pressing hotkey does nothing

**Diagnosis**:
1. Check if `monitor-toggle.ahk` is running (tray icon)
2. Check log file:
   ```powershell
   Get-Content monitor-toggle.log -Tail 20
   ```

**Solutions**:

**Solution 1**: Verify hotkey registration
Look for "Registered profile X hotkey" in log file. If missing, hotkey failed to register.

**Solution 2**: Check for conflicts
Another application may be capturing the hotkey. Try different combination:
```json
{
  "hotkeys": {
    "profiles": {
      "1": "Ctrl+Alt+F1"
    }
  }
}
```

**Solution 3**: Restart AutoHotkey
Close and restart `monitor-toggle.ahk`.

**Solution 4**: Test simple hotkey
Temporarily change to simple hotkey (e.g., `F12`) to isolate issue.

### Wrong Profile Activates

**Symptom**: Pressing hotkey activates different profile than expected

**Cause**: Closure bug in older versions (should be fixed in current version).

**Solutions**:

**Solution 1**: Update to latest version
Ensure you have version with `CreateSetConfigHandler` closure fix.

**Solution 2**: Verify hotkey configuration
```json
{
  "hotkeys": {
    "profiles": {
      "1": "Left Alt+Left Shift+1",  // Should activate profile 1
      "2": "Left Alt+Left Shift+2",  // Should activate profile 2
      "3": "Left Alt+Left Shift+3"   // Should activate profile 3
    }
  }
}
```

**Solution 3**: Check log file
Log should show: "Hotkey <!<+1 requested profile 1"

### Hotkey Conflicts with Other Apps

**Symptom**: Hotkey works in some apps but not others (e.g., games, browsers)

**Cause**: Other application captures hotkey first.

**Solutions**:

**Solution 1**: Use less common modifiers
```json
"hotkeys": {
  "profiles": {
    "1": "Ctrl+Alt+Win+1"  // Triple modifier
  }
}
```

**Solution 2**: Use function keys
```json
"hotkeys": {
  "profiles": {
    "1": "Ctrl+F13"  // F13-F24 rarely used
  }
}
```

**Solution 3**: Check game overlay hotkeys
Disable overlays (Discord, Steam, GeForce Experience) or change their hotkeys.

## Configuration Issues

### Config.json Won't Load

**Symptom**: "Failed to parse config.json" error

**Diagnosis**:
```powershell
# Validate JSON syntax
Get-Content config.json | ConvertFrom-Json
```

**Solutions**:

**Solution 1**: Fix JSON syntax
Common errors:
- Missing commas between elements
- Extra trailing commas
- Unmatched braces/brackets
- Unescaped quotes in strings

Use online JSON validator: https://jsonlint.com/

**Solution 2**: Restore default
Rename broken config:
```powershell
Rename-Item config.json config.json.backup
```
Restart script to generate fresh config.

**Solution 3**: Use configurator
Let configurator rebuild config:
1. Delete or rename config.json
2. Start monitor-toggle.ahk
3. Press `Left Alt+Left Shift+9`
4. Add profiles via menu

### Validation Errors

**Symptom**: Script shows validation errors on startup

**Diagnosis**:
```powershell
pwsh -File scripts\Validate-Config.ps1 -ConfigPath config.json
```

**Common Errors**:

**Error**: "Profile key 'abc' is not numeric"
```json
// Wrong
"profiles": {
  "abc": { ... }
}

// Correct
"profiles": {
  "1": { ... }
}
```

**Error**: "opacity must be 0-255"
```json
// Wrong
"overlay": {
  "opacity": 300
}

// Correct
"overlay": {
  "opacity": 220
}
```

**Error**: "position invalid"
```json
// Wrong
"overlay": {
  "position": "middle-center"
}

// Correct
"overlay": {
  "position": "center"
}
```

### Profiles Not Showing in Overlay

**Symptom**: Overlay shows "No profiles configured" but config.json has profiles

**Diagnosis**:
1. Check if profile keys are numeric
2. Verify profiles section exists

**Solutions**:

**Solution 1**: Validate config structure
```powershell
pwsh -File scripts\Validate-Config.ps1
```

**Solution 2**: Check profile keys
```json
{
  "profiles": {
    "1": { ... },  // Must be string numbers
    "2": { ... },  // Not integers!
    "three": { ... }  // This will be removed!
  }
}
```

**Solution 3**: Reload config
Restart `monitor-toggle.ahk` after config changes.

## Performance Issues

### Slow Profile Switching

**Symptom**: 3-10 seconds delay when switching profiles

**Expected**: Normal delay is 500ms - 2000ms due to Windows display configuration API.

**Solutions**:

**Solution 1**: Reduce number of displays
Each display adds ~200-500ms to switch time.

**Solution 2**: Disable snapshot refresh
Edit `switch_profile.ps1`, comment out:
```powershell
# Update-DeviceSnapshotIfPossible -SnapshotPath $devicesSnapshotPath
```

**Note**: Manual snapshot updates required after hardware changes.

**Solution 3**: Profile performance
```powershell
pwsh -File tests\Profile-Performance.ps1 -Iterations 10
```

### High CPU Usage

**Symptom**: monitor-toggle.ahk using high CPU

**Diagnosis**:
1. Check Task Manager for process
2. Check log file for errors

**Solutions**:

**Solution 1**: Disable overlay auto-show
Remove overlay display from startup sequence in monitor-toggle.ahk.

**Solution 2**: Increase overlay duration
Reduce overlay show frequency:
```json
{
  "overlay": {
    "durationMs": 5000  // Shorter = less frequent
  }
}
```

**Solution 3**: Check for infinite loops
Review `monitor-toggle.log` for repeated error messages.

### Script Crashes

**Symptom**: monitor-toggle.ahk closes unexpectedly

**Diagnosis**:
```powershell
# Check Windows Event Viewer
Get-EventLog -LogName Application -Source "AutoHotkey" -Newest 10
```

**Solutions**:

**Solution 1**: Check log file
```powershell
Get-Content monitor-toggle.log -Tail 50
```

**Solution 2**: Run in debug mode
Add to top of monitor-toggle.ahk:
```ahk
#Warn All, MsgBox
```

**Solution 3**: Test with minimal config
Create minimal config with single profile.

## Logging and Diagnostics

### Enable Verbose Logging

**AutoHotkey**: Already logs to `monitor-toggle.log`

**PowerShell**: Add `-Verbose` flag:
```ahk
; In SetConfig() function:
command := Format('powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Verbose -File "{1}" -profileKey "{2}"', psScript, profileKey)
```

### View Log File

```powershell
# Tail log (live updates)
Get-Content monitor-toggle.log -Tail 20 -Wait

# Filter errors only
Select-String -Path monitor-toggle.log -Pattern "ERROR"

# View last 50 lines
Get-Content monitor-toggle.log -Tail 50
```

### Collect Diagnostics

```powershell
# Create diagnostic bundle
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$diagPath = "diagnostics-$timestamp"
New-Item -ItemType Directory -Path $diagPath

# Copy relevant files
Copy-Item config.json, devices_snapshot.json, monitor-toggle.log -Destination $diagPath -ErrorAction SilentlyContinue

# Export system info
Get-ComputerInfo | Out-File "$diagPath\system-info.txt"
Get-Module -ListAvailable DisplayConfig, AudioDeviceCmdlets | Out-File "$diagPath\modules.txt"

# Compress
Compress-Archive -Path $diagPath -DestinationPath "$diagPath.zip"
Write-Host "Diagnostics saved to: $diagPath.zip"
```

### Test Individual Components

**Test Display Enumeration**:
```powershell
pwsh -File scripts\export_devices.ps1 -OutputPath test-devices.json
Get-Content test-devices.json | ConvertFrom-Json | Format-List
```

**Test Profile Switch** (manual):
```powershell
pwsh -File scripts\switch_profile.ps1 -profileKey "1" -Verbose
```

**Test Config Validation**:
```powershell
pwsh -File scripts\Validate-Config.ps1 -ConfigPath config.json -Verbose
```

**Test Hotkey Conversion**:
```ahk
; Add to monitor-toggle.ahk (temporary)
descriptor := "Left Alt+Left Shift+1"
ahkKey := ConvertDescriptorToAhkHotkey(descriptor)
MsgBox("Descriptor: " descriptor "`nAHK Key: " ahkKey)
```

## Getting Help

### Check Documentation

1. [README.md](README.md) - Basic usage
2. [CONFIGURATION.md](CONFIGURATION.md) - Config reference
3. [API_REFERENCE.md](API_REFERENCE.md) - Function docs
4. [ARCHITECTURE.md](ARCHITECTURE.md) - System design

### Search Issues

Check [GitHub Issues](https://github.com/yBCddsrs7Z/monitor-manage-vibed/issues) for similar problems.

### Report a Bug

Include:
1. **Description**: What happened vs. what you expected
2. **Steps to reproduce**: Minimal steps to trigger issue
3. **Environment**:
   - Windows version
   - PowerShell version (`$PSVersionTable`)
   - AutoHotkey version
   - Module versions
4. **Logs**: Relevant sections from `monitor-toggle.log`
5. **Config**: Sanitized `config.json` (remove personal info)

### Community Support

- **GitHub Discussions**: General questions
- **GitHub Issues**: Bug reports and feature requests

## Quick Reference

### Common Commands

```powershell
# Export devices
pwsh -File scripts\export_devices.ps1

# Validate config
pwsh -File scripts\Validate-Config.ps1

# Run tests
pwsh -File tests\run-all-tests.ps1

# Profile performance
pwsh -File tests\Profile-Performance.ps1

# View log
Get-Content monitor-toggle.log -Tail 20 -Wait
```

### Common Hotkeys (Defaults)

| Hotkey | Action |
|--------|--------|
| `Left Alt+Left Shift+1-6` | Activate profile 1-6 |
| `Left Alt+Left Shift+7` | Cycle audio |
| `Left Alt+Left Shift+8` | Enable all displays |
| `Left Alt+Left Shift+9` | Open configurator |
| `Left Alt+Left Shift+0` | Toggle overlay |

### Emergency Recovery

**If everything is broken:**
1. Close `monitor-toggle.ahk` (right-click tray icon → Exit)
2. Rename config.json to config.json.backup
3. Delete devices_snapshot.json
4. Restart monitor-toggle.ahk (creates fresh config)
5. Press `Left Alt+Left Shift+9` to reconfigure
