$env:MONITOR_MANAGE_SUPPRESS_MAIN = '1'
$scriptPath = Join-Path $PSScriptRoot '..\scripts\configure_profiles.ps1'
. $scriptPath

Describe 'Get-DeviceInventory' {
    It 'returns display entries with displayId values when snapshot provides them' {
        $tempSnapshot = Join-Path $PSScriptRoot 'devices_snapshot.test.json'
        $snapshotData = [ordered]@{
            Timestamp = (Get-Date).ToString('o')
            Displays  = @(
                [ordered]@{ Name = 'Display One'; DisplayId = '101' },
                [ordered]@{ Name = 'Display Two'; DisplayId = '202' }
            )
            AudioDevices = @('Generic Speakers (USB Audio)')
        }
        $snapshotData | ConvertTo-Json -Depth 4 | Set-Content -Path $tempSnapshot -Encoding UTF8

        $script:snapshotPath = $tempSnapshot

        $displays, $audio = Get-DeviceInventory

        ($displays | Measure-Object).Count | Should -Be 2
        $displays[0].name | Should -Be 'Display One'
        $displays[0].displayId | Should -Be '101'
        $displays[1].name | Should -Be 'Display Two'
        $displays[1].displayId | Should -Be '202'

        Remove-Item -Path $tempSnapshot -Force
    }

    It 'handles single display without unwrapping array' {
        $tempSnapshot = Join-Path $PSScriptRoot 'devices_snapshot.single.json'
        $snapshotData = [ordered]@{
            Timestamp = (Get-Date).ToString('o')
            Displays  = @(
                [ordered]@{ Name = 'Display One'; DisplayId = '101' }
            )
            AudioDevices = @('Speakers')
        }
        $snapshotData | ConvertTo-Json -Depth 4 | Set-Content -Path $tempSnapshot -Encoding UTF8

        $script:snapshotPath = $tempSnapshot

        $displays, $audio = Get-DeviceInventory

        ($displays | Measure-Object).Count | Should -Be 1
        $displays | Should -BeOfType [Array]
        $displays[0].name | Should -Be 'Display One'

        Remove-Item -Path $tempSnapshot -Force
    }

    It 'returns empty arrays when snapshot is missing' {
        $script:snapshotPath = Join-Path $PSScriptRoot 'nonexistent.json'

        $displays, $audio, $microphones = Get-DeviceInventory

        $displays | Should -Not -BeNullOrEmpty
        $audio | Should -Not -BeNullOrEmpty
        $microphones | Should -Not -BeNullOrEmpty
        ($displays | Measure-Object).Count | Should -Be 0
        ($audio | Measure-Object).Count | Should -Be 0
        ($microphones | Measure-Object).Count | Should -Be 0
    }
}

Describe 'Merge-DisplayReferences' {
    It 'populates missing displayId values using available display list' {
        $available = @(
            [ordered]@{ name = 'Display One'; displayId = '101' },
            [ordered]@{ name = 'Display Two'; displayId = '202' }
        )

        $selected = @(
            [ordered]@{ name = 'Display One'; displayId = $null },
            [ordered]@{ name = 'Display Two'; displayId = $null }
        )

        $result = Merge-DisplayReferences -References $selected -Available $available

        ($result | Measure-Object).Count | Should -Be 2
        $result[0].name | Should -Be 'Display One'
        $result[0].displayId | Should -Be '101'
        $result[1].name | Should -Be 'Display Two'
        $result[1].displayId | Should -Be '202'
    }

    It 'merges display references with available displays' {
        $available = @(
            [ordered]@{ name = 'Display One'; displayId = '101' }
        )

        $selected = @(
            [ordered]@{ name = 'Display One'; displayId = $null }
        )

        $result = @(Merge-DisplayReferences -References $selected -Available $available)

        ($result | Measure-Object).Count | Should -Be 1
        $result[0].displayId | Should -Be '101'
        $result[0].name | Should -Be 'Display One'
    }

    It 'returns array even with single merged reference' {
        $available = @(
            [ordered]@{ name = 'Display One'; displayId = '101' }
        )

        $selected = @(
            [ordered]@{ name = 'Display One'; displayId = $null }
        )

        $result = @(Merge-DisplayReferences -References $selected -Available $available)

        $result | Should -BeOfType [Array]
        ($result | Measure-Object).Count | Should -Be 1
    }
}

Describe 'ConvertTo-DisplayReferenceArray' {
    It 'returns array for single item' {
        $testInput = @([ordered]@{ name = 'Display One'; displayId = '101' })
        $result = @(ConvertTo-DisplayReferenceArray $testInput)

        $result | Should -BeOfType [Array]
        ($result | Measure-Object).Count | Should -Be 1
    }

    It 'returns array for multiple items' {
        $testInput = @(
            [ordered]@{ name = 'Display One'; displayId = '101' },
            [ordered]@{ name = 'Display Two'; displayId = '202' }
        )
        $result = ConvertTo-DisplayReferenceArray $testInput

        $result | Should -BeOfType [Array]
        ($result | Measure-Object).Count | Should -Be 2
    }

    It 'returns empty array for null input' {
        $result = @(ConvertTo-DisplayReferenceArray $null)

        $result | Should -Not -BeNullOrEmpty
        ($result | Measure-Object).Count | Should -Be 0
    }
}

Describe 'Get-ProfileEntries' {
    It 'returns array for single profile' {
        $config = [ordered]@{
            '1' = [ordered]@{
                activeDisplays = @('Display One')
                disableDisplays = @()
                audio = 'Speakers'
            }
        }

        $result = @(Get-ProfileEntries -Config $config)

        $result | Should -BeOfType [Array]
        ($result | Measure-Object).Count | Should -Be 1
    }

    It 'returns array for multiple profiles' {
        $config = [ordered]@{
            '1' = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }
            '2' = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }
            '3' = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }
        }

        $result = Get-ProfileEntries -Config $config

        $result | Should -BeOfType [Array]
        ($result | Measure-Object).Count | Should -Be 3
    }
}

Describe 'ConvertTo-NameArray' {
    It 'returns array for single name' {
        $testInput = @([ordered]@{ name = 'Display One' })
        $result = @(ConvertTo-NameArray $testInput)

        $result | Should -BeOfType [Array]
        ($result | Measure-Object).Count | Should -Be 1
        $result[0] | Should -Be 'Display One'
    }

    It 'filters out empty names' {
        $testInput = @(
            [ordered]@{ name = 'Display One' },
            [ordered]@{ name = '' },
            [ordered]@{ name = 'Display Two' }
        )
        $result = ConvertTo-NameArray $testInput

        $result | Should -BeOfType [Array]
        ($result | Measure-Object).Count | Should -Be 2
    }
}

Describe 'Get-UniqueDisplayReferences' {
    It 'returns array for single reference' {
        $references = @(
            [ordered]@{ name = 'Display One'; displayId = '101' }
        )

        $result = @(Get-UniqueDisplayReferences $references)

        $result | Should -BeOfType [Array]
        $result.Count | Should -Be 1
    }

    It 'removes duplicate references' {
        $references = @(
            [ordered]@{ name = 'Display One'; displayId = '101' }
            [ordered]@{ name = 'Display One'; displayId = '101' }
            [ordered]@{ name = 'Display Two'; displayId = '102' }
        )

        $result = @(Get-UniqueDisplayReferences $references)

        $result.Count | Should -Be 2
    }

    It 'handles empty array input' {
        $references = @()

        $result = @(Get-UniqueDisplayReferences $references)

        $result | Should -BeOfType [Array]
        $result.Count | Should -Be 0
    }

    It 'handles null input gracefully' {
        $result = @(Get-UniqueDisplayReferences $null)

        $result | Should -BeOfType [Array]
        $result.Count | Should -Be 0
    }
}

Describe 'Optimize-ProfileKeys' {
    It 'renumbers profiles with gaps to be sequential' {
        $config = [System.Collections.Specialized.OrderedDictionary]::new()
        $config['1'] = [ordered]@{ activeDisplays = @('Display1'); disableDisplays = @(); audio = '' }
        $config['3'] = [ordered]@{ activeDisplays = @('Display3'); disableDisplays = @(); audio = '' }
        $config['5'] = [ordered]@{ activeDisplays = @('Display5'); disableDisplays = @(); audio = '' }

        $mapping = Optimize-ProfileKeys -Config $config

        $config.Keys.Count | Should -Be 3
        $config.Contains('1') | Should -Be $true
        $config.Contains('2') | Should -Be $true
        $config.Contains('3') | Should -Be $true
        $config.Contains('5') | Should -Be $false
        
        $mapping['3'] | Should -Be '2'
        $mapping['5'] | Should -Be '3'
    }

    It 'preserves data when renumbering' {
        $config = [System.Collections.Specialized.OrderedDictionary]::new()
        $config['2'] = [ordered]@{ activeDisplays = @('DisplayA'); disableDisplays = @('DisplayB'); audio = 'AudioA' }
        $config['4'] = [ordered]@{ activeDisplays = @('DisplayC'); disableDisplays = @('DisplayD'); audio = 'AudioB' }

        Optimize-ProfileKeys -Config $config

        $config['1'].activeDisplays[0] | Should -Be 'DisplayA'
        $config['1'].audio | Should -Be 'AudioA'
        $config['2'].activeDisplays[0] | Should -Be 'DisplayC'
        $config['2'].audio | Should -Be 'AudioB'
    }

    It 'returns empty mapping when already sequential' {
        $config = [System.Collections.Specialized.OrderedDictionary]::new()
        $config['1'] = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }
        $config['2'] = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }
        $config['3'] = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }

        $mapping = Optimize-ProfileKeys -Config $config

        $mapping.Count | Should -Be 0
    }

    It 'skips _documentation keys during renumbering' {
        $config = [System.Collections.Specialized.OrderedDictionary]::new()
        $config['1'] = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }
        $config['_documentation'] = [ordered]@{ notes = 'test' }
        $config['5'] = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }

        Optimize-ProfileKeys -Config $config

        $config.Contains('_documentation') | Should -Be $true
        $config.Contains('1') | Should -Be $true
        $config.Contains('2') | Should -Be $true
        $config.Contains('5') | Should -Be $false
    }
}

Remove-Item Env:MONITOR_MANAGE_SUPPRESS_MAIN -ErrorAction SilentlyContinue


