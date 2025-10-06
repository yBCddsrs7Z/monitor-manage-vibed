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

        if (($displays | Measure-Object).Count -ne 2) { throw 'Expected two display entries.' }
        if ($displays[0].name -ne 'Display One') { throw 'First display name mismatch.' }
        if ($displays[0].displayId -ne '101') { throw 'First display ID mismatch.' }
        if ($displays[1].name -ne 'Display Two') { throw 'Second display name mismatch.' }
        if ($displays[1].displayId -ne '202') { throw 'Second display ID mismatch.' }

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

        if (($displays | Measure-Object).Count -ne 1) { throw 'Expected one display entry.' }
        if ($displays -isnot [Array]) { throw 'Result should be an array even with single item.' }
        if ($displays[0].name -ne 'Display One') { throw 'Display name mismatch.' }

        Remove-Item -Path $tempSnapshot -Force
    }

    It 'returns empty arrays when snapshot is missing' {
        $script:snapshotPath = Join-Path $PSScriptRoot 'nonexistent.json'

        $displays, $audio, $microphones = Get-DeviceInventory

        if ($null -eq $displays) { throw 'Displays should not be null.' }
        if ($null -eq $audio) { throw 'Audio should not be null.' }
        if ($null -eq $microphones) { throw 'Microphones should not be null.' }
        if (($displays | Measure-Object).Count -ne 0) { throw 'Expected empty displays array.' }
        if (($audio | Measure-Object).Count -ne 0) { throw 'Expected empty audio array.' }
        if (($microphones | Measure-Object).Count -ne 0) { throw 'Expected empty microphones array.' }
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

        if (($result | Measure-Object).Count -ne 2) { throw 'Expected two merged display references.' }
        if ($result[0].name -ne 'Display One') { throw 'Merged display one name mismatch.' }
        if ($result[0].displayId -ne '101') { throw 'Merged display one ID mismatch.' }
        if ($result[1].name -ne 'Display Two') { throw 'Merged display two name mismatch.' }
        if ($result[1].displayId -ne '202') { throw 'Merged display two ID mismatch.' }
    }

    It 'merges display references with available displays' {
        $available = @(
            [ordered]@{ name = 'Display One'; displayId = '101' }
        )

        $selected = @(
            [ordered]@{ name = 'Display One'; displayId = $null }
        )

        $result = @(Merge-DisplayReferences -References $selected -Available $available)

        if (($result | Measure-Object).Count -ne 1) { throw 'Expected one merged display reference.' }
        if ($result[0].displayId -ne '101') { throw 'Display ID should be populated from available displays.' }
        if ($result[0].name -ne 'Display One') { throw 'Display name should be preserved.' }
    }

    It 'returns array even with single merged reference' {
        $available = @(
            [ordered]@{ name = 'Display One'; displayId = '101' }
        )

        $selected = @(
            [ordered]@{ name = 'Display One'; displayId = $null }
        )

        $result = @(Merge-DisplayReferences -References $selected -Available $available)

        if ($result -isnot [Array]) { throw 'Result should be an array even with single item.' }
        if (($result | Measure-Object).Count -ne 1) { throw 'Expected one merged display reference.' }
    }
}

Describe 'ConvertTo-DisplayReferenceArray' {
    It 'returns array for single item' {
        $input = @([ordered]@{ name = 'Display One'; displayId = '101' })
        $result = @(ConvertTo-DisplayReferenceArray $input)

        if ($result -isnot [Array]) { throw 'Result should be an array.' }
        if (($result | Measure-Object).Count -ne 1) { throw 'Expected one item.' }
    }

    It 'returns array for multiple items' {
        $input = @(
            [ordered]@{ name = 'Display One'; displayId = '101' },
            [ordered]@{ name = 'Display Two'; displayId = '202' }
        )
        $result = ConvertTo-DisplayReferenceArray $input

        if ($result -isnot [Array]) { throw 'Result should be an array.' }
        if (($result | Measure-Object).Count -ne 2) { throw 'Expected two items.' }
    }

    It 'returns empty array for null input' {
        $result = @(ConvertTo-DisplayReferenceArray $null)

        if ($null -eq $result) { throw 'Result should not be null.' }
        if (($result | Measure-Object).Count -ne 0) { throw 'Expected empty array.' }
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

        if ($result -isnot [Array]) { throw 'Result should be an array even with single profile.' }
        if (($result | Measure-Object).Count -ne 1) { throw 'Expected one entry.' }
    }

    It 'returns array for multiple profiles' {
        $config = [ordered]@{
            '1' = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }
            '2' = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }
            '3' = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }
        }

        $result = Get-ProfileEntries -Config $config

        if ($result -isnot [Array]) { throw 'Result should be an array.' }
        if (($result | Measure-Object).Count -ne 3) { throw 'Expected three entries.' }
    }
}

Describe 'ConvertTo-NameArray' {
    It 'returns array for single name' {
        $input = @([ordered]@{ name = 'Display One' })
        $result = @(ConvertTo-NameArray $input)

        if ($result -isnot [Array]) { throw 'Result should be an array.' }
        if (($result | Measure-Object).Count -ne 1) { throw 'Expected one name.' }
        if ($result[0] -ne 'Display One') { throw 'Name mismatch.' }
    }

    It 'filters out empty names' {
        $input = @(
            [ordered]@{ name = 'Display One' },
            [ordered]@{ name = '' },
            [ordered]@{ name = 'Display Two' }
        )
        $result = ConvertTo-NameArray $input

        if ($result -isnot [Array]) { throw 'Result should be an array.' }
        if (($result | Measure-Object).Count -ne 2) { throw 'Expected two names after filtering.' }
    }
}

Describe 'Get-UniqueDisplayReferences' {
    It 'returns array for single reference' {
        $references = @(
            [ordered]@{ name = 'Display One'; displayId = '101' }
        )

        $result = @(Get-UniqueDisplayReferences $references)

        if ($result -isnot [Array]) { throw 'Result should be an array.' }
        if ($result.Count -ne 1) { throw 'Expected one unique reference.' }
    }

    It 'removes duplicate references' {
        $references = @(
            [ordered]@{ name = 'Display One'; displayId = '101' }
            [ordered]@{ name = 'Display One'; displayId = '101' }
            [ordered]@{ name = 'Display Two'; displayId = '102' }
        )

        $result = @(Get-UniqueDisplayReferences $references)

        if ($result.Count -ne 2) { throw 'Expected two unique references after deduplication.' }
    }

    It 'handles empty array input' {
        $references = @()

        $result = @(Get-UniqueDisplayReferences $references)

        if ($result -isnot [Array]) { throw 'Result should be an array.' }
        if ($result.Count -ne 0) { throw 'Expected empty array for empty input.' }
    }

    It 'handles null input gracefully' {
        $result = @(Get-UniqueDisplayReferences $null)

        if ($result -isnot [Array]) { throw 'Result should be an array.' }
        if ($result.Count -ne 0) { throw 'Expected empty array for null input.' }
    }
}

Describe 'Optimize-ProfileKeys' {
    It 'renumbers profiles with gaps to be sequential' {
        $config = [System.Collections.Specialized.OrderedDictionary]::new()
        $config['1'] = [ordered]@{ activeDisplays = @('Display1'); disableDisplays = @(); audio = '' }
        $config['3'] = [ordered]@{ activeDisplays = @('Display3'); disableDisplays = @(); audio = '' }
        $config['5'] = [ordered]@{ activeDisplays = @('Display5'); disableDisplays = @(); audio = '' }

        $mapping = Optimize-ProfileKeys -Config $config

        if ($config.Keys.Count -ne 3) { throw 'Should still have 3 profiles.' }
        if (-not $config.Contains('1')) { throw 'Should have profile 1.' }
        if (-not $config.Contains('2')) { throw 'Should have profile 2.' }
        if (-not $config.Contains('3')) { throw 'Should have profile 3.' }
        if ($config.Contains('5')) { throw 'Should not have profile 5 anymore.' }
        
        if ($mapping['3'] -ne '2') { throw 'profile 3 should map to 2.' }
        if ($mapping['5'] -ne '3') { throw 'profile 5 should map to 3.' }
    }

    It 'preserves data when renumbering' {
        $config = [System.Collections.Specialized.OrderedDictionary]::new()
        $config['2'] = [ordered]@{ activeDisplays = @('DisplayA'); disableDisplays = @('DisplayB'); audio = 'AudioA' }
        $config['4'] = [ordered]@{ activeDisplays = @('DisplayC'); disableDisplays = @('DisplayD'); audio = 'AudioB' }

        Optimize-ProfileKeys -Config $config

        if ($config['1'].activeDisplays[0] -ne 'DisplayA') { throw 'profile 1 should have DisplayA.' }
        if ($config['1'].audio -ne 'AudioA') { throw 'profile 1 should have AudioA.' }
        if ($config['2'].activeDisplays[0] -ne 'DisplayC') { throw 'profile 2 should have DisplayC.' }
        if ($config['2'].audio -ne 'AudioB') { throw 'profile 2 should have AudioB.' }
    }

    It 'returns empty mapping when already sequential' {
        $config = [System.Collections.Specialized.OrderedDictionary]::new()
        $config['1'] = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }
        $config['2'] = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }
        $config['3'] = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }

        $mapping = Optimize-ProfileKeys -Config $config

        if ($mapping.Count -ne 0) { throw 'Should return empty mapping when already sequential.' }
    }

    It 'skips _documentation keys during renumbering' {
        $config = [System.Collections.Specialized.OrderedDictionary]::new()
        $config['1'] = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }
        $config['_documentation'] = [ordered]@{ notes = 'test' }
        $config['5'] = [ordered]@{ activeDisplays = @(); disableDisplays = @(); audio = '' }

        Optimize-ProfileKeys -Config $config

        if (-not $config.Contains('_documentation')) { throw 'Should preserve _documentation key.' }
        if (-not $config.Contains('1')) { throw 'Should have profile 1.' }
        if (-not $config.Contains('2')) { throw 'Should have profile 2.' }
        if ($config.Contains('5')) { throw 'Should not have profile 5.' }
    }
}

Remove-Item Env:MONITOR_MANAGE_SUPPRESS_MAIN -ErrorAction SilentlyContinue


