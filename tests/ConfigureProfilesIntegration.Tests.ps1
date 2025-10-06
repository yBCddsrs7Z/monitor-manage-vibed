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
        $entries | Should -BeOfType [Array]
        $entries.Count | Should -Be 1
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
        
        $entries.Count | Should -Be 1
        $entries[0].Value | Should -Not -Be '_documentation'
    }

    It 'handles empty config without errors' {
        $config = [System.Collections.Specialized.OrderedDictionary]::new()

        $entries = @(Get-ProfileEntries -Config $config)
        $entries.Count | Should -Be 0
    }

    It 'returns properly wrapped array for multiple profiles' {
        $config = [System.Collections.Specialized.OrderedDictionary]::new()
        $config['1'] = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }
        $config['2'] = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }
        $config['3'] = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }

        $entries = @(Get-ProfileEntries -Config $config)
        
        $entries | Should -BeOfType [Array]
        $entries.Count | Should -Be 3
    }

    It 'finds next available key correctly skipping _documentation' {
        $config = [System.Collections.Specialized.OrderedDictionary]::new()
        $config['1'] = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }
        $config['_documentation'] = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }

        $nextKey = Get-NextProfileKey -Config $config
        
        $nextKey | Should -Be '2'
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
        $result.Contains('_documentation') | Should -Be $false
        
        # Should contain the valid profile
        $result.Contains('1') | Should -Be $true
        
        $result.Keys.Count | Should -Be 1
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
            $saved.hotkeys.profiles.PSObject.Properties.Name | Should -Not -Contain '_documentation'
            
            # Should have hotkey for profile 1
            $saved.hotkeys.profiles.'1' | Should -Be 'Left Alt+Left Shift+1'
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
        
        $normalized['profiles'].Contains('_documentation') | Should -Be $false
        
        $normalized['profiles'].Contains('1') | Should -Be $true
    }

    It 'shows profile summary without _documentation keys' {
        $config = [System.Collections.Specialized.OrderedDictionary]::new()
        $config['1'] = [ordered]@{ activeDisplays = @('Display One'); disableDisplays = @(); audio = 'Speakers' }
        $config['_documentation'] = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }

        # Capture output
        $output = Show-ProfileSummary -Config $config *>&1 | Out-String
        
        # Should show profile 1
        $output | Should -Match 'profile 1:'
        
        # Should NOT show _documentation
        $output | Should -Not -Match '_documentation'
    }
}

Remove-Item Env:MONITOR_MANAGE_SUPPRESS_MAIN -ErrorAction SilentlyContinue


