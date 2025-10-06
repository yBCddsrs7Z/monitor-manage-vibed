# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased] - 2025-10-06

### Changed
- Renamed "control groups" to "profiles" throughout entire codebase
- Updated all test files: `ConfigureControlGroups` → `ConfigureProfiles`, `SwitchControlGroup` → `SwitchProfile`
- Renamed scripts: `configure_control_groups.ps1` → `configure_profiles.ps1`, `switch_control_group.ps1` → `switch_profile.ps1`
- Updated config structure: `controlGroups` → `profiles`, `hotkeys.groups` → `hotkeys.profiles`
- Clarified that only 6 profiles (1-6) are created by default, with Alt+Shift+7 reserved for audio cycling

### Added
- 17 new integration and AHK tests (total: 71 tests passing)
- `CHANGELOG.md` for tracking changes
- Configuration reference documentation in README

### Fixed
- AHK test framework string concatenation syntax for v2
- PowerShell test environment variables for ValidateConfig tests
- `Optimize-ProfileKeys` function to properly skip non-numeric keys
- `Get-DeviceInventory` return value handling (3 values instead of 2)

## [1.0.0] - 2025-10-03 — Code Quality, Testing, CI/CD & Performance

### Added - CI/CD
- GitHub Actions workflow for automated testing (`.github/workflows/test.yml`)
  - Runs all 54 tests on every push and pull request
  - Validates config.json schema
  - Checks PowerShell scripts for syntax errors
  - Runs on Windows environment with PowerShell

### Added - Performance
- Performance profiling tool: `tests/Profile-Performance.ps1` for benchmarking
  - Profiles config validation, module loading, and display name normalization
  - Measures JSON parsing performance
  - Reports test suite execution time and average per test
  - Configurable iteration count for accuracy

### Fixed
- PowerShell syntax error: Fixed missing closing brace in `Write-Log` function and extra closing brace in `Get-DisplaysFromSnapshotFile` in `scripts/switch_profile.ps1`
- Global declaration: Removed redundant `global` keyword from `overlaySettingsCache` assignment in `ToggleProfileOverlay()` (line 426)
- Array conversion bug: Fixed single-item array unwrapping across all PowerShell scripts by wrapping array returns with `@()`:
  - `scripts/configure_profiles.ps1`: `Get-ProfileEntries`, `ConvertTo-DisplayReferenceArray`, `ConvertTo-NameArray`, `Get-UniqueDisplayReferences`, `Select-DisplayReferencesMultiple`, `Merge-DisplayReferences`
  - `scripts/switch_profile.ps1`: `ConvertTo-DisplayReferenceArray`, `Get-DisplaysFromSnapshotFile`, `Get-DisplaySnapshot`
  - `scripts/export_devices.ps1`: `Get-DisplaySnapshot`, `Get-AudioSnapshot`

### Added - Testing
- Comprehensive test suite: 54 passing tests across all PowerShell scripts:
  - `tests/ConfigureProfiles.Tests.ps1`: 21 tests covering device inventory, display reference merging, array handling, profile operations, and edge cases (null/empty inputs)
  - `tests/SwitchProfile.Tests.ps1`: 13 tests covering display resolution, normalization, snapshot parsing, array conversion, and edge cases (null, whitespace, special characters)
  - `tests/ExportDevices.Tests.ps1`: 4 tests covering property retrieval and JSON structure validation
  - `tests/ValidateConfig.Tests.ps1`: 7 tests covering config.json schema validation
  - `tests/ConfigureProfilesIntegration.Tests.ps1`: 9 tests covering array unwrapping, documentation filtering, and config operations
- Edge case coverage: Added 5 new tests for robustness:
  - Null and empty array handling in `Get-UniqueDisplayReferences`
  - Null, whitespace-only, and special-character-only inputs in `Get-NormalizedDisplayName`
- Test infrastructure: Created `tests/run-all-tests.ps1` for unified test execution with detailed reporting
- Test documentation: Added `tests/README.md` with usage instructions and coverage details
- Test artifacts: Updated `.gitignore` to exclude temporary test files
- Script testability: Made parameters optional in `switch_profile.ps1` and `Validate-Config.ps1` for automated testing

### Changed - Documentation
- README hotkey updates: Updated all hotkey references from `Alt+Shift` to `Left Alt+Left Shift` to match current defaults
- README clarity: Clarified hotkey actions (`Left Alt+Left Shift+9` opens configurator, `Left Alt+Left Shift+0` toggles overlay)
- Original attribution: Added proper attribution to Matt Drayton's original work

### Added - Enhancements
- Config validation: Added `scripts/Validate-Config.ps1` for validating config.json structure and values
  - Validates required top-level keys (profiles, hotkeys, overlay)
  - Validates profile structure (activeDisplays, disableDisplays, audio fields)
  - Validates overlay settings (opacity range, position values, font sizes)
  - Returns detailed errors and warnings
- Shared utilities: Created `scripts/Common.ps1` with reusable functions for future refactoring
  - Includes logging, module management, display name normalization, and property utilities
  - Ready for integration to eliminate code duplication across scripts
- Hotkey normalization: Enhanced descriptor parsing to handle `Left/Right` modifier prefixes with space normalization
- Error handling: Improved PowerShell module installation flow with better error messages

## [0.1.0] - 2025-09-28 — Initial Enhanced Fork

### Changed - Documentation
- README overhaul: Rewrote the top-level README to document automatic snapshot refresh, name-based display resolution, current hotkeys, setup workflow, troubleshooting tips, and startup guidance
- Hotkey documentation: Documented configurable hotkeys and overlay updates

### Changed - `monitor-toggle.ahk`
- Config defaults & normalization: `LoadConfig()` now auto-creates a populated `config.json` with default `hotkeys`, `overlay`, and empty `profiles`, merges legacy configs, and persists the normalized structure. The `hotkeys` block contains a `profiles` map of explicit bindings so profile hotkeys can be customized individually
- Configurable hotkeys: Hotkey bindings (profiles, enable-all, configurator, overlay) are read from `config.hotkeys`, registered dynamically, and displayed using `DescribeHotkey()`. Profile entries fall back to the new `hotkeys.profiles` map before using the legacy prefix
- Overlay customization: Overlay font, colors, opacity, position, and duration pull from `config.overlay`; the empty-state summary uses the configured hotkey labels
- Default profile count: Only profiles `1`-`6` are created by default, with `Alt+Shift+7` reserved for audio cycling and `Alt+Shift+8/9/0` for enable-all, configurator, and overlay toggle

### Changed - `switch_profile.ps1`
- Active profile marker: Update `scripts/active_profile` after successfully switching profiles
- Display & audio logging: Record resolved display names and audio device information for auditing
- Active monitor detection: Adds helper to fetch the currently-active profile
- Schema awareness: Reads profiles from the new top-level `profiles` map while ignoring `hotkeys` and `overlay` entries, preserving compatibility with legacy layouts
- Display toggling safeguards: Wrapped display operations in `Set-DisplayState` to warn when a named monitor is absent and to avoid redundant enable/disable calls
- Audio device validation: Confirmed target audio device exists before switching, logging warnings when it cannot be found
- Module-based control: Uses the `DisplayConfig` and `AudioDeviceCmdlets` modules directly, prompting for installation if they are missing
- Documentation: Added header comments outlining script flow and inline context where errors are surfaced

### Changed - `scripts/export_devices.ps1`
- Shared logging: Appends results and errors to `monitor-toggle.log` for traceability alongside the main script
- Hotkey/overlay preservation: Loads and saves top-level `hotkeys` and `overlay` blocks, merging with defaults and writing them back alongside `profiles`. Profile bindings are stored in a dedicated `hotkeys.profiles` map so edits persist without relying on prefixes
- Default schema: When `config.json` is missing or empty, the helper now writes the full default structure instead of an empty object
- Robust output: Ensures the destination directory exists, handles enumeration failures gracefully, and exits with an error code when necessary
- Documentation: Included script-level description and comments summarizing exported JSON fields
