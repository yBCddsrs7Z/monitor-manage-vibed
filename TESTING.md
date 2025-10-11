# Testing Guide

Comprehensive guide to testing monitor-manage.

## Table of Contents
- [Overview](#overview)
- [Running Tests](#running-tests)
- [Test Suite Structure](#test-suite-structure)
- [Writing Tests](#writing-tests)
- [Continuous Integration](#continuous-integration)
- [Performance Testing](#performance-testing)

## Overview

Monitor-manage has comprehensive test coverage across both **PowerShell** and **AutoHotkey** components.

**Test Statistics**:
- **PowerShell Tests**: 54/54 passing ✅
- **AutoHotkey Tests**: NEW ✅
- **Total Coverage**: Core functionality, edge cases, integration scenarios

**Testing Frameworks**:
- **PowerShell**: Pester (v3/v4 compatible)
- **AutoHotkey**: Custom test framework (`ahk-test-framework.ahk`)

## Running Tests

### Quick Start

```powershell
# Run all tests (recommended)
pwsh -File tests/run-all-tests.ps1
```

**Expected Output**:
```
========================================
Running ConfigureProfiles.Tests.ps1
========================================
Describing Get-DeviceInventory
 [+] handles empty config without errors 45ms
 [+] returns three arrays 67ms
 ...

========================================
OVERALL TEST RESULTS
========================================
Total Passed:  54
Total Failed:  0
Total Skipped: 0
========================================
```

### Run Specific Test Suites

```powershell
# PowerShell tests only
Invoke-Pester -Path tests/ConfigureProfiles.Tests.ps1
Invoke-Pester -Path tests/SwitchProfile.Tests.ps1
Invoke-Pester -Path tests/ExportDevices.Tests.ps1
Invoke-Pester -Path tests/ValidateConfig.Tests.ps1
Invoke-Pester -Path tests/ConfigureProfilesIntegration.Tests.ps1

# AutoHotkey tests only
& "C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" tests\monitor-toggle.Tests.ahk
```

### Run with Detailed Output

```powershell
# Pester detailed output
Invoke-Pester -Path tests/*.Tests.ps1 -Output Detailed

# Show all test names
Invoke-Pester -Path tests/*.Tests.ps1 -Output Diagnostic
```

### Run Tests in CI/CD Mode

```powershell
# Exit with non-zero code on failure
pwsh -File tests/run-all-tests.ps1
exit $LASTEXITCODE
```

## Test Suite Structure

### PowerShell Tests

#### ConfigureProfiles.Tests.ps1 (21 tests)

Tests for the interactive profile configurator.

**Functions Tested**:
- `Get-DeviceInventory` - Device enumeration
- `Merge-DisplayReferences` - Display merging logic
- `ConvertTo-DisplayReferenceArray` - Array conversion
- `Get-ProfileEntries` - Profile enumeration
- `ConvertTo-NameArray` - Name extraction
- `Get-UniqueDisplayReferences` - Deduplication

**Test Categories**:
1. **Device Inventory** (3 tests)
   - Empty config handling
   - Array structure validation
   - Error handling

2. **Display Reference Merging** (4 tests)
   - Available display integration
   - ID preservation
   - Multiple display handling
   - Empty input handling

3. **Array Conversion** (5 tests)
   - Single item handling (prevents unwrapping)
   - Multiple items
   - String input
   - Object with name property
   - Null input

4. **Profile Operations** (4 tests)
   - Profile enumeration
   - Numeric key filtering
   - Empty profile handling
   - Documentation key filtering

5. **Name Extraction** (3 tests)
   - Name array conversion
   - Object handling
   - Empty/null handling

6. **Deduplication** (2 tests)
   - Unique reference extraction
   - Edge cases (null, empty)

#### SwitchProfile.Tests.ps1 (13 tests)

Tests for profile switching logic.

**Functions Tested**:
- `Resolve-DisplayIdentifiers` - Name-to-ID resolution
- `ConvertTo-DisplayReferenceArray` - Array handling
- `Get-DisplaysFromSnapshotFile` - Snapshot parsing
- `Get-NormalizedDisplayName` - Name normalization

**Test Categories**:
1. **Display Resolution** (3 tests)
   - Name matching (exact)
   - Normalized name matching
   - ID matching

2. **Array Conversion** (4 tests)
   - Single item (anti-unwrapping)
   - Multiple items
   - Empty input
   - Null input

3. **Snapshot Parsing** (3 tests)
   - Valid snapshot
   - Missing displays key
   - Empty file

4. **Name Normalization** (3 tests)
   - Whitespace handling
   - Special character removal
   - Edge cases (null, empty, whitespace-only)

#### ExportDevices.Tests.ps1 (4 tests)

Tests for device snapshot generation.

**Functions Tested**:
- `Get-PropertyValue` - Safe property access
- Integration tests for export process

**Test Categories**:
1. **Property Retrieval** (2 tests)
   - Property exists
   - Property missing (default value)

2. **Integration** (2 tests)
   - Display snapshot structure
   - Audio snapshot structure

#### ValidateConfig.Tests.ps1 (7 tests)

Tests for configuration validation.

**Functions Tested**:
- `Test-ConfigStructure` - Complete validation

**Test Categories**:
1. **File Validation** (2 tests)
   - Non-existent file
   - Invalid JSON

2. **Structure Validation** (2 tests)
   - Missing required keys
   - Valid minimal config

3. **Profile Validation** (1 test)
   - Invalid profile structure

4. **Overlay Validation** (2 tests)
   - Invalid opacity range
   - Invalid position value

#### ConfigureProfilesIntegration.Tests.ps1 (9 tests)

Integration tests for edge cases.

**Test Categories**:
1. **Array Unwrapping Prevention** (3 tests)
   - Single profile scenario
   - Get-ProfileEntries
   - ConvertTo-NameArray

2. **Documentation Filtering** (3 tests)
   - Filtered from profiles
   - Filtered from hotkeys
   - Filtered from all operations

3. **Configuration Operations** (3 tests)
   - Loading with documentation keys
   - Saving without documentation keys
   - Empty config handling

### AutoHotkey Tests

#### monitor-toggle.Tests.ahk

Tests for AutoHotkey components.

**Test Suites**:

1. **Config Loading** (3 tests)
   - Load config.json successfully
   - Return profiles as Map
   - Find highest config index

2. **Hotkey Registration** (2 tests)
   - Register correct number of hotkeys
   - Create unique handlers (closure fix)

3. **Closure Bug Fix** (1 test)
   - Verify profile key captured by value

4. **Helper Functions** (3 tests)
   - GetMapValue default handling
   - GetMapValue actual value
   - ConvertDescriptorToAhkHotkey conversion

**Total**: 9 tests

## Writing Tests

### PowerShell Test Template

```powershell
# tests/MyFeature.Tests.ps1

# Prevent main script execution
$env:MONITOR_MANAGE_SUPPRESS_MAIN = '1'

# Source script to test
$scriptDir = Split-Path -Parent $PSCommandPath
$scriptPath = Join-Path $scriptDir '..\scripts\my_script.ps1'
. $scriptPath

Describe "MyFeature" {
    Context "When input is valid" {
        It "should return expected result" {
            # Arrange
            $input = "test-value"
            
            # Act
            $result = Invoke-MyFunction -Input $input
            
            # Assert
            $result | Should -Be "expected-value"
        }
    }
    
    Context "When input is invalid" {
        It "should throw error" {
            { Invoke-MyFunction -Input $null } | Should -Throw
        }
        
        It "should handle empty string" {
            $result = Invoke-MyFunction -Input ""
            $result | Should -Be ""
        }
    }
}
```

### AutoHotkey Test Template

```ahk
; tests/MyFeature.Tests.ahk
#Requires AutoHotkey v2.0
#Include ahk-test-framework.ahk

; Include functions to test
#Include ..\monitor-toggle.ahk

RunMyTests() {
    Describe("MyFeature")
    
    It("should do something")
    result := MyFunction("input")
    AssertEqual(result, "expected", "Should return expected value")
    
    It("should handle empty input")
    result := MyFunction("")
    AssertTrue(result = "", "Should handle empty string")
    
    It("should handle null")
    result := MyFunction(unset)
    AssertTrue(!IsSet(result) || result = "", "Should handle unset variable")
}

if (A_LineFile == A_ScriptFullPath) {
    RunMyTests()
    PrintTestResults()
    ExitApp(GetTestExitCode())
}
```

### Testing Best Practices

#### 1. Test Isolation
Each test should be independent and not rely on other tests.

```powershell
# ✓ Good - isolated
It "creates new profile" {
    $profiles = @{}
    $profiles["1"] = @{activeDisplays = @()}
    $profiles.Count | Should -Be 1
}

# ✗ Bad - depends on previous test
It "edits profile" {
    # Assumes profile "1" exists from previous test
    $profiles["1"].activeDisplays = @("Monitor")
}
```

#### 2. Arrange-Act-Assert Pattern

```powershell
It "normalizes display name" {
    # Arrange
    $inputName = "  Dell  U2720Q  "
    
    # Act
    $result = Get-NormalizedDisplayName -Name $inputName
    
    # Assert
    $result | Should -Be "dell u2720q"
}
```

#### 3. Test Edge Cases

Always test:
- Null input
- Empty input
- Single item (for arrays)
- Multiple items
- Invalid input

```powershell
It "handles null input" {
    $result = Get-DisplayNames -Spec $null
    $result | Should -BeOfType 'Array'
    $result.Count | Should -Be 0
}
```

#### 4. Prevent Array Unwrapping

PowerShell unwraps single-item arrays in some contexts. Always force array context:

```powershell
# ✓ Correct
function Get-Items {
    $items = @(Get-ChildItem)
    return @($items)  # Force array
}

# Test it
It "returns array even with single item" {
    $result = @(Get-Items)
    $result | Should -BeOfType 'Array'
}
```

#### 5. Use Descriptive Test Names

```powershell
# ✓ Good - describes what and why
It "returns empty array when input is null" { }
It "normalizes display name by removing special characters" { }

# ✗ Bad - vague
It "works" { }
It "test1" { }
```

### Pester Assertions

Common assertions in Pester v3/v4:

```powershell
# Equality
$result | Should -Be $expected
$result | Should -Not -Be $unexpected

# Type checking
$result | Should -BeOfType 'String'
$result | Should -BeOfType 'Array'

# Null checking
$result | Should -Not -BeNullOrEmpty
$result | Should -BeNullOrEmpty

# Exception testing
{ Invoke-Function } | Should -Throw
{ Invoke-Function } | Should -Not -Throw

# Array/Collection
$array.Count | Should -Be 3
$array | Should -Contain "item"

# Boolean
$result | Should -BeTrue
$result | Should -BeFalse

# Pattern matching
$result | Should -Match 'pattern'
```

### AutoHotkey Assertions

Available assertions in `ahk-test-framework.ahk`:

```ahk
; Equality
AssertEqual(actual, expected, message)

; Boolean
AssertTrue(condition, message)
AssertFalse(condition, message)

; Object checking
AssertIsObject(value, message)

; Custom assertion
if (condition) {
    PassTest(message)
} else {
    FailTest(message)
}
```

## Continuous Integration

### GitHub Actions Workflow

Tests run automatically on:
- Every push to `main` or `develop` branches
- Every pull request
- Manual workflow dispatch

**Workflow File**: `.github/workflows/test.yml`

**Jobs**:
1. **PowerShell Tests**
   - Install Pester
   - Install required modules
   - Run all PowerShell tests
   - Report results

2. **Config Validation**
   - Validate config.json schema
   - Check for syntax errors

3. **AutoHotkey Tests** (if available)
   - Detect AutoHotkey installation
   - Run AHK test suite
   - Report results

### Running Tests Locally (CI Mode)

```powershell
# Simulate CI environment
$env:CI = 'true'
$env:MONITOR_MANAGE_SUPPRESS_MAIN = '1'
$env:MONITOR_MANAGE_SUPPRESS_SWITCH = '1'
$env:MONITOR_MANAGE_VALIDATION_TEST_MODE = '1'

pwsh -File tests/run-all-tests.ps1
$exitCode = $LASTEXITCODE

# Cleanup
Remove-Item Env:CI -ErrorAction SilentlyContinue
Remove-Item Env:MONITOR_MANAGE_SUPPRESS_MAIN -ErrorAction SilentlyContinue
Remove-Item Env:MONITOR_MANAGE_SUPPRESS_SWITCH -ErrorAction SilentlyContinue
Remove-Item Env:MONITOR_MANAGE_VALIDATION_TEST_MODE -ErrorAction SilentlyContinue

exit $exitCode
```

### Test Results Output

Tests produce:
1. **Console Output**: Real-time test results
2. **Exit Code**: 0 = pass, 1 = fail
3. **XML Report** (optional): For CI integration

Generate XML report:
```powershell
Invoke-Pester -Path tests/*.Tests.ps1 -OutputFile test-results.xml -OutputFormat NUnitXml
```

## Performance Testing

### Profile Performance

Measure script execution performance:

```powershell
pwsh -File tests/Profile-Performance.ps1 -Iterations 20
```

**Output**:
```
Performance Profiling Results
========================================
Config Validation:        45.2ms avg
Module Loading:          123.4ms avg
Display Normalization:    2.3ms avg
JSON Parsing:            15.6ms avg
Test Suite:              1234ms total (24.7ms per test)
========================================
```

### Custom Performance Testing

```powershell
# Measure specific function
Measure-Command {
    Get-DeviceInventory
} | Select-Object TotalMilliseconds

# Average over multiple runs
$times = 1..10 | ForEach-Object {
    (Measure-Command {
        Get-DeviceInventory
    }).TotalMilliseconds
}
$average = ($times | Measure-Object -Average).Average
Write-Host "Average: $average ms"
```

### Performance Benchmarks

Target performance metrics:

| Operation | Target | Typical | Acceptable |
|-----------|--------|---------|------------|
| Config Load | <100ms | 50ms | 200ms |
| Profile Switch | <2s | 1s | 3s |
| Device Export | <500ms | 300ms | 1s |
| Config Validation | <200ms | 100ms | 500ms |
| Test Suite | <5s | 3s | 10s |

## Test Coverage

### Coverage by Component

| Component | Tests | Coverage |
|-----------|-------|----------|
| configure_profiles.ps1 | 30 | 85% |
| switch_profile.ps1 | 13 | 80% |
| export_devices.ps1 | 4 | 75% |
| Validate-Config.ps1 | 7 | 90% |
| monitor-toggle.ahk | 9 | 70% |

### Untested Areas

Known gaps in test coverage:
1. **UI Interactions**: Menu selections in configure_profiles.ps1
2. **Hardware Interactions**: Actual display/audio switching
3. **Error Recovery**: Some edge case error paths
4. **Integration**: End-to-end user workflows

### Adding Coverage

To add test coverage:
1. Identify untested function
2. Write unit test following template
3. Test edge cases
4. Update coverage metrics
5. Add integration test if needed

## Debugging Failed Tests

### PowerShell Test Failures

**Enable Verbose Output**:
```powershell
Invoke-Pester -Path tests/MyTest.Tests.ps1 -Output Detailed -Verbose
```

**Isolate Single Test**:
```powershell
Invoke-Pester -Path tests/MyTest.Tests.ps1 -TestName "specific test name"
```

**Debug in PowerShell ISE**:
1. Open test file in PowerShell ISE
2. Set breakpoint (F9)
3. Run test
4. Step through (F10/F11)

### AutoHotkey Test Failures

**Add Debug Output**:
```ahk
It("my test")
MsgBox("Debug: result = " result)  ; Pause and show value
AssertEqual(result, expected, "Test failed")
```

**View Test Results**:
```ahk
PrintTestResults()  ; Shows summary at end
```

## Test Maintenance

### When to Update Tests

Update tests when:
1. **Adding features**: Write tests first (TDD)
2. **Fixing bugs**: Add regression test
3. **Refactoring**: Ensure existing tests pass
4. **Changing behavior**: Update test expectations

### Test Hygiene

Regular maintenance:
1. Remove obsolete tests
2. Update test data
3. Fix flaky tests (inconsistent pass/fail)
4. Improve test performance
5. Enhance error messages

### Test Review Checklist

Before merging test changes:
- [ ] All tests pass locally
- [ ] Tests are isolated (no dependencies)
- [ ] Edge cases covered
- [ ] Error messages are descriptive
- [ ] No hardcoded paths or values
- [ ] Documentation updated
- [ ] Performance acceptable

## Resources

### Pester Documentation
- [Pester Docs](https://pester.dev/docs/quick-start)
- [Pester GitHub](https://github.com/pester/Pester)

### AutoHotkey Testing
- [AutoHotkey Docs](https://www.autohotkey.com/docs/v2/)
- Custom framework: `tests/ahk-test-framework.ahk`

### CI/CD
- [GitHub Actions](https://docs.github.com/en/actions)
- Workflow file: `.github/workflows/test.yml`

## See Also
- [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) - Development workflow
- [API_REFERENCE.md](API_REFERENCE.md) - Function documentation
- [ARCHITECTURE.md](ARCHITECTURE.md) - System design
