$env:MONITOR_MANAGE_SUPPRESS_SWITCH = '1'
$scriptPath = Join-Path $PSScriptRoot '..\scripts\switch_profile.ps1'
. $scriptPath

Describe 'Resolve-DisplayIdentifiers' {
    It 'resolves displays using names when displayId is missing' {
        $knownDisplays = @(
            [pscustomobject]@{
                DisplayId       = 101
                Name            = 'Generic Display 27'
                NormalizedName  = Get-NormalizedDisplayName -Name 'Generic Display 27'
                Active          = $true
            }
        )

        $references = @(
            [ordered]@{ name = 'Generic Display 27'; displayId = $null }
        )

        $result = Resolve-DisplayIdentifiers -References $references -KnownDisplays $knownDisplays

        $result.Ids.Length | Should -Be 1
        $result.Ids[0] | Should -Be 101
        $result.Missing.Count | Should -Be 0
    }

    It 'resolves displays using normalized names when formatting differs' {
        $knownDisplays = @(
            [pscustomobject]@{
                DisplayId       = 202
                Name            = 'Generic Display NX2'
                NormalizedName  = Get-NormalizedDisplayName -Name 'Generic Display NX2'
                Active          = $false
            }
        )

        $references = @(
            [ordered]@{ name = 'Generic Display NX2'; displayId = $null }
        )

        $result = Resolve-DisplayIdentifiers -References $references -KnownDisplays $knownDisplays

        $result.Ids.Length | Should -Be 1
        $result.Ids[0] | Should -Be 202
        $result.Missing.Count | Should -Be 0
    }

    It 'reports missing displays when not found' {
        $knownDisplays = @(
            [pscustomobject]@{
                DisplayId       = 101
                Name            = 'Display One'
                NormalizedName  = Get-NormalizedDisplayName -Name 'Display One'
                Active          = $true
            }
        )

        $references = @(
            [ordered]@{ name = 'Unknown Display'; displayId = $null }
        )

        $result = Resolve-DisplayIdentifiers -References $references -KnownDisplays $knownDisplays

        $result.Ids.Length | Should -Be 0
        $result.Missing.Count | Should -Be 1
    }
}

Describe 'ConvertTo-DisplayReferenceArray' {
    It 'returns array for single display reference' {
        $testInput = @([ordered]@{ name = 'Display One'; displayId = '101' })
        $result = @(ConvertTo-DisplayReferenceArray $testInput)

        $result | Should -BeOfType [Array]
        ($result | Measure-Object).Count | Should -Be 1
    }

    It 'returns array for multiple display references' {
        $testInput = @(
            [ordered]@{ name = 'Display One'; displayId = '101' },
            [ordered]@{ name = 'Display Two'; displayId = '202' }
        )
        $result = ConvertTo-DisplayReferenceArray $testInput

        $result | Should -BeOfType [Array]
        ($result | Measure-Object).Count | Should -Be 2
    }
}

Describe 'Get-DisplaysFromSnapshotFile' {
    It 'returns array for single display in snapshot' {
        $tempSnapshot = Join-Path $PSScriptRoot 'snapshot.single.json'
        $snapshotData = [ordered]@{
            Timestamp = (Get-Date).ToString('o')
            Displays  = @(
                [ordered]@{ Name = 'Display One'; DisplayId = '101' }
            )
        }
        $snapshotData | ConvertTo-Json -Depth 4 | Set-Content -Path $tempSnapshot -Encoding UTF8

        $result = @(Get-DisplaysFromSnapshotFile -SnapshotPath $tempSnapshot)

        $result | Should -BeOfType [Array]
        ($result | Measure-Object).Count | Should -Be 1

        Remove-Item -Path $tempSnapshot -Force
    }

    It 'returns empty array for missing snapshot file' {
        $result = @(Get-DisplaysFromSnapshotFile -SnapshotPath 'nonexistent.json')

        $result | Should -Not -BeNullOrEmpty
        ($result | Measure-Object).Count | Should -Be 0
    }
}

Describe 'Get-NormalizedDisplayName' {
    It 'normalizes display name by removing spaces and special characters' {
        $result = Get-NormalizedDisplayName 'Generic Display 27'

        $result | Should -Be 'genericdisplay27'
    }

    It 'normalizes display name with hyphens' {
        $result = Get-NormalizedDisplayName 'Display-One'

        $result | Should -Be 'displayone'
    }

    It 'returns null for empty string' {
        $result = Get-NormalizedDisplayName ''

        $result | Should -BeNullOrEmpty
    }

    It 'handles null input gracefully' {
        $result = Get-NormalizedDisplayName $null

        $result | Should -BeNullOrEmpty
    }

    It 'handles whitespace-only input' {
        $result = Get-NormalizedDisplayName '   '

        $result | Should -BeNullOrEmpty
    }

    It 'handles special characters only' {
        $result = Get-NormalizedDisplayName '---@@@___'

        $result | Should -BeNullOrEmpty
    }
}

Remove-Item Env:MONITOR_MANAGE_SUPPRESS_SWITCH -ErrorAction SilentlyContinue


