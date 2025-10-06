$scriptPath = Join-Path $PSScriptRoot '..\scripts\Validate-Config.ps1'

# Source the entire validation script to get the function
# We'll override the main execution by checking if we're in test mode
$env:MONITOR_MANAGE_VALIDATION_TEST_MODE = '1'
. $scriptPath
Remove-Item Env:MONITOR_MANAGE_VALIDATION_TEST_MODE -ErrorAction SilentlyContinue

Describe 'Test-ConfigStructure' {
    BeforeAll {
        $script:testDir = Join-Path $PSScriptRoot 'config-validation-tests'
        if (-not (Test-Path $script:testDir)) {
            New-Item -ItemType Directory -Path $script:testDir -Force | Out-Null
        }
    }

    AfterAll {
        if (Test-Path $script:testDir) {
            Remove-Item -Path $script:testDir -Recurse -Force
        }
    }

    It 'returns false for non-existent config file' {
        $result = Test-ConfigStructure -ConfigPath 'nonexistent.json'
        
        $result.IsValid | Should -Be $false
        $result.Errors.Count | Should -BeGreaterThan 0
    }

    It 'returns false for invalid JSON' {
        $testFile = Join-Path $script:testDir 'invalid.json'
        Set-Content -Path $testFile -Value '{ invalid json }'
        
        $result = Test-ConfigStructure -ConfigPath $testFile
        
        $result.IsValid | Should -Be $false
        $result.Errors.Count | Should -BeGreaterThan 0
    }

    It 'returns false for missing required top-level keys' {
        $testFile = Join-Path $script:testDir 'missing-keys.json'
        $config = @{
            profiles = @{}
        } | ConvertTo-Json
        Set-Content -Path $testFile -Value $config
        
        $result = Test-ConfigStructure -ConfigPath $testFile
        
        $result.IsValid | Should -Be $false
        $result.Errors.Count | Should -BeGreaterOrEqual 2
    }

    It 'returns true for valid minimal config' {
        $testFile = Join-Path $script:testDir 'valid-minimal.json'
        $config = @{
            profiles = @{
                '1' = @{
                    activeDisplays = @()
                    disableDisplays = @()
                    audio = ''
                }
            }
            hotkeys = @{
                enableAll = 'Alt+Shift+8'
                profiles = @{
                    '1' = 'Alt+Shift+1'
                }
                openConfigurator = 'Alt+Shift+9'
                toggleOverlay = 'Alt+Shift+0'
            }
            overlay = @{
                fontName = 'Segoe UI'
                fontSize = 16
                fontBold = 1
                backgroundColor = 'Black'
                textColor = 'White'
                opacity = 220
                position = 'top-left'
                marginX = 10
                marginY = 10
                durationMs = 10000
            }
        } | ConvertTo-Json -Depth 4
        Set-Content -Path $testFile -Value $config
        
        $result = Test-ConfigStructure -ConfigPath $testFile
        
        $result.IsValid | Should -Be $true
    }

    It 'detects invalid profile structure' {
        $testFile = Join-Path $script:testDir 'invalid-profile.json'
        $config = @{
            profiles = @{
                '1' = @{
                    activeDisplays = @()
                    # Missing disableDisplays and audio
                }
            }
            hotkeys = @{
                enableAll = 'Alt+Shift+8'
                profiles = @{ '1' = 'Alt+Shift+1' }
                openConfigurator = 'Alt+Shift+9'
                toggleOverlay = 'Alt+Shift+0'
            }
            overlay = @{
                fontName = 'Segoe UI'
                fontSize = 16
                fontBold = 1
                backgroundColor = 'Black'
                textColor = 'White'
                opacity = 220
                position = 'top-left'
                marginX = 10
                marginY = 10
                durationMs = 10000
            }
        } | ConvertTo-Json -Depth 4
        Set-Content -Path $testFile -Value $config
        
        $result = Test-ConfigStructure -ConfigPath $testFile
        
        $result.IsValid | Should -Be $false
        $result.Errors.Count | Should -BeGreaterOrEqual 2
    }

    It 'detects invalid overlay opacity' {
        $testFile = Join-Path $script:testDir 'invalid-opacity.json'
        $config = @{
            profiles = @{
                '1' = @{
                    activeDisplays = @()
                    disableDisplays = @()
                    audio = ''
                }
            }
            hotkeys = @{
                enableAll = 'Alt+Shift+8'
                profiles = @{ '1' = 'Alt+Shift+1' }
                openConfigurator = 'Alt+Shift+9'
                toggleOverlay = 'Alt+Shift+0'
            }
            overlay = @{
                fontName = 'Segoe UI'
                fontSize = 16
                fontBold = 1
                backgroundColor = 'Black'
                textColor = 'White'
                opacity = 300  # Invalid: > 255
                position = 'top-left'
                marginX = 10
                marginY = 10
                durationMs = 10000
            }
        } | ConvertTo-Json -Depth 4
        Set-Content -Path $testFile -Value $config
        
        $result = Test-ConfigStructure -ConfigPath $testFile
        
        $result.IsValid | Should -Be $false
    }

    It 'detects invalid overlay position' {
        $testFile = Join-Path $script:testDir 'invalid-position.json'
        $config = @{
            profiles = @{
                '1' = @{
                    activeDisplays = @()
                    disableDisplays = @()
                    audio = ''
                }
            }
            hotkeys = @{
                enableAll = 'Alt+Shift+8'
                profiles = @{ '1' = 'Alt+Shift+1' }
                openConfigurator = 'Alt+Shift+9'
                toggleOverlay = 'Alt+Shift+0'
            }
            overlay = @{
                fontName = 'Segoe UI'
                fontSize = 16
                fontBold = 1
                backgroundColor = 'Black'
                textColor = 'White'
                opacity = 220
                position = 'invalid-position'
                marginX = 10
                marginY = 10
                durationMs = 10000
            }
        } | ConvertTo-Json -Depth 4
        Set-Content -Path $testFile -Value $config
        
        $result = Test-ConfigStructure -ConfigPath $testFile
        
        $result.IsValid | Should -Be $false
    }
}


