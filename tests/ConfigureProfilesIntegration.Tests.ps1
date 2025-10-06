$env:MONITOR_MANAGE_SUPPRESS_MAIN = '1'
$scriptPath = Join-Path $PSScriptRoot '..\scripts\configure_profiles.ps1'
. $scriptPath

Describe 'Configure profiles Integration Tests' {
    It 'handles single profile without array unwrapping error' {
        $config = [System.Collections.Specialized.OrderedDictionary]::new()
        $config['1'] = [ordered]@{
            activeDisplays = @('Display One')
            disableDisplays = @()
            audio = 'Speakers'
        }

        # This should not throw a parameter transformation error
        $entries = @(Get-ProfileEntries -Config $config)
        if ($entries -isnot [Array]) { throw 'Should return array even with single item.' }
        if ($entries.Count -ne 1) { throw 'Should have exactly one entry.' }
    }

    It 'filters out _documentation keys from profile entries' {
        $config = [System.Collections.Specialized.OrderedDictionary]::new()
        $config['1'] = [ordered]@{
            activeDisplays = @('Display One')
            disableDisplays = @()
            audio = 'Speakers'
        }
        $config['_documentation'] = [ordered]@{
            activeDisplays = @()
            disableDisplays = @()
            audio = ''
        }

        $entries = @(Get-ProfileEntries -Config $config)
        
        if ($entries.Count -ne 1) { throw 'Should filter out _documentation key, leaving only 1 entry.' }
        if ($entries[0].Value -eq '_documentation') { throw '_documentation should be filtered out.' }
    }

    It 'handles empty config without errors' {
        $config = [System.Collections.Specialized.OrderedDictionary]::new()

        $entries = @(Get-ProfileEntries -Config $config)
        if ($entries.Count -ne 0) { throw 'Empty config should return empty array.' }
    }

    It 'returns properly wrapped array for multiple profiles' {
        $config = [System.Collections.Specialized.OrderedDictionary]::new()
        $config['1'] = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }
        $config['2'] = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }
        $config['3'] = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }

        $entries = @(Get-ProfileEntries -Config $config)
        
        if ($entries -isnot [Array]) { throw 'Should return array.' }
        if ($entries.Count -ne 3) { throw 'Should have 3 entries.' }
    }

    It 'finds next available key correctly skipping _documentation' {
        $config = [System.Collections.Specialized.OrderedDictionary]::new()
        $config['1'] = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }
        $config['_documentation'] = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }

        $nextKey = Get-NextProfileKey -Config $config
        
        if ($nextKey -ne '2') { throw "Next key should be '2', not '$nextKey'." }
    }

    It 'filters _documentation when converting profile source' {
        # Simulate what happens during config loading
        $profilesource = [ordered]@{
            '1' = [ordered]@{
                activeDisplays = @('Display One')
                disableDisplays = @()
                audio = 'Speakers'
            }
            '_documentation' = [ordered]@{
                description = 'This is documentation'
            }
        }
        
        # Manually apply the same filtering logic that's in Get-ConfigData (lines 286-296)
        $result = [System.Collections.Specialized.OrderedDictionary]::new()
        foreach ($key in $profilesource.Keys) {
            # Skip documentation and metadata keys (starting with _)
            if ($key -match '^_') { continue }
            
            $profileValue = $profilesource[$key]
            $result[$key] = [ordered]@{
                activeDisplays  = ConvertTo-DisplayReferenceArray @($profileValue.activeDisplays)
                disableDisplays = ConvertTo-DisplayReferenceArray @($profileValue.disableDisplays)
                audio           = $profileValue.audio
            }
        }
        
        # Should not contain _documentation key
        if ($result.Contains('_documentation')) {
            throw 'Result should not contain _documentation key.'
        }
        
        # Should contain the valid profile
        if (-not $result.Contains('1')) {
            throw 'Result should contain profile 1.'
        }
        
        if ($result.Keys.Count -ne 1) {
            throw "Should have exactly 1 profile, not $($result.Keys.Count)."
        }
    }

    It 'saves config without creating hotkeys for _documentation' {
        $config = [System.Collections.Specialized.OrderedDictionary]::new()
        $config['1'] = [ordered]@{
            activeDisplays = @('Display One')
            disableDisplays = @()
            audio = 'Speakers'
        }
        
        $tempConfig = Join-Path $PSScriptRoot 'test-save-config.json'
        $script:configPath = $tempConfig
        $script:HotkeySettings = Get-DefaultHotkeys
        $script:OverlaySettings = Get-DefaultOverlay
        
        try {
            Save-ConfigData -Config $config
            
            $saved = Get-Content -Path $tempConfig -Raw | ConvertFrom-Json
            
            # Check that hotkeys.profiles doesn't have _documentation
            if ($saved.hotkeys.profiles.PSObject.Properties.Name -contains '_documentation') {
                throw 'Saved config should not have hotkey for _documentation.'
            }
            
            # Should have hotkey for profile 1
            if ($saved.hotkeys.profiles.'1' -ne 'Left Alt+Left Shift+1') {
                throw 'Should have correct hotkey for profile 1.'
            }
        } finally {
            Remove-Item -Path $tempConfig -Force -ErrorAction SilentlyContinue
        }
    }

    It 'handles _documentation in hotkeys.profiles and removes it' {
        $hotkeys = [ordered]@{
            profiles = [ordered]@{
                '1' = 'Left Alt+Left Shift+1'
                '_documentation' = 'This should be removed'
            }
            enableAll = 'Left Alt+Left Shift+8'
            openConfigurator = 'Left Alt+Left Shift+9'
            toggleOverlay = 'Left Alt+Left Shift+0'
        }
        
        $normalized = Set-HotkeyProfileDefaults -Hotkeys $hotkeys
        
        if ($normalized['profiles'].Contains('_documentation')) {
            throw 'Normalized hotkeys should not contain _documentation in profiles.'
        }
        
        if (-not $normalized['profiles'].Contains('1')) {
            throw 'Normalized hotkeys should still contain profile 1.'
        }
    }

    It 'shows profile summary without _documentation keys' {
        $config = [System.Collections.Specialized.OrderedDictionary]::new()
        $config['1'] = [ordered]@{ activeDisplays = @('Display One'); disableDisplays = @(); audio = 'Speakers' }
        $config['_documentation'] = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }

        # Capture output
        $output = Show-ProfileSummary -Config $config *>&1 | Out-String
        
        # Should show profile 1
        if ($output -notmatch 'profile 1:') {
            throw 'Summary should show profile 1.'
        }
        
        # Should NOT show _documentation
        if ($output -match '_documentation') {
            throw 'Summary should not show _documentation.'
        }
    }
}

Remove-Item Env:MONITOR_MANAGE_SUPPRESS_MAIN -ErrorAction SilentlyContinue


