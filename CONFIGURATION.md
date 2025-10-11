# Configuration Guide

Complete reference for configuring monitor-manage.

## Table of Contents
- [Configuration File Location](#configuration-file-location)
- [Configuration Structure](#configuration-structure)
- [Profiles](#profiles)
- [Hotkeys](#hotkeys)
- [Overlay](#overlay)
- [Settings](#settings)
- [Examples](#examples)
- [Validation](#validation)

## Configuration File Location

**File**: `config.json` in the monitor-manage directory

**Format**: JSON (JavaScript Object Notation)

**Encoding**: UTF-8

**Auto-generation**: Created automatically with defaults on first run if missing

**Editing Options**:
1. **Interactive configurator** (recommended): Press `Left Alt+Left Shift+9`
2. **Manual editing**: Edit `config.json` in any text editor
3. **Programmatic**: Use PowerShell to modify JSON

## Configuration Structure

### Top-Level Schema

```json
{
  "profiles": { ... },        // Profile definitions (required)
  "hotkeys": { ... },         // Hotkey bindings (required)
  "overlay": { ... },         // Overlay appearance (required)
  "settings": { ... },        // Global settings (optional)
  "_documentation": { ... }   // Inline help (ignored by code)
}
```

### Minimal Valid Config

```json
{
  "profiles": {},
  "hotkeys": {
    "profiles": {},
    "cycleAudio": "Left Alt+Left Shift+7",
    "enableAll": "Left Alt+Left Shift+8",
    "openConfigurator": "Left Alt+Left Shift+9",
    "toggleOverlay": "Left Alt+Left Shift+0"
  },
  "overlay": {
    "position": "top-left",
    "fontSize": 16
  }
}
```

## Profiles

Profiles define monitor and audio configurations that can be activated with hotkeys.

### Profile Schema

```json
{
  "profiles": {
    "1": {
      "activeDisplays": ["Display Name 1", "Display Name 2"],
      "disableDisplays": ["Display Name 3"],
      "audio": "Speakers (USB Audio)",
      "microphone": "Microphone (USB Audio)"
    }
  }
}
```

### Profile Keys

**Requirements**:
- Must be **numeric strings**: `"1"`, `"2"`, `"3"`, etc.
- Non-numeric keys will be automatically removed
- Gaps allowed but not recommended: `"1"`, `"3"`, `"7"` works but use configurator to renumber

**Defaults**: Profiles `"1"` through `"6"` created by default (empty)

**Adding More**: You can add `"7"`, `"8"`, etc. (but must configure hotkeys manually)

### activeDisplays

**Type**: Array of strings or single string

**Purpose**: Displays to **enable** when profile activates

**Format**: Exact display names from `devices_snapshot.json`

**Examples**:
```json
// Single display
"activeDisplays": "Dell U2720Q"

// Multiple displays
"activeDisplays": ["Dell U2720Q", "LG 27UK850", "Generic Display"]

// Empty (no displays enabled)
"activeDisplays": []
```

**Display Name Sources**:
1. Run `pwsh -File scripts/export_devices.ps1` to generate snapshot
2. Open `devices_snapshot.json` and copy display `name` values
3. Use configurator (`Left Alt+Left Shift+9`) for interactive selection

**Matching Rules**:
- Exact name match (case-sensitive preferred)
- Normalized name match (lowercase, no special chars)
- Display ID fallback (if name changed)

### disableDisplays

**Type**: Array of strings or single string

**Purpose**: Displays to **disable** when profile activates

**Format**: Same as `activeDisplays`

**Examples**:
```json
// Disable laptop screen when docked
"disableDisplays": "Integrated Display"

// Disable multiple
"disableDisplays": ["Laptop Screen", "Secondary Monitor"]
```

**Note**: You can list the same display in both `activeDisplays` and `disableDisplays` - the last action wins (usually disable).

### audio

**Type**: String

**Purpose**: Audio output device to set as default

**Format**: Exact device name from `devices_snapshot.json`

**Examples**:
```json
"audio": "Speakers (USB Audio)"
"audio": "Headphones (Realtek)"
"audio": "HDMI Audio"
```

**Finding Device Names**:
1. Run `pwsh -File scripts/export_devices.ps1`
2. Open `devices_snapshot.json`
3. Look in `audio.output` array for device `name` values
4. Or use configurator for selection menu

**Optional**: Leave empty `""` to skip audio switching

### microphone

**Type**: String

**Purpose**: Audio input device to set as default

**Format**: Exact device name from `devices_snapshot.json`

**Requirements**: Must enable microphone management in settings:
```json
{
  "settings": {
    "enableMicrophoneManagement": true
  }
}
```

**Examples**:
```json
"microphone": "Microphone (USB Audio)"
"microphone": "Built-in Microphone"
```

**Optional**: Leave empty or omit if not needed

### Profile Examples

**Example 1: Laptop Only**
```json
{
  "profiles": {
    "1": {
      "activeDisplays": ["Integrated Display"],
      "disableDisplays": [],
      "audio": "Speakers (Realtek)"
    }
  }
}
```

**Example 2: Docked Workstation**
```json
{
  "profiles": {
    "2": {
      "activeDisplays": ["Dell U2720Q", "LG 27UK850"],
      "disableDisplays": ["Integrated Display"],
      "audio": "Speakers (USB Audio)",
      "microphone": "USB Microphone"
    }
  }
}
```

**Example 3: Single External Monitor**
```json
{
  "profiles": {
    "3": {
      "activeDisplays": "HDMI Monitor",
      "disableDisplays": "Laptop Screen",
      "audio": "HDMI Audio"
    }
  }
}
```

## Hotkeys

Defines keyboard shortcuts for all actions.

### Hotkey Schema

```json
{
  "hotkeys": {
    "profiles": {
      "1": "Left Alt+Left Shift+1",
      "2": "Left Alt+Left Shift+2",
      "3": "Left Alt+Left Shift+3",
      "4": "Left Alt+Left Shift+4",
      "5": "Left Alt+Left Shift+5",
      "6": "Left Alt+Left Shift+6"
    },
    "cycleAudio": "Left Alt+Left Shift+7",
    "enableAll": "Left Alt+Left Shift+8",
    "openConfigurator": "Left Alt+Left Shift+9",
    "toggleOverlay": "Left Alt+Left Shift+0"
  }
}
```

### Hotkey Descriptor Format

**Syntax**: `[Modifier+]...[Modifier+]Key`

**Modifiers** (case-insensitive):
- `Alt`, `Left Alt`, `Right Alt`
- `Shift`, `Left Shift`, `Right Shift`
- `Ctrl`, `Control`, `Left Ctrl`, `Right Ctrl`
- `Win`, `Left Win`, `Right Win`

**Keys**:
- **Letters**: `A`-`Z` (case-insensitive)
- **Numbers**: `0`-`9`
- **Function Keys**: `F1`-`F24`
- **Special Keys**: `Enter`, `Esc`, `Space`, `Tab`, `Backspace`, `Delete`, `Insert`, `Home`, `End`, `PgUp`, `PgDn`, `Left`, `Right`, `Up`, `Down`

**Examples**:
```json
"Left Alt+Left Shift+1"    // Default style
"Ctrl+Alt+F1"              // Function key
"Win+Shift+M"              // Windows key
"Ctrl+Enter"               // Special key
"Right Alt+Space"          // Right-hand modifier
```

**Important Notes**:
- Use `+` to separate modifiers and keys
- Spaces around `+` are allowed: `Alt + Shift + 1`
- Left/Right modifiers must specify hand: `Left Alt`, not `LAlt`
- Descriptors are normalized on load for consistency

### Profile Hotkeys

**Location**: `hotkeys.profiles` object

**Format**: Map profile keys to descriptors

```json
{
  "hotkeys": {
    "profiles": {
      "1": "Left Alt+Left Shift+1",
      "2": "Ctrl+Alt+1",
      "7": "Win+F1"
    }
  }
}
```

**Requirements**:
- Profile key must match a profile in `profiles` section
- Descriptor must be valid
- No duplicate hotkeys (last one wins)

### Special Action Hotkeys

#### cycleAudio
Cycles through available audio output devices.

**Default**: `Left Alt+Left Shift+7`

**Example**:
```json
"cycleAudio": "Ctrl+Alt+A"
```

#### enableAll
Enables all connected displays (panic button).

**Default**: `Left Alt+Left Shift+8`

**Use Case**: When displays are confused, press this to re-enable everything

**Example**:
```json
"enableAll": "Ctrl+Alt+E"
```

#### openConfigurator
Opens interactive profile editor.

**Default**: `Left Alt+Left Shift+9`

**Example**:
```json
"openConfigurator": "Ctrl+Alt+C"
```

#### toggleOverlay
Shows/hides profile summary overlay.

**Default**: `Left Alt+Left Shift+0`

**Example**:
```json
"toggleOverlay": "Ctrl+Alt+O"
```

### Hotkey Conflicts

**Avoid conflicts with**:
- Windows system shortcuts (`Win+D`, `Win+L`, etc.)
- Common application shortcuts (`Ctrl+C`, `Ctrl+V`, etc.)
- Other running AutoHotkey scripts

**Testing**: After changing hotkeys, test in a text editor to ensure they're not captured by other apps

## Overlay

Controls the appearance and behavior of the profile summary overlay.

### Overlay Schema

```json
{
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
  }
}
```

### Font Settings

#### fontName
**Type**: String

**Purpose**: Font family for overlay text

**Default**: `"Segoe UI"`

**Common Values**:
- `"Segoe UI"` - Modern, clean (recommended)
- `"Consolas"` - Monospace
- `"Arial"` - Classic sans-serif
- `"Courier New"` - Monospace serif

**Requirements**: Font must be installed on system

#### fontSize
**Type**: Integer

**Purpose**: Font size in points

**Default**: `16`

**Range**: `8` - `72` (recommended: `12` - `24`)

**Example**:
```json
"fontSize": 20  // Larger text
```

#### fontBold
**Type**: Boolean

**Purpose**: Make text bold

**Default**: `true`

**Values**: `true` or `false`

**Example**:
```json
"fontBold": false  // Normal weight
```

### Color Settings

#### textColor
**Type**: String

**Purpose**: Text color

**Default**: `"Blue"`

**Formats**:
1. **Named colors**: `"Blue"`, `"White"`, `"Red"`, `"Green"`, `"Yellow"`, `"Silver"`, `"Gray"`, `"Black"`
2. **Hex colors**: `"#0000FF"`, `"#FFFFFF"`, `"#FF0000"`
3. **RGB**: `"0x0000FF"`

**Examples**:
```json
"textColor": "White"      // Named
"textColor": "#00FF00"    // Hex green
"textColor": "0xFFFF00"   // RGB yellow
```

#### backgroundColor
**Type**: String

**Purpose**: Background color of overlay window

**Default**: `"Black"`

**Format**: Same as textColor

**Examples**:
```json
"backgroundColor": "#202020"  // Dark gray
"backgroundColor": "Navy"      // Dark blue
```

### Position Settings

#### position
**Type**: String

**Purpose**: Where to display overlay on screen

**Default**: `"top-left"`

**Valid Values**:
- `"top-left"` - Upper left corner
- `"top-right"` - Upper right corner
- `"top-center"` - Top center
- `"bottom-left"` - Lower left corner
- `"bottom-right"` - Lower right corner
- `"bottom-center"` - Bottom center
- `"center"` - Screen center

**Example**:
```json
"position": "bottom-right"
```

#### marginX
**Type**: Integer

**Purpose**: Horizontal offset from screen edge (pixels)

**Default**: `10`

**Range**: `0` - `500`

**Example**:
```json
"marginX": 50  // 50 pixels from edge
```

#### marginY
**Type**: Integer

**Purpose**: Vertical offset from screen edge (pixels)

**Default**: `10`

**Range**: `0` - `500`

**Example**:
```json
"marginY": 100  // 100 pixels from edge
```

### Behavior Settings

#### opacity
**Type**: Integer

**Purpose**: Window transparency level

**Default**: `220`

**Range**: `0` - `255`
- `0` = Fully transparent (invisible)
- `255` = Fully opaque (solid)
- `220` = Slightly transparent (recommended)

**Example**:
```json
"opacity": 180  // More transparent
```

#### durationMs
**Type**: Integer

**Purpose**: How long profile overlay stays visible (milliseconds)

**Default**: `10000` (10 seconds)

**Range**: `1000` - `60000` (1-60 seconds)

**Special**: `0` = Never auto-hide (must close manually)

**Example**:
```json
"durationMs": 5000  // 5 seconds
```

### Notification Settings

Notifications are temporary messages (e.g., "Activating profile 1...") that appear during actions.

#### notificationPosition
**Type**: String

**Purpose**: Where notifications appear

**Default**: `"top-center"`

**Valid Values**: Same as `position`

**Example**:
```json
"notificationPosition": "bottom-center"
```

#### notificationDuration
**Type**: Integer

**Purpose**: How long notifications stay visible (milliseconds)

**Default**: `5000` (5 seconds)

**Range**: `1000` - `30000`

**Example**:
```json
"notificationDuration": 3000  // 3 seconds
```

### Overlay Examples

**Example 1: Minimalist Dark Theme**
```json
{
  "overlay": {
    "fontName": "Consolas",
    "fontSize": 14,
    "fontBold": false,
    "textColor": "#00FF00",
    "backgroundColor": "#000000",
    "opacity": 200,
    "position": "top-right",
    "marginX": 20,
    "marginY": 20,
    "durationMs": 8000
  }
}
```

**Example 2: High Contrast**
```json
{
  "overlay": {
    "fontSize": 20,
    "fontBold": true,
    "textColor": "Yellow",
    "backgroundColor": "Black",
    "opacity": 255,
    "position": "center"
  }
}
```

## Settings

Global application settings.

### Settings Schema

```json
{
  "settings": {
    "enableMicrophoneManagement": false
  }
}
```

### enableMicrophoneManagement

**Type**: Boolean

**Purpose**: Enable microphone switching in profiles

**Default**: `false`

**When enabled**:
- Profile editor shows microphone selection
- Profile overlay shows microphone info
- `switch_profile.ps1` switches default microphone

**When disabled**:
- Microphone field hidden in configurator
- Microphone switching skipped

**Example**:
```json
{
  "settings": {
    "enableMicrophoneManagement": true
  }
}
```

## Examples

### Complete Example Config

```json
{
  "_documentation": {
    "note": "This is a sample configuration"
  },
  "profiles": {
    "1": {
      "activeDisplays": ["Built-in Display"],
      "disableDisplays": [],
      "audio": "Internal Speakers"
    },
    "2": {
      "activeDisplays": ["Dell U2720Q", "LG 27UK850"],
      "disableDisplays": ["Built-in Display"],
      "audio": "USB Audio",
      "microphone": "USB Microphone"
    },
    "3": {
      "activeDisplays": "HDMI Monitor",
      "disableDisplays": "Laptop Screen",
      "audio": "HDMI Audio"
    }
  },
  "hotkeys": {
    "profiles": {
      "1": "Left Alt+Left Shift+1",
      "2": "Left Alt+Left Shift+2",
      "3": "Left Alt+Left Shift+3"
    },
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
    "enableMicrophoneManagement": true
  }
}
```

## Validation

### Manual Validation

```powershell
pwsh -File scripts/Validate-Config.ps1 -ConfigPath config.json
```

**Exit Codes**:
- `0` = Valid
- `1` = Invalid (errors printed to console)

### Automatic Validation

Config is validated automatically:
1. On script startup (`monitor-toggle.ahk`)
2. After configurator saves changes
3. In CI/CD pipeline

### Common Validation Errors

**Error**: "Required key missing: profiles"
- **Fix**: Add empty `"profiles": {}` to config

**Error**: "Profile key '1a' is not numeric"
- **Fix**: Change to numeric key like `"1"` or `"10"`

**Error**: "opacity must be 0-255"
- **Fix**: Set overlay.opacity within range

**Error**: "position 'top-middle' invalid"
- **Fix**: Use valid position (see overlay.position values)

**Error**: "Hotkey descriptor invalid"
- **Fix**: Use proper format: `"Modifier+Key"`

### Validation Rules

**Profiles**:
- Keys must be numeric strings
- activeDisplays/disableDisplays must be strings or arrays
- audio/microphone must be strings

**Hotkeys**:
- Must contain profiles, cycleAudio, enableAll, openConfigurator, toggleOverlay
- Descriptors must parse to valid AHK syntax

**Overlay**:
- fontSize: 1-100
- opacity: 0-255
- position: one of valid values
- durationMs: 0-60000

## Configuration Best Practices

1. **Use Configurator**: Prefer `Left Alt+Left Shift+9` over manual editing
2. **Backup**: Copy `config.json` before major changes
3. **Validate**: Run validation script after manual edits
4. **Test**: Test each profile after configuration changes
5. **Descriptive**: Use `_documentation` fields for notes (ignored by code)
6. **Consistent**: Use consistent naming for displays across profiles
7. **Minimal**: Don't include default values unless you want to customize them

## See Also
- [README.md](README.md) - General usage
- [API_REFERENCE.md](API_REFERENCE.md) - Function documentation
- [ARCHITECTURE.md](ARCHITECTURE.md) - System design
