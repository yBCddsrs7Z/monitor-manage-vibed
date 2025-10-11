# Developer Guide

Guide for contributors and developers working on monitor-manage.

## Table of Contents
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Debugging](#debugging)
- [Common Tasks](#common-tasks)
- [Contributing](#contributing)

## Development Setup

### Prerequisites

1. **AutoHotkey v2**: [Download here](https://www.autohotkey.com/v2/)
2. **PowerShell**: 5.1+ (built-in) or 7+ (recommended)
3. **Pester**: Testing framework
   ```powershell
   Install-Module -Name Pester -Force -SkipPublisherCheck
   ```
4. **Git**: For version control
5. **VS Code** (recommended) with extensions:
   - AutoHotkey v2 Language Support
   - PowerShell

### Clone and Setup

```powershell
# Clone repository
git clone https://github.com/yBCddsrs7Z/monitor-manage-vibed.git
cd monitor-manage-vibed

# Install PowerShell modules
Install-Module -Name DisplayConfig -Scope CurrentUser -Force
Install-Module -Name AudioDeviceCmdlets -Scope CurrentUser -Force

# Verify setup
pwsh -File scripts/check_requirements.ps1

# Run tests
pwsh -File tests/run-all-tests.ps1
```

## Project Structure

```
monitor-manage/
├── monitor-toggle.ahk         # Main entry point (AHK v2)
├── _JXON.ahk                  # JSON library for AHK
├── config.json                # User configuration (gitignored)
├── devices_snapshot.json      # Hardware state (gitignored)
├── monitor-toggle.log         # Activity log (gitignored)
│
├── scripts/                   # PowerShell helpers
│   ├── switch_profile.ps1     # Core switching logic
│   ├── configure_profiles.ps1 # Interactive editor
│   ├── export_devices.ps1     # Device enumeration
│   ├── cycle_audio.ps1        # Audio cycling
│   ├── Validate-Config.ps1    # Config validation
│   ├── Common.ps1             # Shared utilities
│   └── check_requirements.ps1 # Setup verification
│
├── tests/                     # Test suite
│   ├── run-all-tests.ps1      # Test runner
│   ├── ConfigureProfiles.Tests.ps1
│   ├── SwitchProfile.Tests.ps1
│   ├── ExportDevices.Tests.ps1
│   ├── ValidateConfig.Tests.ps1
│   ├── ConfigureProfilesIntegration.Tests.ps1
│   ├── monitor-toggle.Tests.ahk
│   ├── ahk-test-framework.ahk
│   └── Profile-Performance.ps1
│
├── .github/                   # CI/CD
│   └── workflows/
│       └── test.yml           # GitHub Actions workflow
│
└── docs/                      # Documentation
    ├── README.md
    ├── ARCHITECTURE.md
    ├── API_REFERENCE.md
    ├── DEVELOPER_GUIDE.md     # This file
    ├── CONFIGURATION.md
    ├── CHANGELOG.md
    └── TESTING.md
```

## Coding Standards

### AutoHotkey (v2)

**Style**:
```ahk
; Function names: PascalCase
MyFunction(param1, param2) {
    ; Local variables: camelCase
    localVar := "value"
    
    ; Globals: camelCase with global keyword
    global configFile
    
    ; Use explicit returns
    return result
}

; Constants: PascalCase or camelCase
DefaultTimeout := 5000
```

**Best Practices**:
- Always require AutoHotkey v2: `#Requires AutoHotkey v2.0`
- Use `Map()` for objects, `Array()` for lists
- No empty object literals `{}` - use `Map()`
- Use `IsObject()` for type checks
- Handle errors with `try`/`catch`
- Log important actions via `LogMessage()`

**Type Checking**:
```ahk
; ✓ Correct (v2 syntax)
if (variable is Integer)
if (obj is Map)
if (Type(value) = "Array")

; ✗ Wrong (v1 syntax)
if (variable is "Integer")  ; Don't quote types!
```

### PowerShell

**Style**:
```powershell
# Function names: Verb-Noun
function Get-DeviceInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$DevicePath,
        
        [Parameter(Mandatory=$false)]
        [int]$Timeout = 5000
    )
    
    # Use approved verbs: Get, Set, New, Remove, etc.
    # Variables: PascalCase or camelCase
    $deviceList = @()
    
    return $deviceList
}
```

**Best Practices**:
- Use `[CmdletBinding()]` for advanced functions
- Declare parameter types explicitly
- Use `$ErrorActionPreference = 'Stop'` for scripts
- Validate inputs
- Return objects, not formatted text
- Use `Write-Verbose` for debug output
- Wrap array returns with `@()` to prevent unwrapping

**Array Handling**:
```powershell
# ✓ Correct - prevents single-item unwrapping
function Get-Items {
    $items = @(Get-ChildItem)
    return @($items)  # Force array context
}

# ✗ Wrong - single item returns string, not array
function Get-Items {
    return Get-ChildItem  # May unwrap!
}
```

### Git Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting, no code change
- `refactor`: Code restructure, no behavior change
- `test`: Adding/updating tests
- `chore`: Build process, dependencies

**Examples**:
```
feat(profiles): add microphone management support
fix(hotkeys): prevent closure bug in hotkey handlers
docs(api): add API reference for all functions
test(config): add validation tests for config schema
```

## Testing

### Running Tests

```powershell
# Run all tests
pwsh -File tests/run-all-tests.ps1

# Run specific test file
Invoke-Pester -Path tests/SwitchProfile.Tests.ps1

# Run with verbose output
Invoke-Pester -Path tests/*.Tests.ps1 -Output Detailed

# Run AutoHotkey tests
& "C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" tests\monitor-toggle.Tests.ahk
```

### Writing PowerShell Tests

```powershell
# tests/MyFeature.Tests.ps1

# Suppress main script execution
$env:MONITOR_MANAGE_SUPPRESS_MAIN = '1'

# Source the script to test
$scriptDir = Split-Path -Parent $PSCommandPath
$scriptPath = Join-Path $scriptDir '..\scripts\my_script.ps1'
. $scriptPath

Describe "My Feature" {
    It "does something correctly" {
        # Arrange
        $input = "test"
        
        # Act
        $result = Do-Something -Input $input
        
        # Assert
        $result | Should -Be "expected"
    }
    
    It "handles null input" {
        { Do-Something -Input $null } | Should -Throw
    }
}
```

### Writing AutoHotkey Tests

```ahk
; tests/MyFeature.Tests.ahk
#Requires AutoHotkey v2.0
#Include ahk-test-framework.ahk

; Mock globals if needed
global testConfig := Map()

; Include functions to test
#Include ..\monitor-toggle.ahk

RunMyTests() {
    Describe("My Feature")
    
    It("does something")
    result := MyFunction("input")
    AssertEqual(result, "expected", "Should return expected value")
    
    It("handles empty input")
    result := MyFunction("")
    AssertEqual(result, "", "Should handle empty string")
}

if (A_LineFile == A_ScriptFullPath) {
    RunMyTests()
    PrintTestResults()
    ExitApp(GetTestExitCode())
}
```

### Test Coverage Requirements

- **New features**: Must include tests
- **Bug fixes**: Add regression test
- **Refactoring**: Existing tests must pass
- **Target coverage**: 80%+ for critical paths

### CI/CD

Tests run automatically on:
- Every push to `main` or `develop`
- Every pull request
- Manual workflow dispatch

See `.github/workflows/test.yml` for configuration.

## Debugging

### AutoHotkey Debugging

**Enable Detailed Logging**:
```ahk
; Add at top of function
LogMessage("Entering MyFunction with param: " param)

; Log intermediate values
LogMessage("Processing display: " displayName)

; Log exit
LogMessage("MyFunction returning: " result)
```

**Use MsgBox for Interactive Debugging**:
```ahk
MsgBox("Variable value: " variable)  ; Pause execution
```

**Check Log File**:
```powershell
Get-Content monitor-toggle.log -Tail 50 -Wait
```

**Syntax Checking**:
```powershell
# Verify script has no syntax errors
& "C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" /ErrorStdOut monitor-toggle.ahk
```

### PowerShell Debugging

**Use Write-Verbose**:
```powershell
Write-Verbose "Processing item: $item" -Verbose
```

**Enable Debugging**:
```powershell
$DebugPreference = 'Continue'
Write-Debug "Debug message"
```

**PowerShell ISE / VS Code**:
- Set breakpoints with `F9`
- Step through code with `F10` (over) / `F11` (into)
- Watch variables in debug pane

**Profile Performance**:
```powershell
pwsh -File tests/Profile-Performance.ps1 -Iterations 20
```

### Common Issues

**Issue**: Hotkeys not registering
- **Check**: Log file for "Failed to register" messages
- **Check**: Hotkey conflicts with other applications
- **Debug**: Test with simple hotkey first (e.g., `F12`)

**Issue**: Display not found
- **Check**: `devices_snapshot.json` for actual display names
- **Check**: Display is powered on and connected
- **Debug**: Run `export_devices.ps1` manually, inspect output

**Issue**: PowerShell script hangs
- **Check**: Module installation prompts (run elevated PS to install globally)
- **Debug**: Run script directly with `-Verbose` flag

## Common Tasks

### Adding a New Profile Field

1. **Update GetDefaultConfig()** in `monitor-toggle.ahk`:
   ```ahk
   profiles[profileKey] := Map(
       "activeDisplays", Array(),
       "disableDisplays", Array(),
       "audio", "",
       "microphone", "",
       "newField", ""  ; Add this
   )
   ```

2. **Update configure_profiles.ps1** to prompt for new field:
   ```powershell
   function Add-Profile {
       # ... existing code ...
       $newField = Read-Host "Enter new field value"
       $profile.newField = $newField
   }
   ```

3. **Update switch_profile.ps1** to apply new field:
   ```powershell
   $newField = $profile.newField
   if ($newField) {
       Apply-NewField -Value $newField
   }
   ```

4. **Update Validate-Config.ps1** to validate new field

5. **Add tests** for new field in relevant test files

6. **Update documentation** (README, CONFIGURATION.md)

### Adding a New Hotkey Action

1. **Define handler function** in `monitor-toggle.ahk`:
   ```ahk
   MyNewAction(descriptor := "") {
       LogMessage("MyNewAction triggered via " descriptor)
       ; Implementation here
   }
   ```

2. **Add default binding** in `GetDefaultConfig()`:
   ```ahk
   hotkeys := Map(
       ; ... existing ...
       "myNewAction", "Left Alt+Left Shift+F1"
   )
   ```

3. **Register in RegisterConfiguredHotkeys()**:
   ```ahk
   myActionDescriptor := GetMapValue(hotkeys, "myNewAction", "Left Alt+Left Shift+F1")
   RegisterHotkeyWithDescriptor("my-action", myActionDescriptor, MyNewAction)
   ```

4. **Document** in README hotkey table

### AutoHotkey v2 Syntax

Common v1 to v2 patterns (already applied in codebase):
- `ComObjCreate()` → `ComObject()`
- `ObjHasOwnProp(obj, key)` → `obj.HasOwnProp(key)`
- `is "Type"` → `is Type` (no quotes!)
- `{}` → `Map()`

### Performance Optimization

**Profile First**:
```powershell
pwsh -File tests/Profile-Performance.ps1 -Iterations 50
```

**Optimization Targets**:
1. **PowerShell startup** (~200-500ms)
   - Minimize script invocations
   - Cache results where possible
   
2. **Module imports** (~100-300ms first time)
   - Use lazy loading
   - Import once per session
   
3. **Device enumeration** (~50-200ms)
   - Cache in `devices_snapshot.json`
   - Only refresh when needed

**Measure Specific Functions**:
```powershell
Measure-Command {
    Get-DisplaySnapshot
}
```

## Contributing

### Workflow

1. **Fork** the repository
2. **Create feature branch**: `git checkout -b feat/my-feature`
3. **Make changes** following coding standards
4. **Add tests** for new functionality
5. **Run full test suite**: `pwsh -File tests/run-all-tests.ps1`
6. **Commit** with conventional commit message
7. **Push** to your fork
8. **Open Pull Request** to `main` branch

### Pull Request Guidelines

**PR Title**: Use conventional commit format
```
feat(profiles): add multi-monitor rotation support
```

**PR Description** should include:
- **What**: Brief description of changes
- **Why**: Motivation and context
- **How**: Implementation approach
- **Testing**: How you tested changes
- **Breaking Changes**: Any BC breaks
- **Related Issues**: Link to issues

**PR Checklist**:
- [ ] Tests added/updated
- [ ] All tests passing
- [ ] Documentation updated
- [ ] CHANGELOG.md updated (if applicable)
- [ ] No merge conflicts
- [ ] Follows coding standards

### Code Review Process

1. **Automated checks** must pass (CI/CD)
2. **Reviewer** assigned by maintainer
3. **Feedback** addressed via additional commits
4. **Approval** required before merge
5. **Squash merge** to main (clean history)

### Release Process

1. Update `CHANGELOG.md` with release notes
2. Update version numbers if applicable
3. Tag release: `git tag v1.2.0`
4. Push tag: `git push origin v1.2.0`
5. GitHub Actions creates release automatically

## Resources

### Documentation
- [AutoHotkey v2 Docs](https://www.autohotkey.com/docs/v2/)
- [PowerShell Docs](https://docs.microsoft.com/powershell/)
- [Pester Docs](https://pester.dev/docs/quick-start)
- [Conventional Commits](https://www.conventionalcommits.org/)

### Tools
- [AutoHotkey v2 Download](https://www.autohotkey.com/v2/)
- [VS Code](https://code.visualstudio.com/)
- [PowerShell 7](https://github.com/PowerShell/PowerShell)
- [Git](https://git-scm.com/)

### Community
- [GitHub Issues](https://github.com/yBCddsrs7Z/monitor-manage-vibed/issues)
- [GitHub Discussions](https://github.com/yBCddsrs7Z/monitor-manage-vibed/discussions)

## Troubleshooting Development Issues

### "Module not found" during tests
```powershell
# Install missing modules
Install-Module -Name DisplayConfig -Scope CurrentUser -Force
Install-Module -Name AudioDeviceCmdlets -Scope CurrentUser -Force
```

### AutoHotkey syntax errors
```powershell
# Check for v1 syntax
Select-String -Path *.ahk -Pattern 'ComObjCreate|ObjHasOwnProp\(|is "' -Context 0,2
```

### Tests failing with "Should -Be" errors
You're using Pester v3/v4 syntax but have v5 installed:
```powershell
# Check Pester version
Get-Module -ListAvailable Pester

# Install compatible version
Install-Module -Name Pester -RequiredVersion 4.10.1 -Force -SkipPublisherCheck
```

### Git line ending issues
```bash
# Configure Git to handle line endings
git config --global core.autocrlf true
```

## Getting Help

- **Bug reports**: Open GitHub issue with reproduction steps
- **Feature requests**: Open GitHub discussion
- **Questions**: Check README and documentation first
- **Security issues**: Email maintainers privately (see SECURITY.md)
