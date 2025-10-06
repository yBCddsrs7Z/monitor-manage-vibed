param()

$ErrorActionPreference = 'Stop'
$script:SelectionCancelled = $false

$scriptDir = Split-Path -Parent $PSCommandPath
$repoRoot = Resolve-Path (Join-Path $scriptDir '..')
$configPath = Join-Path $repoRoot 'config.json'
$snapshotPath = Join-Path $repoRoot 'devices_snapshot.json'
$exportScript = Join-Path $scriptDir 'export_devices.ps1'
$script:HotkeySettings = $null
$script:OverlaySettings = $null
$script:Settings = $null

function Get-DefaultHotkeys {
    $profiles = [ordered]@{}
    foreach ($index in 1..6) {
        $key = [string]$index
        $profiles[$key] = 'Left Alt+Left Shift+' + $key
    }
    return [ordered]@{
        profiles         = $profiles
        cycleAudio       = 'Left Alt+Left Shift+7'
        enableAll        = 'Left Alt+Left Shift+8'
        openConfigurator = 'Left Alt+Left Shift+9'
        toggleOverlay    = 'Left Alt+Left Shift+0'
    }
}

function Get-DefaultOverlay {
    return [ordered]@{
        fontName              = 'Segoe UI'
        fontSize              = 16
        fontBold              = $true
        textColor             = 'Blue'
        backgroundColor       = 'Black'
        opacity               = 220
        position              = 'top-left'
        marginX               = 10
        marginY               = 10
        durationMs            = 10000
        notificationPosition  = 'top-center'
        notificationDuration  = 5000
    }
}

function Get-DefaultSettings {
    return [ordered]@{
        enableMicrophoneManagement = $false
    }
}

function ConvertTo-OrderedMap {
    param($Value)

    $result = [ordered]@{}
    if ($null -eq $Value) {
        return $result
    }

    if ($Value -is [System.Collections.IDictionary]) {
        foreach ($key in $Value.Keys) {
            $result[$key] = $Value[$key]
        }
        return $result
    }

    foreach ($property in $Value.PSObject.Properties) {
        $result[$property.Name] = $property.Value
    }

    return $result
}

function Merge-OrderedDefaults {
    param($Current, $Defaults)

    if (-not $Current) {
        $Current = @{}
    }

    $merged = [ordered]@{}
    foreach ($key in $Defaults.Keys) {
        if ($Current.Contains($key)) {
            $merged[$key] = $Current[$key]
        } else {
            $merged[$key] = $Defaults[$key]
        }
    }

    foreach ($key in $Current.Keys) {
        if (-not $merged.Contains($key)) {
            $merged[$key] = $Current[$key]
        }
    }

    return $merged
}

function Convert-AhkHotkeyToDescriptor {
    param([string]$Hotkey)

    if ([string]::IsNullOrWhiteSpace($Hotkey)) {
        return ''
    }

    $modifiers = New-Object System.Collections.Generic.List[string]
    $key = ''
    $sidePrefix = ''

    for ($i = 0; $i -lt $Hotkey.Length; $i++) {
        $char = $Hotkey[$i]
        switch ($char) {
            '<' { $sidePrefix = 'Left '; continue }
            '>' { $sidePrefix = 'Right '; continue }
            '!' { $modifiers.Add($sidePrefix + 'Alt'); $sidePrefix = ''; continue }
            '+' { $modifiers.Add($sidePrefix + 'Shift'); $sidePrefix = ''; continue }
            '^' { $modifiers.Add($sidePrefix + 'Ctrl'); $sidePrefix = ''; continue }
            '#' { $modifiers.Add($sidePrefix + 'Win'); $sidePrefix = ''; continue }
            default {
                $key = $Hotkey.Substring($i)
                break
            }
        }
        $sidePrefix = ''
    }

    $descriptor = if ($modifiers.Count -gt 0) { ($modifiers -join '+') } else { '' }

    if ($key) {
        if ($descriptor) {
            return "$descriptor+$key"
        }
        return $key
    }

    return $descriptor
}

function Set-HotkeyDescriptorNormalized {
    param([string]$Descriptor)

    if ([string]::IsNullOrWhiteSpace($Descriptor)) {
        return ''
    }

    if ($Descriptor -match '^[!#^+<>]') {
        $Descriptor = Convert-AhkHotkeyToDescriptor $Descriptor
    }

    $tokens = @()
    foreach ($token in ($Descriptor -split '\+')) {
        $trimmed = $token.Trim()
        if (-not $trimmed) { continue }

        if ($trimmed.Length -eq 1 -or $trimmed -match '^[0-9]+$') {
            $tokens += $trimmed.ToUpperInvariant()
            continue
        }

        if ($trimmed -match '^(Left|Right)\s+') {
            $direction, $remainder = $trimmed -split '\s+', 2
            $normalizedDirection = $direction.Substring(0,1).ToUpperInvariant() + $direction.Substring(1).ToLowerInvariant()
            if ([string]::IsNullOrWhiteSpace($remainder)) {
                $tokens += $normalizedDirection
            } else {
                $tokens += ("{0} {1}" -f $normalizedDirection, (Get-Culture).TextInfo.ToTitleCase($remainder.ToLowerInvariant()))
            }
            continue
        }

        if ($trimmed -match '^f[0-9]{1,2}$') {
            $tokens += $trimmed.ToUpperInvariant()
            continue
        }

        $tokens += (Get-Culture).TextInfo.ToTitleCase($trimmed.ToLowerInvariant())
    }

    return ($tokens -join '+')
}

function Set-HotkeyProfileDefaults {
    param([Parameter(Mandatory = $true)]$Hotkeys)

    $defaults = Get-DefaultHotkeys
    $current = ConvertTo-OrderedMap $Hotkeys

    if (-not ($current.Contains('profiles') -and ($current['profiles'] -is [System.Collections.IDictionary] -or $current['profiles'] -is [System.Management.Automation.PSObject]))) {
        $current['profiles'] = [ordered]@{}
    }

    $profileMap = ConvertTo-OrderedMap $current['profiles']

    foreach ($key in @($profileMap.Keys)) {
        # Skip documentation and metadata keys (starting with _)
        if ($key -match '^_') {
            $profileMap.Remove($key)
            continue
        }
        $profileMap[$key] = Set-HotkeyDescriptorNormalized $profileMap[$key]
    }

    if ($current.Contains('profilePrefix') -and $current['profilePrefix']) {
        $prefix = $current['profilePrefix']
        foreach ($index in 1..6) {
            $key = [string]$index
            if (-not $profileMap.Contains($key) -or -not $profileMap[$key]) {
                $profileMap[$key] = Set-HotkeyDescriptorNormalized ($prefix + $key)
            }
        }
        $current.Remove('profilePrefix') | Out-Null
    }

    foreach ($index in 1..6) {
        $key = [string]$index
        if (-not $profileMap.Contains($key) -or -not $profileMap[$key]) {
            $profileMap[$key] = $defaults['profiles'][$key]
        }
    }

    $current['profiles'] = $profileMap

    foreach ($prop in $defaults.Keys) {
        if ($prop -eq 'profiles') { continue }

        $normalized = Set-HotkeyDescriptorNormalized ($current[$prop])
        if ($normalized) {
            $current[$prop] = $normalized
        } elseif (-not $current.Contains($prop)) {
            $current[$prop] = $defaults[$prop]
        } else {
            $current[$prop] = $defaults[$prop]
        }
    }

    return $current
}

function Read-YesNoResponse {
    param(
        [string]$Message,
        [bool]$DefaultYes = $true,
        [string[]]$Context = @()
    )

    $options = @('Yes', 'No')
    $defaultChoice = if ($DefaultYes) { 'Yes' } else { 'No' }
    $selection = Invoke-InteractiveSelection -Items $options -Prompt $Message -CurrentValues @($defaultChoice) -ContextLines $Context
    return $selection -eq 'Yes'
}

function Get-ConfigData {
    if (-not (Test-Path $configPath)) {
        if (Read-YesNoResponse "No config.json found. Create a new configuration?" $true) {
            $defaults = [ordered]@{
                hotkeys       = Get-DefaultHotkeys
                overlay       = Get-DefaultOverlay
                settings      = Get-DefaultSettings
                profiles = [ordered]@{
                    "1" = [ordered]@{
                        activeDisplays = @()
                        disableDisplays = @()
                        audio = $null
                        microphone = ''
                    }
                }
            }
            $defaults | ConvertTo-Json -Depth 6 | Set-Content -Path $configPath -Encoding UTF8
            Write-Host "Created new config at $configPath" -ForegroundColor Green
        } else {
            throw "Cannot proceed without config.json."
{{ ... }}
        }
    }
    try {
        $raw = Get-Content -Path $configPath -Raw -Encoding UTF8
        if (-not $raw.Trim()) {
            $raw = (@{ hotkeys = Get-DefaultHotkeys; overlay = Get-DefaultOverlay; settings = Get-DefaultSettings; profiles = @{} } | ConvertTo-Json -Depth 6)
            Set-Content -Path $configPath -Value $raw -Encoding UTF8
        }
        $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
    } catch {
        throw "Failed to read or parse config.json: $_"
    }

    $rootMap = ConvertTo-OrderedMap $parsed

    if ($env:MONITOR_MANAGE_DEBUG) {
        Write-Host "[DEBUG] rootMap keys: $($rootMap.Keys -join ', ')" -ForegroundColor Gray
        Write-Host "[DEBUG] rootMap['profiles'] type: $($rootMap['profiles'].GetType().Name)" -ForegroundColor Gray
        Write-Host "[DEBUG] rootMap['profiles'] is null: $($null -eq $rootMap['profiles'])" -ForegroundColor Gray
    }

    $script:HotkeySettings = Set-HotkeyProfileDefaults (Merge-OrderedDefaults (ConvertTo-OrderedMap $rootMap['hotkeys']) (Get-DefaultHotkeys))
    $script:OverlaySettings = Merge-OrderedDefaults (ConvertTo-OrderedMap $rootMap['overlay']) (Get-DefaultOverlay)
    $script:Settings = Merge-OrderedDefaults (ConvertTo-OrderedMap $rootMap['settings']) (Get-DefaultSettings)

    $profileSource = $rootMap['profiles']
    
    if ($env:MONITOR_MANAGE_DEBUG) {
        Write-Host "[DEBUG] profileSource is null: $($null -eq $profileSource)" -ForegroundColor Gray
        Write-Host "[DEBUG] profileSource is empty: $(-not $profileSource)" -ForegroundColor Gray
        if ($profileSource) {
            Write-Host "[DEBUG] profileSource type: $($profileSource.GetType().Name)" -ForegroundColor Gray
            $profKeys = $profileSource | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
            Write-Host "[DEBUG] profileSource properties: $($profKeys -join ', ')" -ForegroundColor Gray
        }
    }
    
    if (-not $profileSource) {
        if ($env:MONITOR_MANAGE_DEBUG) {
            Write-Host "[DEBUG] profileSource was falsy, checking rootMap keys" -ForegroundColor Gray
        }
        $profileSource = [ordered]@{}
        foreach ($key in $rootMap.Keys) {
            if ($key -in @('hotkeys', 'overlay', 'profiles', 'settings')) { continue }
            $profileSource[$key] = $rootMap[$key]
        }
    } else {
        # Convert to OrderedDictionary if it's a PSCustomObject
        $profileSource = ConvertTo-OrderedMap $profileSource
    }

    $result = [System.Collections.Specialized.OrderedDictionary]::new()

    if ($env:MONITOR_MANAGE_DEBUG) {
        Write-Host "[DEBUG] profileSource has $($profileSource.Keys.Count) keys: $($profileSource.Keys -join ', ')" -ForegroundColor Gray
    }

    foreach ($key in $profileSource.Keys) {
        # Skip documentation and metadata keys (starting with _)
        if ($key -match '^_') { continue }
        
        $profileValue = $profileSource[$key]
        
        if ($env:MONITOR_MANAGE_DEBUG) {
            Write-Host "[DEBUG] Processing profile $key" -ForegroundColor Gray
            Write-Host "[DEBUG]   activeDisplays raw: $($profileValue.activeDisplays)" -ForegroundColor Gray
        }
        
        $activeConverted = ConvertTo-DisplayReferenceArray @($profileValue.activeDisplays)
        $disableConverted = ConvertTo-DisplayReferenceArray @($profileValue.disableDisplays)
        
        if ($env:MONITOR_MANAGE_DEBUG) {
            Write-Host "[DEBUG]   activeDisplays converted count: $($activeConverted.Count)" -ForegroundColor Gray
            Write-Host "[DEBUG]   disableDisplays converted count: $($disableConverted.Count)" -ForegroundColor Gray
        }
        
        $result[$key] = [ordered]@{
            activeDisplays  = $activeConverted
            disableDisplays = $disableConverted
            audio           = $profileValue.audio
            microphone      = $profileValue.microphone
        }
    }

    if ($env:MONITOR_MANAGE_DEBUG) {
        Write-Host "[DEBUG] Get-ConfigData returning $($result.Keys.Count) profiles" -ForegroundColor Gray
    }

    return $result
}

function Save-ConfigData {
    param([System.Collections.Specialized.OrderedDictionary]$Config)

    if (-not $script:HotkeySettings) {
        $script:HotkeySettings = Get-DefaultHotkeys
    }
    $script:HotkeySettings = Set-HotkeyProfileDefaults $script:HotkeySettings
    if (-not $script:OverlaySettings) {
        $script:OverlaySettings = Get-DefaultOverlay
    }
    if (-not $script:Settings) {
        $script:Settings = Get-DefaultSettings
    }

    $exportProfiles = [ordered]@{}
    foreach ($key in $Config.Keys) {
        # Skip documentation and metadata keys (starting with _)
        if ($key -match '^_') { continue }
        
        $profile = $Config[$key]
        $activeRefs = ConvertTo-DisplayReferenceArray @($profile.activeDisplays)
        $disableRefs = ConvertTo-DisplayReferenceArray @($profile.disableDisplays)

        $activeNames = ConvertTo-NameArray -References $activeRefs
        $disableNames = ConvertTo-NameArray -References $disableRefs

        $exportProfiles[$key] = [ordered]@{
            activeDisplays  = ConvertTo-ConfigDisplayValue -Names $activeNames
            disableDisplays = ConvertTo-ConfigDisplayValue -Names $disableNames
            audio           = if ($profile.audio) { [string]$profile.audio } else { $null }
            microphone      = if ($profile.microphone) { [string]$profile.microphone } else { '' }
        }
    }

    $root = [ordered]@{
        hotkeys       = $script:HotkeySettings
        overlay       = $script:OverlaySettings
        settings      = $script:Settings
        profiles = $exportProfiles
    }

    $json = $root | ConvertTo-Json -Depth 6
    Set-Content -Path $configPath -Value $json -Encoding UTF8
    Write-Host "Configuration saved to $configPath" -ForegroundColor Green
}

function Invoke-DevicesSnapshotExport {
    Write-Host "Running export script to refresh devices snapshot..." -ForegroundColor Cyan
    try {
        & $exportScript -OutputPath $snapshotPath
        Write-Host "Updated $snapshotPath" -ForegroundColor Green
    } catch {
        Write-Host "Failed to update devices snapshot: $_" -ForegroundColor Red
    }
}

function Initialize-DevicesSnapshot {
    if (-not (Test-Path $snapshotPath)) {
        Write-Host "devices_snapshot.json not found." -ForegroundColor Yellow
        if (Read-YesNoResponse "Generate a snapshot now?" $true) {
            Invoke-DevicesSnapshotExport
        } else {
            Write-Host "Proceeding without snapshot. Some lists will be empty." -ForegroundColor Yellow
        }
    }
}

function New-DefaultProfiles {
    param(
        [array]$AvailableDisplays,
        [array]$AvailableAudio
    )
    
    if ($AvailableDisplays.Count -eq 0) {
        Write-Host "No displays detected. Cannot generate default profiles." -ForegroundColor Yellow
        return [ordered]@{}
    }
    
    Write-Host "`nGenerating default profiles..." -ForegroundColor Cyan
    
    $config = [ordered]@{}
    $profileNum = 1
    
    # Get default audio device (first in list or none)
    $defaultAudio = $null
    if ($AvailableAudio.Count -gt 0) {
        $defaultAudio = $AvailableAudio[0].Name
    }
    
    # If only one display, create a simple profile
    if ($AvailableDisplays.Count -eq 1) {
        $display = $AvailableDisplays[0]
        $config["$profileNum"] = [ordered]@{
            activeDisplays = @(@{ Name = $display.Name; displayId = $display.DisplayId })
            disableDisplays = @()
            audio = $defaultAudio
            microphone = ''
        }
        Write-Host "  profile 1: $($display.Name) (single display)" -ForegroundColor Gray
        return $config
    }
    
    # For multiple displays, create individual profiles (one display at a time)
    foreach ($display in $AvailableDisplays) {
        $otherDisplays = $AvailableDisplays | Where-Object { $_.Name -ne $display.Name }
        
        $config["$profileNum"] = [ordered]@{
            activeDisplays = @(@{ Name = $display.Name; displayId = $display.DisplayId })
            disableDisplays = @($otherDisplays | ForEach-Object { @{ Name = $_.Name; displayId = $_.DisplayId } })
            audio = $defaultAudio
            microphone = ''
        }
        
        Write-Host "  profile ${profileNum}: $($display.Name) only" -ForegroundColor Gray
        $profileNum++
    }
    
    Write-Host "`nGenerated $($config.Keys.Count) default profile(s)." -ForegroundColor Green
    Write-Host "Note: Use Alt+Shift+8 (panic button) to enable all displays at once." -ForegroundColor Gray
    return $config
}

function Get-DeviceInventory {
    if (-not (Test-Path $snapshotPath)) {
        return @(), @(), @()
    }
    try {
        $raw = Get-Content -Path $snapshotPath -Raw -Encoding UTF8
        if (-not $raw.Trim()) { return @(), @(), @() }
        $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Host "Failed to read devices snapshot: $_" -ForegroundColor Red
        return @(), @(), @()
    }
    $displays = @()
    $audio = @()
    $microphones = @()

    if ($parsed.Displays) {
        foreach ($entry in @($parsed.Displays)) {
            $reference = ConvertTo-DisplayReference $entry
            if (-not $reference) { continue }

            $name = Get-DisplayReferenceName $reference
            $id = Get-DisplayReferenceId $reference

            $displays += [ordered]@{
                name      = $name
                displayId = if ($id) { [string]$id } else { $null }
            }
        }
    }

    if ($parsed.AudioDevices) { $audio = @($parsed.AudioDevices) }
    if ($parsed.Microphones) { $microphones = @($parsed.Microphones) }

    return $displays, $audio, $microphones
}

function New-SelectionItem {
    param(
        [string]$Label,
        [object]$Value,
        [string]$Identity
    )

    if (-not $Identity) {
        $Identity = Get-SelectionIdentity $Value
    }

    return [PSCustomObject]@{
        Label    = [string]$Label
        Value    = $Value
        Identity = $Identity
    }
}

function Get-DisplayReferenceName {
    param($Value)

    if ($null -eq $Value) { return $null }

    if ($Value -is [string]) {
        return [string]$Value
    }

    if ($Value -is [System.Collections.IDictionary]) {
        foreach ($key in 'name','Name','displayName','DisplayName','FriendlyName') {
            if ($Value.Contains($key) -and $Value[$key]) {
                return [string]$Value[$key]
            }
        }
        return $null
    }

    if ($Value -is [System.Management.Automation.PSObject]) {
        foreach ($key in 'name','Name','displayName','DisplayName','FriendlyName') {
            $prop = $Value.PSObject.Properties[$key]
            if ($prop -and $prop.Value) {
                return [string]$prop.Value
            }
        }
        return $null
    }

    return $null
}

function Get-DisplayReferenceId {
    param($Value)

    if ($null -eq $Value) { return $null }

    if ($Value -is [System.Collections.IDictionary]) {
        foreach ($key in 'displayId','DisplayId','id','Id','pathId','PathId','targetId','TargetId') {
            if ($Value.Contains($key) -and $Value[$key]) {
                return [string]$Value[$key]
            }
        }
        return $null
    }

    if ($Value -is [System.Management.Automation.PSObject]) {
        foreach ($key in 'displayId','DisplayId','id','Id','pathId','PathId','targetId','TargetId') {
            $prop = $Value.PSObject.Properties[$key]
            if ($prop -and $prop.Value) {
                return [string]$prop.Value
            }
        }
        return $null
    }

    return $null
}

function ConvertTo-DisplayReference {
    param($Value)

    if ($null -eq $Value) { return $null }

    if ($Value -is [System.Collections.DictionaryEntry]) {
        return ConvertTo-DisplayReference -Value $Value.Value
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $name = Get-DisplayReferenceName $Value
        $id = Get-DisplayReferenceId $Value
        return [ordered]@{
            name      = if ($name) { [string]$name } else { $null }
            displayId = if ($id) { [string]$id } else { $null }
        }
    }

    if ($Value -is [System.Management.Automation.PSObject]) {
        $hash = @{}
        foreach ($prop in $Value.PSObject.Properties) {
            $hash[$prop.Name] = $prop.Value
        }
        return ConvertTo-DisplayReference -Value $hash
    }

    $text = [string]$Value
    return [ordered]@{
        name      = $text
        displayId = $null
    }
}

function Format-DisplayReference {
    param($Value)

    $reference = ConvertTo-DisplayReference $Value
    if (-not $reference) { return '(unnamed display)' }

    $name = Get-DisplayReferenceName $reference
    if ($name) { return $name }

    $id = Get-DisplayReferenceId $reference
    if ($id) { return "Display $id" }

    return '(unnamed display)'
}

function Get-NormalizedDisplayName {
    param([string]$Name)

    if (-not $Name) { return $null }

    $trimmed = $Name.Trim()
    if (-not $trimmed) { return $null }

    $lower = $trimmed.ToLowerInvariant()
    $collapsed = [System.Text.RegularExpressions.Regex]::Replace($lower, '\s+', ' ')
    $normalized = [System.Text.RegularExpressions.Regex]::Replace($collapsed, '[^a-z0-9]', '')
    if (-not $normalized) { return $null }
    return $normalized
}

function ConvertTo-DisplayReferenceArray {
    param([object[]]$Values)

    $results = @()
    foreach ($value in $Values) {
        $converted = ConvertTo-DisplayReference $value
        if (-not $converted) { continue }

        if (-not $converted.Name -and $converted.DisplayId) {
            $converted = [pscustomobject]@{
                Name      = [string]$converted.DisplayId
                DisplayId = $null
            }
        }

        $results += $converted
    }

    return @($results)
}

function ConvertTo-NameArray {
    param([object[]]$References)

    $names = @()
    foreach ($reference in $References) {
        if (-not $reference) { continue }
        $name = Get-DisplayReferenceName $reference
        if ($name) { $names += [string]$name }
    }
    return @($names)
}

function ConvertTo-ConfigDisplayValue {
    param([string[]]$Names)

    if (-not $Names -or $Names.Count -eq 0) {
        return @()
    }

    if ($Names.Count -eq 1) {
        return $Names[0]
    }

    return $Names
}

function Get-UniqueDisplayReferences {
    param([object[]]$References)

    if (-not $References) { return @() }

    $unique = @()
    $seen = New-Object 'System.Collections.Generic.HashSet[string]'

    foreach ($reference in (ConvertTo-DisplayReferenceArray @($References))) {
        if (-not $reference) { continue }
        $identity = Get-SelectionIdentity $reference
        if (-not $identity) { $identity = [guid]::NewGuid().ToString() }
        if ($seen.Add($identity)) {
            $unique += $reference
        }
    }

    return @($unique)
}

function Format-DisplayLabel {
    param($Value)

    if ($Value -is [string]) {
        return [string]$Value
    }

    $reference = ConvertTo-DisplayReference $Value
    if (-not $reference) {
        return '(unnamed display)'
    }

    $name = Get-DisplayReferenceName $reference
    if ($name) {
        return $name
    }

    $id = Get-DisplayReferenceId $reference
    if ($id) {
        return 'Display'
    }

    return '(unnamed display)'
}

function Format-DisplayLabelWithStatus {
    param(
        $Value,
        [object[]]$KnownDisplays = $null
    )

    $label = Format-DisplayLabel -Value $Value

    if (-not $KnownDisplays -and $script:CurrentDisplayInventory) {
        $KnownDisplays = $script:CurrentDisplayInventory
    }

    if (-not $KnownDisplays) {
        return $label
    }

    $reference = ConvertTo-DisplayReference $Value
    if (-not $reference) {
        return $label
    }

    $name = Get-DisplayReferenceName $reference
    $id = Get-DisplayReferenceId $reference

    if (-not $name -and -not $id) {
        return $label
    }

    $matched = $null
    if ($id) {
        $matched = $KnownDisplays | Where-Object { (Get-DisplayReferenceId $_) -eq $id }
    }
    if (-not $matched -and $name) {
        $matched = $KnownDisplays | Where-Object { (Get-DisplayReferenceName $_) -eq $name }
    }

    if (-not $matched) {
        return "{0} (not found)" -f $label
    }

    return $label
}

function Get-SelectionIdentity {
    param($Value)

    if ($null -eq $Value) { return '__NULL__' }

    if ($Value -is [string]) { return "str::$Value" }

    $reference = ConvertTo-DisplayReference $Value
    if ($reference) {
        $name = Get-DisplayReferenceName $reference
        $displayId = Get-DisplayReferenceId $reference
        $normalizedName = Get-NormalizedDisplayName $name

        if ($normalizedName) { return "name::$normalizedName" }
        if ($displayId) { return "displayid::$displayId" }
    }

    if ($Value -is [ValueType]) { return "val::$Value" }

{{ ... }}
    return "obj::{0}" -f ($Value.GetHashCode())
}

function Format-DisplaySummary {
    param(
        [object[]]$Values,
        [object[]]$KnownDisplays = $null
    )

    $unique = Get-UniqueDisplayReferences -References $Values
    if ($unique.Count -eq 0) { return '(none)' }

    if (-not $KnownDisplays -and $script:CurrentDisplayInventory) {
        $KnownDisplays = $script:CurrentDisplayInventory
    }

    if ($KnownDisplays) {
        return ($unique | ForEach-Object { Format-DisplayLabelWithStatus -Value $_ -KnownDisplays $KnownDisplays }) -join ', '
    }

    return ($unique | ForEach-Object { Format-DisplayReference $_ }) -join ', '
}

function Select-DisplayReferencesMultiple {
    param(
        [object[]]$Available,
        [object[]]$Current,
        [string]$Prompt,
        [string[]]$Context = @()
    )

    $options = ConvertTo-DisplayReferenceArray @($Available)
    $existing = ConvertTo-DisplayReferenceArray @($Current)

    $identityMap = @{}
    $entries = @()
    foreach ($reference in $options) {
        if ($null -eq $reference) { continue }
        $identity = Get-SelectionIdentity $reference
        if (-not $identityMap.ContainsKey($identity)) {
            $label = Format-DisplayLabel $reference
            if ([string]::IsNullOrWhiteSpace($label) -or $label -like 'System.Collections.*') { continue }
            $identityMap[$identity] = $reference
            $entries += New-SelectionItem -Label $label -Value $reference -Identity $identity
        }
    }

    $missingReferences = @()
    foreach ($reference in $existing) {
        if ($null -eq $reference) { continue }
        $identity = Get-SelectionIdentity $reference
        if (-not $identityMap.ContainsKey($identity)) {
            $missingReferences += $reference
        }
    }

    if ($entries.Count -eq 0) {
        Write-Host "No displays available for $Prompt. Clearing selection." -ForegroundColor Yellow
        return @()
    }

    if ($missingReferences.Count -gt 0) {
        $missingLabels = ($missingReferences | ForEach-Object { Format-DisplayLabelWithStatus -Value $_ }) -join ', '
        if ($missingLabels) {
            $Context += "Unavailable (kept): $missingLabels"
        }
    }

    $currentValues = @()
    foreach ($reference in $existing) {
        $identity = Get-SelectionIdentity $reference
        if ($identityMap.ContainsKey($identity)) {
            $currentValues += $identityMap[$identity]
        }
    }

    $selection = Invoke-InteractiveSelection -Items $entries -Prompt $Prompt -CurrentValues $currentValues -Multiple -ContextLines $Context

    if ($script:SelectionCancelled) {
        return $Current
    }

    if ($null -eq $selection) {
        return $existing
    }

    $result = @()
    $result += ConvertTo-DisplayReferenceArray @($selection)

    if ($missingReferences.Count -gt 0) {
        $resultIdentities = New-Object 'System.Collections.Generic.HashSet[string]'
        foreach ($ref in $result) {
            $null = $resultIdentities.Add((Get-SelectionIdentity $ref))
        }
        foreach ($ref in $missingReferences) {
            $identity = Get-SelectionIdentity $ref
            if (-not $resultIdentities.Contains($identity)) {
                $result = @($result)
                $result += $ref
            }
        }
    }

    return @($result)
}

function Select-DisplayReferenceSingle {
    param(
        [object[]]$Available,
        [object]$Current,
        [string]$Prompt,
        [string[]]$Context = @(),
        [switch]$AllowNone
    )

    $availableRefs = ConvertTo-DisplayReferenceArray @($Available)
    $existing = ConvertTo-DisplayReferenceArray @($Current)
    $currentRef = if ($existing.Count -gt 0) { $existing[0] } else { $null }

    $identityMap = @{}
    $entries = @()
    foreach ($reference in $availableRefs) {
        if ($null -eq $reference) { continue }
        $identity = Get-SelectionIdentity $reference
        if (-not $identityMap.ContainsKey($identity)) {
            $label = Format-DisplayLabel $reference
            if ([string]::IsNullOrWhiteSpace($label) -or $label -like 'System.Collections.*') { continue }
            $identityMap[$identity] = $reference
            $entries += New-SelectionItem -Label $label -Value $reference -Identity $identity
        }
    }

    $missingReference = $null
    if ($currentRef) {
        $identity = Get-SelectionIdentity $currentRef
        if (-not $identityMap.ContainsKey($identity)) {
            $missingReference = $currentRef
        }
    }

    if ($AllowNone -and -not ($entries | Where-Object { $null -eq $_.Value })) {
        $entries += New-SelectionItem -Label '[None]' -Value $null -Identity '__NULL__'
    }

    if ($missingReference) {
        $missingLabel = Format-DisplayLabelWithStatus -Value $missingReference
        if ($missingLabel) {
            $Context += "Unavailable (kept): $missingLabel"
        }
    }

    if ($entries.Count -eq 0) {
        Write-Host "No displays available for $Prompt." -ForegroundColor Yellow
        if ($AllowNone) { return $null }
        return $currentRef
    }

    $currentValues = @()
    if ($currentRef) {
        $identity = Get-SelectionIdentity $currentRef
        if ($identityMap.ContainsKey($identity)) {
            $currentValues += $identityMap[$identity]
        }
    }

    if ($AllowNone) {
        $selection = Invoke-InteractiveSelection -Items $entries -Prompt $Prompt -CurrentValues $currentValues -AllowNone -ContextLines $Context
    } else {
        $selection = Invoke-InteractiveSelection -Items $entries -Prompt $Prompt -CurrentValues $currentValues -ContextLines $Context
    }

    if ($script:SelectionCancelled) {
        return $currentRef
    }

    if ($null -eq $selection) {
        if ($AllowNone) { return $null }
        return $currentRef
    }

    $result = ConvertTo-DisplayReferenceArray @($selection)
    if ($result.Count -eq 0) {
        if ($AllowNone) { return $null }
        return $currentRef
    }

    $merged = Merge-DisplayReferences -References $result -Available $availableRefs
    if ($merged.Count -eq 0) {
        if ($AllowNone) { return $null }
        return $currentRef
    }

    return $merged[0]
}

function Merge-DisplayReferences {
    param(
        [object[]]$References,
        [object[]]$Available
    )

    $availableRefs = ConvertTo-DisplayReferenceArray @($Available)
    $byId = @{}
    $byName = @{}
    $byNormalizedName = @{}
    foreach ($display in $availableRefs) {
        if (-not $display) { continue }
        $name = Get-DisplayReferenceName $display
        $id = Get-DisplayReferenceId $display
        if ($id) { $byId[[string]$id] = $display }
        if ($name) { $byName[$name] = $display }

        $normalized = Get-NormalizedDisplayName $name
        if ($normalized -and -not $byNormalizedName.ContainsKey($normalized)) {
            $byNormalizedName[$normalized] = $display
        }
    }

    $normalized = @()
    foreach ($reference in (ConvertTo-DisplayReferenceArray @($References))) {
        if (-not $reference) { continue }

        $result = ConvertTo-DisplayReference $reference
        if (-not $result) { continue }

        $currentName = Get-DisplayReferenceName $result
        $currentId = Get-DisplayReferenceId $result
        $currentNormalized = Get-NormalizedDisplayName $currentName

        if ($currentName -and $byName.ContainsKey($currentName)) {
            $source = $byName[$currentName]
            $sourceId = Get-DisplayReferenceId $source
            if ($sourceId) { $result['displayId'] = [string]$sourceId }
            if (-not $currentName) {
                $result['name'] = Get-DisplayReferenceName $source
            }
        } elseif ($currentNormalized -and $byNormalizedName.ContainsKey($currentNormalized)) {
            $source = $byNormalizedName[$currentNormalized]
            $sourceId = Get-DisplayReferenceId $source
            $sourceName = Get-DisplayReferenceName $source
            if ($sourceId) { $result['displayId'] = [string]$sourceId }
            if ($sourceName) { $result['name'] = $sourceName }
        } elseif ($currentId -and $byId.ContainsKey([string]$currentId)) {
            $source = $byId[[string]$currentId]
            $sourceName = Get-DisplayReferenceName $source
            if (-not $currentName -and $sourceName) { $result['name'] = $sourceName }
        }

        if (-not (Get-DisplayReferenceId $result) -and $currentId) {
            $result['displayId'] = [string]$currentId
        }
        if (-not (Get-DisplayReferenceName $result) -and $currentName) {
            $result['name'] = $currentName
        }

        $normalized += $result
    }

    return @($normalized)
}

function Resolve-MissingDisplayIds {
    param(
        [System.Collections.Specialized.OrderedDictionary]$Config,
        [object[]]$AvailableDisplays
    )

    if (-not $Config) { return }

    $normalizedAvailable = ConvertTo-DisplayReferenceArray @($AvailableDisplays)
    if ($normalizedAvailable.Count -eq 0) { return }

    $keys = @($Config.Keys)
    foreach ($key in $keys) {
        $profile = $Config[$key]
        if (-not $profile) { continue }

        $profile.activeDisplays  = Merge-DisplayReferences -References $profile.activeDisplays -Available $normalizedAvailable
        $profile.disableDisplays = Merge-DisplayReferences -References $profile.disableDisplays -Available $normalizedAvailable

        $Config[$key] = $profile
    }
}

function Select-SingleItem {
    param(
        [string[]]$Items,
        [string]$Prompt,
        [object]$Current,
        [switch]$AllowNone,
        [string[]]$Context = @()
    )

    if (-not $Items -or $Items.Count -eq 0) {
        Write-Host "No items available for $Prompt. Clearing selection." -ForegroundColor Yellow
        return $null
    }

    $entries = @()
    foreach ($item in $Items) {
        $entries += New-SelectionItem -Label $item -Value $item
    }

    if ($AllowNone -and -not ($entries | Where-Object { $_.Label -eq '[None]' })) {
        # Use empty string as the value for [None] instead of null
        $entries += New-SelectionItem -Label '[None]' -Value '' -Identity '__NONE__'
    }

    $currentValues = @()
    if ($Current -eq '') {
        # Empty string means explicitly set to [None]
        $currentValues += '__NONE__'
    } elseif ($Current) {
        # Has an actual value
        $currentValues += $Current
    }
    # If null, leave currentValues empty (no pre-selection)

    if ($AllowNone) {
        $result = Invoke-InteractiveSelection -Items $entries -Prompt $Prompt -CurrentValues $currentValues -AllowNone -ContextLines $Context
    } else {
        $result = Invoke-InteractiveSelection -Items $entries -Prompt $Prompt -CurrentValues $currentValues -ContextLines $Context
    }

    if ($script:SelectionCancelled) {
        $script:SelectionCancelled = $false
        return $Current
    }

    return $result
}

function Set-ConsoleCapacity {
    param([int]$RequiredRows)

    $rawUi = $Host.UI.RawUI
    $buffer = $rawUi.BufferSize
    if ($RequiredRows -lt $buffer.Height) { return }

    $targetHeight = [Math]::Max($RequiredRows + 2, $rawUi.WindowSize.Height + 2)
    $targetHeight = [Math]::Max($targetHeight, $buffer.Height * 2)
    if ($targetHeight -gt 5000) { $targetHeight = 5000 }
    $rawUi.BufferSize = New-Object System.Management.Automation.Host.Size($buffer.Width, $targetHeight)
}

function Get-SortedIndices {
    param([System.Collections.Generic.HashSet[int]]$Set)

    $values = @()
    foreach ($item in $Set) {
        $values += [int]$item
    }
    return $values | Sort-Object
}

function Write-PaddedLine {
    param(
        [string]$Text,
        [int]$Width
    )

    if ($null -eq $Text) { $Text = '' }
    if ($Width -lt 1) {
        Write-Host $Text
        return
    }

    $displayWidth = $Width
    if ($Text.Length -gt $displayWidth) {
        $Text = $Text.Substring(0, [Math]::Max($displayWidth - 1, 0))
    }
    Write-Host ($Text.PadRight($displayWidth))
}

function Get-ProfileDescription {
    param(
        [string]$Key,
        [hashtable]$profile
    )

    $activeReferences = ConvertTo-DisplayReferenceArray @($profile.activeDisplays)
    $inactiveReferences = ConvertTo-DisplayReferenceArray @($profile.disableDisplays)

    if ($activeReferences.Count) {
        $active = ($activeReferences | ForEach-Object { Format-DisplayLabelWithStatus $_ }) -join ', '
    } else {
        $active = '(none)'
    }

    if ($inactiveReferences.Count) {
        $inactive = ($inactiveReferences | ForEach-Object { Format-DisplayLabelWithStatus $_ }) -join ', '
    } else {
        $inactive = '(none)'
    }

    if ($profile.audio) {
        $audio = $profile.audio
    } else {
        $audio = '(none)'
    }
    
    # Include microphone info if microphone management is enabled
    $description = "profile ${Key}: enable -> ${active} | disable -> ${inactive} | audio -> ${audio}"
    if ($script:Settings -and $script:Settings.enableMicrophoneManagement) {
        $mic = if ($profile.microphone) { $profile.microphone } else { '(none)' }
        $description += " | mic -> ${mic}"
    }
    
    return $description
}

function Get-ProfileEntries {
    param([System.Collections.Specialized.OrderedDictionary]$Config)

    $entries = @()
    foreach ($key in ($Config.Keys | Sort-Object {[int]::TryParse($_,[ref]$null); $_})) {
        # Skip documentation and metadata keys (starting with _ or reserved names)
        if ($key -match '^_' -or $key -in @('settings', 'hotkeys', 'overlay', 'profiles', 'version')) { 
            continue 
        }
        
        $profile = $Config[$key]
        $entries += New-SelectionItem -Label (Get-ProfileDescription -Key $key -profile $profile) -Value $key
    }
    return @($entries)
}

function Get-NextProfileKey {
    param([System.Collections.Specialized.OrderedDictionary]$Config)

    $used = New-Object 'System.Collections.Generic.HashSet[int]'

    foreach ($key in $Config.Keys) {
        $candidate = 0
        if ([int]::TryParse($key, [ref]$candidate)) {
            $null = $used.Add($candidate)
        }
    }

    $next = 1
    while ($used.Contains($next)) {
        $next++
    }

    return [string]$next
}

function Invoke-InteractiveSelection {
    param(
        [System.Collections.IEnumerable]$Items,
        [string]$Prompt,
        [object[]]$CurrentValues,
        [switch]$Multiple,
        [switch]$AllowNone,
        [string[]]$ContextLines = @()
    )

    $script:SelectionCancelled = $false

    $itemList = @()
    foreach ($entry in $Items) {
        if ($entry -is [System.Management.Automation.PSObject] -and $entry.PSObject.Properties['Label'] -and $entry.PSObject.Properties['Value']) {
            $itemList += $entry
        } else {
            $label = [string]$entry
            $itemList += New-SelectionItem -Label $label -Value $entry
        }
    }

    if ($itemList.Count -eq 0) {
        if ($Multiple) { return @() }
        return $null
    }

    $console = [System.Console]
    $rawUi = $Host.UI.RawUI
    $bufferWidth = $rawUi.BufferSize.Width
    if ($bufferWidth -lt 10) {
        $bufferWidth = 120
    }

    $originalValues = if ($CurrentValues) { @($CurrentValues) } else { @() }
    $currentIdentities = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($value in $originalValues) {
        $null = $currentIdentities.Add((Get-SelectionIdentity $value))
    }

    $selectedIndices = New-Object System.Collections.Generic.HashSet[int]
    for ($i = 0; $i -lt $itemList.Count; $i++) {
        $itemIdentity = $itemList[$i].Identity
        if (-not $itemIdentity) {
            $itemIdentity = Get-SelectionIdentity $itemList[$i].Value
            $itemList[$i] = New-SelectionItem -Label $itemList[$i].Label -Value $itemList[$i].Value -Identity $itemIdentity
        }
        if ($currentIdentities.Contains($itemIdentity)) {
            $null = $selectedIndices.Add($i)
        }
    }

    if (-not $Multiple) {
        if ($selectedIndices.Count -eq 0 -and -not $AllowNone) {
            $null = $selectedIndices.Add(0)
        } elseif ($selectedIndices.Count -gt 1) {
            $sortedCurrent = Get-SortedIndices -Set $selectedIndices
            if ($sortedCurrent.Count -gt 0) {
                $selectedIndices.Clear()
                $null = $selectedIndices.Add($sortedCurrent[0])
            }
        }
    }

    if ($itemList.Count -eq 1) {
        $currentIndex = 0
    } elseif ($selectedIndices.Count -gt 0) {
        $sortedInitial = Get-SortedIndices -Set $selectedIndices
        if ($sortedInitial.Count -gt 0) {
            $currentIndex = $sortedInitial[0]
        } else {
            $currentIndex = 0
        }
    } else {
        $currentIndex = 0
    }

    $instructionLines = @()
    if ($Multiple) {
        $instructionLines += 'Use Up/Down arrows to move, Space toggles selection, Enter confirms, Esc cancels.'
        $instructionLines += 'Press Delete to clear all selections.'
    } else {
        $instructionLines += 'Use Up/Down arrows to move, Enter confirms, Esc cancels.'
        if ($AllowNone) {
            $instructionLines += 'Press Delete to clear the selection.'
        }
    }

    $headerCount = $ContextLines.Count + 1 + $instructionLines.Count
    $blockHeight = $headerCount + $itemList.Count

    $requiredRows = $console::CursorTop + $blockHeight + 2
    Set-ConsoleCapacity -RequiredRows $requiredRows

    $blockTop = $console::CursorTop
    for ($i = 0; $i -lt $blockHeight; $i++) { Write-Host '' }

    $initialCursorVisible = $console::CursorVisible
    $console::CursorVisible = $false

    try {
        while ($true) {
            $console::SetCursorPosition(0, $blockTop)

            foreach ($line in $ContextLines) {
                Write-PaddedLine -Text $line -Width $bufferWidth
            }

            Write-PaddedLine -Text $Prompt -Width $bufferWidth
            foreach ($line in $instructionLines) {
                Write-PaddedLine -Text $line -Width $bufferWidth
            }

            for ($i = 0; $i -lt $itemList.Count; $i++) {
                $item = $itemList[$i]
                if ($Multiple) {
                    if ($selectedIndices.Contains($i)) {
                        $marker = '[x]'
                    } else {
                        $marker = '[ ]'
                    }
                } else {
                    if ($selectedIndices.Contains($i)) {
                        $marker = '(*)'
                    } else {
                        $marker = '( )'
                    }
                }

                if ($i -eq $currentIndex) {
                    $prefix = '>'
                } else {
                    $prefix = ' '
                }

                $labelValue = $item.Value
                if ($labelValue -is [System.Collections.IDictionary] -or $labelValue -is [System.Management.Automation.PSObject]) {
                    $label = Format-DisplayLabel $labelValue
                } else {
                    $label = $item.Label
                }

                if ($label -is [System.Collections.IDictionary] -or $label -is [System.Management.Automation.PSObject]) {
                    $label = Format-DisplayLabel $label
                }
                $label = [string]$label
                if ([string]::IsNullOrWhiteSpace($label) -or $label -like 'System.Collections.*') {
                    $label = '<unnamed>'
                }

                $lineText = "{0} {1} {2}" -f $prefix, $marker, $label
                if ($lineText.Length -gt $bufferWidth) {
                    $lineText = $lineText.Substring(0, [Math]::Max($bufferWidth - 1, 0))
                }
                Write-PaddedLine -Text $lineText -Width $bufferWidth
            }

            $readRow = $blockTop + $blockHeight - 1
            Set-ConsoleCapacity -RequiredRows ($readRow + 2)
            $console::SetCursorPosition(0, $readRow)
            $keyInfo = $console::ReadKey($true)

            switch ($keyInfo.Key) {
                'UpArrow' {
                    if ($currentIndex -gt 0) { $currentIndex-- } else { $currentIndex = $itemList.Count - 1 }
                }
                'DownArrow' {
                    if ($currentIndex -lt $itemList.Count - 1) { $currentIndex++ } else { $currentIndex = 0 }
                }
                'Home' { $currentIndex = 0 }
                'End' { $currentIndex = $itemList.Count - 1 }
                'Spacebar' {
                    if ($Multiple) {
                        if ($selectedIndices.Contains($currentIndex)) {
                            $selectedIndices.Remove($currentIndex) | Out-Null
                        } else {
                            $selectedIndices.Add($currentIndex) | Out-Null
                        }
                    } else {
                        $selectedIndices.Clear()
                        $selectedIndices.Add($currentIndex) | Out-Null
                    }
                }
                'Delete' {
                    if ($Multiple -or $AllowNone) {
                        $selectedIndices.Clear()
                    }
                }
                'Escape' {
                    $console::SetCursorPosition(0, $blockTop + $blockHeight)
                    Write-Host ''
                    $script:SelectionCancelled = $true
                    if ($Multiple) { return $originalValues }
                    if ($originalValues.Count -eq 0) { return $null }
                    return $originalValues[0]
                }
                'Enter' {
                    if ($Multiple) {
                        $result = @()
                        for ($i = 0; $i -lt $itemList.Count; $i++) {
                            if ($selectedIndices.Contains($i)) {
                                $result += $itemList[$i].Value
                            }
                        }
                        $console::SetCursorPosition(0, $blockTop + $blockHeight)
                        Write-Host ''
                        return $result
                    }

                    if ($selectedIndices.Count -eq 0) {
                        if ($AllowNone) {
                            $console::SetCursorPosition(0, $blockTop + $blockHeight)
                            Write-Host ''
                            return $null
                        }
                        $selectedIndices.Add($currentIndex) | Out-Null
                    }

                    $sortedSelection = Get-SortedIndices -Set $selectedIndices
                    if ($sortedSelection.Count -eq 0) {
                        $console::SetCursorPosition(0, $blockTop + $blockHeight)
                        Write-Host ''
                        return $null
                    }

                    $index = $sortedSelection[0]
                    if ($index -ge 0 -and $index -lt $itemList.Count) {
                        $console::SetCursorPosition(0, $blockTop + $blockHeight)
                        Write-Host ''
                        return $itemList[$index].Value
                    }
                    $console::SetCursorPosition(0, $blockTop + $blockHeight)
                    Write-Host ''
                    return $null
                }
                default { }
            }
        }
    } finally {
        $console::CursorVisible = $initialCursorVisible
        $console::SetCursorPosition(0, $blockTop + $blockHeight)
    }
}

function Read-InteractiveText {
    param(
        [string]$Prompt,
        [string]$Default = '',
        [switch]$AllowEmpty,
        [string[]]$ContextLines = @()
    )

    $console = [System.Console]
    $rawUi = $Host.UI.RawUI
    $bufferWidth = $rawUi.BufferSize.Width
    if ($bufferWidth -lt 10) {
        $bufferWidth = 120
    }

    $instructions = @(
        'Type using the keyboard.',
        'Enter confirms, Esc cancels, Backspace/Delete remove characters.'
    )

    $displayLines = $ContextLines.Count + 1 + $instructions.Count + 1
    $requiredRows = $console::CursorTop + $displayLines + 2
    Set-ConsoleCapacity -RequiredRows $requiredRows

    $blockTop = $console::CursorTop
    for ($i = 0; $i -lt $displayLines; $i++) {
        Write-Host ''
    }

    $initialCursorVisible = $console::CursorVisible
    $console::CursorVisible = $false

    $builder = New-Object System.Text.StringBuilder
    if ($Default) {
        $null = $builder.Append($Default)
    }

    try {
        while ($true) {
            $console::SetCursorPosition(0, $blockTop)

            foreach ($line in $ContextLines) {
                Write-PaddedLine -Text $line -Width $bufferWidth
            }

            Write-PaddedLine -Text $Prompt -Width $bufferWidth
            foreach ($line in $instructions) {
                Write-PaddedLine -Text $line -Width $bufferWidth
            }

            $textValue = $builder.ToString()
            $displayText = "> $textValue"
            if ($displayText.Length -gt $bufferWidth) {
                $displayText = $displayText.Substring(0, [Math]::Max($bufferWidth - 1, 0))
            }
            Write-PaddedLine -Text $displayText -Width $bufferWidth

            $cursorRow = $blockTop + $displayLines - 1
            $cursorCol = [Math]::Min($displayText.Length, [Math]::Max($bufferWidth - 1, 0))
            $console::SetCursorPosition($cursorCol, $cursorRow)

            $keyInfo = $console::ReadKey($true)
            switch ($keyInfo.Key) {
                'Enter' {
                    if (-not $AllowEmpty -and $builder.Length -eq 0) { continue }
                    $console::SetCursorPosition(0, $blockTop + $displayLines)
                    Write-Host ''
                    return $builder.ToString()
                }
                'Escape' {
                    $console::SetCursorPosition(0, $blockTop + $displayLines)
                    Write-Host ''
                    return $null
                }
                'Backspace' {
                    if ($builder.Length -gt 0) { $builder.Length = $builder.Length - 1 }
                }
                'Delete' {
                    if ($builder.Length -gt 0) { $builder.Length = $builder.Length - 1 }
                }
                default {
                    $char = $keyInfo.KeyChar
                    if ($char -and ([int][char]$char) -ge 32) {
                        if ($builder.Length -lt 128) {
                            $null = $builder.Append($char)
                        }
                    }
                }
            }
        }
    } finally {
        $console::CursorVisible = $initialCursorVisible
        $console::SetCursorPosition(0, $blockTop + $displayLines)
    }
}
function Show-ProfileSummary {
    param(
        [System.Collections.Specialized.OrderedDictionary]$Config
    )

    Write-Host "`nCurrent profiles:" -ForegroundColor Cyan
    
    # Count non-documentation profiles
    $validKeys = @($Config.Keys | Where-Object { $_ -notmatch '^_' })
    if ($validKeys.Count -eq 0) {
        Write-Host "  (no profiles defined)" -ForegroundColor Yellow
        return
    }
    
    foreach ($key in ($Config.Keys | Sort-Object {[int]::TryParse($_,[ref]$null); $_})) {
        # Skip documentation and metadata keys (starting with _)
        if ($key -match '^_') { continue }
        
        $profile = $Config[$key]
        Write-Host ("  {0}" -f (Get-ProfileDescription -Key $key -profile $profile))
    }
}

function Set-Profile {
    param(
        [string]$Key,
        [System.Collections.Specialized.OrderedDictionary]$Config,
        [object[]]$Displays,
        [string[]]$AudioDevices,
        [string[]]$Microphones
    )

    if (-not $Config.Contains($Key)) {
        $Config[$Key] = [ordered]@{
            activeDisplays  = @()
            disableDisplays = @()
            audio           = $null
            microphone      = ''
        }
    }

    $profile = $Config[$Key]
    $profile.activeDisplays = ConvertTo-DisplayReferenceArray @($profile.activeDisplays)
    $profile.disableDisplays = ConvertTo-DisplayReferenceArray @($profile.disableDisplays)
    Write-Host "`nEditing profile $Key" -ForegroundColor Cyan
    Write-Host "Current settings:" -ForegroundColor DarkGray
    $activeSummary = Format-DisplaySummary $profile.activeDisplays
    $inactiveSummary = Format-DisplaySummary $profile.disableDisplays
    $audioSummary = if ($profile.audio) { $profile.audio } else { '(none)' }
    Write-Host ("  Active displays : {0}" -f $activeSummary)
    Write-Host ("  Disable displays: {0}" -f $inactiveSummary)
    Write-Host ("  Audio device    : {0}" -f $audioSummary)
    
    $enableMicrophones = $script:Settings.enableMicrophoneManagement -eq $true
    if ($enableMicrophones) {
        $micSummary = if ($profile.microphone) { $profile.microphone } else { '(none)' }
        Write-Host ("  Microphone      : {0}" -f $micSummary)
    }

    $contextLines = @("profile $Key")

    $activeSelection = Select-DisplayReferencesMultiple -Available $Displays -Current $profile.activeDisplays -Prompt "Select displays to keep active" -Context $contextLines
    if ($script:SelectionCancelled) {
        $script:SelectionCancelled = $false
        Write-Host "Edit cancelled. Returning to main menu." -ForegroundColor Yellow
        return $false
    }

    # Filter out displays that were selected as active from the disable list
    $availableForDisable = @()
    $activeNames = @($activeSelection | ForEach-Object { Get-DisplayReferenceName $_ })
    foreach ($display in $Displays) {
        $displayName = Get-DisplayReferenceName $display
        if ($activeNames -notcontains $displayName) {
            $availableForDisable += $display
        }
    }

    # Also filter the current disable list to only include displays that are still available
    $availableDisableNames = @($availableForDisable | ForEach-Object { Get-DisplayReferenceName $_ })
    $filteredCurrentDisable = @($profile.disableDisplays | Where-Object {
        $name = Get-DisplayReferenceName $_
        $availableDisableNames -contains $name
    })

    $inactiveSelection = Select-DisplayReferencesMultiple -Available $availableForDisable -Current $filteredCurrentDisable -Prompt "Select displays to disable" -Context $contextLines
    if ($script:SelectionCancelled) {
        $script:SelectionCancelled = $false
        Write-Host "Edit cancelled. Returning to main menu." -ForegroundColor Yellow
        return $false
    }

    $audioSelection = Select-SingleItem -Items $AudioDevices -Prompt "Select default audio device" -Current $profile.audio -AllowNone -Context $contextLines
    if ($script:SelectionCancelled) {
        $script:SelectionCancelled = $false
        Write-Host "Edit cancelled. Returning to main menu." -ForegroundColor Yellow
        return $false
    }

    # Microphone selection (only if enabled in settings)
    $micSelection = $null
    if ($enableMicrophones) {
        $currentMic = if ($profile.PSObject.Properties['microphone']) { $profile.microphone } else { $null }
        $micSelection = Select-SingleItem -Items $Microphones -Prompt "Select microphone" -Current $currentMic -AllowNone -Context $contextLines
        if ($script:SelectionCancelled) {
            $script:SelectionCancelled = $false
            Write-Host "Edit cancelled. Returning to main menu." -ForegroundColor Yellow
            return $false
        }
    }

    $profile.activeDisplays  = Get-UniqueDisplayReferences -References $activeSelection
    $profile.disableDisplays = Get-UniqueDisplayReferences -References $inactiveSelection
    $profile.audio           = $audioSelection
    if ($enableMicrophones) {
        $profile.microphone  = $micSelection
    }

    $profile.activeDisplays  = Merge-DisplayReferences -References $profile.activeDisplays -Available $Displays
    $profile.disableDisplays = Merge-DisplayReferences -References $profile.disableDisplays -Available $Displays

    $Config[$Key] = $profile
    Write-Host "Updated profile $Key." -ForegroundColor Green
    return $true
}

function New-Profile {
    param(
        [System.Collections.Specialized.OrderedDictionary]$Config
    )

    $key = Get-NextProfileKey -Config $Config

    $Config[$key] = [ordered]@{
        activeDisplays  = @()
        disableDisplays = @()
        audio           = $null
        microphone      = ''
    }

    Write-Host "Added profile '$key'." -ForegroundColor Green
    return $key
}

function Optimize-ProfileKeys {
    param(
        [System.Collections.Specialized.OrderedDictionary]$Config
    )

    # Get all numeric keys and sort them
    $numericKeys = @()
    foreach ($key in $Config.Keys) {
        if ($key -match '^_') { continue }  # Skip metadata keys
        $num = 0
        if ([int]::TryParse($key, [ref]$num)) {
            $numericKeys += $num
        }
    }
    
    if ($numericKeys.Count -eq 0) { return @{} }
    
    $numericKeys = $numericKeys | Sort-Object
    
    # Check if already sequential (1, 2, 3, ...)
    $isSequential = $true
    for ($i = 0; $i -lt $numericKeys.Count; $i++) {
        if ($numericKeys[$i] -ne ($i + 1)) {
            $isSequential = $false
            break
        }
    }
    
    if ($isSequential) { return @{} }  # No renumbering needed
    
    # Build mapping of old -> new keys
    $mapping = @{}
    for ($i = 0; $i -lt $numericKeys.Count; $i++) {
        $oldKey = [string]$numericKeys[$i]
        $newKey = [string]($i + 1)
        if ($oldKey -ne $newKey) {
            $mapping[$oldKey] = $newKey
        }
    }
    
    # Apply renumbering
    $newConfig = [System.Collections.Specialized.OrderedDictionary]::new()
    
    # First, preserve metadata keys
    foreach ($key in $Config.Keys) {
        if ($key -match '^_') {
            $newConfig[$key] = $Config[$key]
        }
    }
    
    # Then add numeric keys in sorted order with new sequential numbers
    $nextIndex = 1
    foreach ($oldNum in $numericKeys) {
        $oldKey = [string]$oldNum
        $newKey = [string]$nextIndex
        $newConfig[$newKey] = $Config[$oldKey]
        $nextIndex++
    }
    
    # Replace config contents
    $Config.Clear()
    foreach ($key in $newConfig.Keys) {
        $Config[$key] = $newConfig[$key]
    }
    
    return $mapping
}

function Remove-Profile {
    param(
        [System.Collections.Specialized.OrderedDictionary]$Config
    )

    if ($Config.Keys.Count -eq 0) {
        Write-Host "No profiles to remove." -ForegroundColor Yellow
        return $false
    }

    $entries = @(Get-ProfileEntries -Config $Config)
    $context = @("Select the profile to remove.", "Press Esc to cancel.")
    $selection = Invoke-InteractiveSelection -Items $entries -Prompt "Choose a profile to remove" -CurrentValues @() -ContextLines $context
    if ($script:SelectionCancelled -or $null -eq $selection) {
        $script:SelectionCancelled = $false
        Write-Host "Removal cancelled." -ForegroundColor Yellow
        return $false
    }

    $confirmContext = @("profile: $selection")
    if (Read-YesNoResponse "Are you sure you want to delete this profile?" $false $confirmContext) {
        $Config.Remove($selection) | Out-Null
        Write-Host "Removed profile '$selection'." -ForegroundColor Green
        
        # Auto-renumber if there are gaps
        $mapping = Optimize-ProfileKeys -Config $Config
        if ($mapping.Count -gt 0) {
            Write-Host "`nAuto-renumbered profiles to be sequential:" -ForegroundColor Cyan
            foreach ($oldKey in ($mapping.Keys | Sort-Object {[int]$_})) {
                Write-Host "  profile $oldKey -> profile $($mapping[$oldKey])" -ForegroundColor Gray
            }
        }
        
        return $true
    }
    Write-Host "Did not remove profile '$selection'." -ForegroundColor Yellow
    return $false
}

# Main execution flow
if ($env:MONITOR_MANAGE_SUPPRESS_MAIN -ne '1') {
    # Check if config.json exists before loading
    $configExistedBefore = Test-Path $configPath
    
    $config = Get-ConfigData
    Initialize-DevicesSnapshot
    $devices = Get-DeviceInventory
    $availableDisplays = $devices[0]
    $availableAudio = $devices[1]
    $availableMicrophones = $devices[2]
    $script:CurrentDisplayInventory = ConvertTo-DisplayReferenceArray @($availableDisplays)

    Resolve-MissingDisplayIds -Config $config -AvailableDisplays $availableDisplays

    # Check if profiles are empty (no displays configured)
    foreach ($key in $config.Keys) {
        $profile = $config[$key]
        $activeCount = @($profile.activeDisplays | Where-Object { $_ }).Count
        $disableCount = @($profile.disableDisplays | Where-Object { $_ }).Count
        if ($activeCount -gt 0 -or $disableCount -gt 0) {
            $hasValidProfiles = $true
            break
        }
    }
    
    # Auto-generate profiles if config was just created or all profiles are empty
    if (-not $hasValidProfiles -and $availableDisplays.Count -gt 0) {
        if (-not $configExistedBefore) {
            # First run - auto-generate without prompting
            Write-Host "`nAuto-generating default profiles..." -ForegroundColor Cyan
            $config = New-DefaultProfiles -AvailableDisplays $availableDisplays -AvailableAudio $availableAudio
            if ($config.Keys.Count -gt 0) {
                Save-ConfigData -Config $config
                Write-Host "`nDefault profiles created and saved. You can edit them using the menu." -ForegroundColor Green
            }
        } else {
            # Config existed but is empty - prompt user
            Write-Host "`nAll profiles are empty." -ForegroundColor Yellow
            if (Read-YesNoResponse "Auto-generate default profiles based on detected displays?" $true) {
                $config = New-DefaultProfiles -AvailableDisplays $availableDisplays -AvailableAudio $availableAudio
                if ($config.Keys.Count -gt 0) {
                    Save-ConfigData -Config $config
                    Write-Host "`nDefault profiles created and saved. You can edit them now or continue." -ForegroundColor Green
                }
            } else {
                Write-Host "You can add profiles manually using the menu." -ForegroundColor Gray
            }
        }
    }

    $dirty = $false

    while ($true) {
        Show-ProfileSummary -Config $config

        # Build microphone status label
        $micStatus = if ($script:Settings.enableMicrophoneManagement) { "enabled" } else { "disabled" }
        $micLabel = "Toggle microphone management (currently: $micStatus)"

        $menuOptions = @(
            New-SelectionItem -Label 'Edit existing profile' -Value 'edit'
            New-SelectionItem -Label 'Add new profile' -Value 'add'
            New-SelectionItem -Label 'Remove profile' -Value 'remove'
            New-SelectionItem -Label 'Generate default profiles' -Value 'generate'
            New-SelectionItem -Label $micLabel -Value 'toggle-microphone'
            New-SelectionItem -Label 'Refresh devices snapshot' -Value 'refresh'
            New-SelectionItem -Label 'Save and exit' -Value 'save'
            New-SelectionItem -Label 'Exit without saving' -Value 'exit'
        )

        $menuContext = @('Use the arrow keys to choose an action. Press Enter to confirm, Esc to cancel and exit.')
        $selection = Invoke-InteractiveSelection -Items $menuOptions -Prompt 'Choose an option' -CurrentValues @('edit') -ContextLines $menuContext

        if ($script:SelectionCancelled -or $null -eq $selection) {
            if ($dirty -and -not (Read-YesNoResponse "Discard unsaved changes?" $false)) {
                $script:SelectionCancelled = $false
                continue
            }
            $script:SelectionCancelled = $false
            Write-Host "Exiting without saving changes." -ForegroundColor Yellow
            return
        }

        switch ($selection) {
            'edit' {
                if ($config.Keys.Count -eq 0) {
                    Write-Host "No profiles available." -ForegroundColor Yellow
                    continue
                }

                $entries = @(Get-ProfileEntries -Config $config)
                $context = @('Choose a profile to edit.', 'Press Esc to cancel.')
                $key = Invoke-InteractiveSelection -Items $entries -Prompt 'Select profile to edit' -CurrentValues @() -ContextLines $context
                if ($null -eq $key) {
                    Write-Host "Edit cancelled." -ForegroundColor Yellow
                    continue
                }

                if (Set-Profile -Key $key -Config $config -Displays $availableDisplays -AudioDevices $availableAudio -Microphones $availableMicrophones) {
                    $dirty = $true
                }
            }
            'add' {
                $addedKey = New-Profile -Config $config
                if ($addedKey) {
                    if (Set-Profile -Key $addedKey -Config $config -Displays $availableDisplays -AudioDevices $availableAudio -Microphones $availableMicrophones) {
                        $dirty = $true
                    }
                }
            }
            'remove' {
                if (Remove-Profile -Config $config) {
                    $dirty = $true
                }
            }
            'generate' {
                if ($availableDisplays.Count -eq 0) {
                    Write-Host "No displays detected. Cannot generate profiles." -ForegroundColor Yellow
                    continue
                }
                
                if ($config.Keys.Count -gt 0) {
                    Write-Host "`nWarning: This will replace all existing profiles." -ForegroundColor Yellow
                    if (-not (Read-YesNoResponse "Replace existing profiles with auto-generated defaults?" $false)) {
                        Write-Host "Generation cancelled." -ForegroundColor Yellow
                        continue
                    }
                }
                
                $config = New-DefaultProfiles -AvailableDisplays $availableDisplays -AvailableAudio $availableAudio
                $dirty = $true
                Write-Host "profiles generated. Review and save when ready." -ForegroundColor Green
            }
            'toggle-microphone' {
                $currentState = $script:Settings.enableMicrophoneManagement
                $newState = -not $currentState
                $script:Settings.enableMicrophoneManagement = $newState
                $dirty = $true
                
                $stateText = if ($newState) { "enabled" } else { "disabled" }
                Write-Host "`nMicrophone management is now $stateText." -ForegroundColor Green
                if ($newState) {
                    Write-Host "Profiles can now specify microphone devices." -ForegroundColor Gray
                } else {
                    Write-Host "Microphone settings in profiles will be ignored." -ForegroundColor Gray
                }
            }
            'refresh' {
                Invoke-DevicesSnapshotExport
                $devices = Get-DeviceInventory
                $availableDisplays = $devices[0]
                $availableAudio = $devices[1]
                $availableMicrophones = $devices[2]
                $script:CurrentDisplayInventory = ConvertTo-DisplayReferenceArray @($availableDisplays)
            }
            'save' {
                Save-ConfigData -Config $config
                return
            }
            'exit' {
                if ($dirty -and -not (Read-YesNoResponse "Discard unsaved changes?" $false)) {
                    continue
                }
                Write-Host "Exiting without saving changes." -ForegroundColor Yellow
                return
            }
            default {
                Write-Host "Unknown selection '$selection'." -ForegroundColor Red
            }
        }
    }
}




