#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Cycles to the next available audio output device.

.DESCRIPTION
    Gets all playback audio devices, finds the current default, and switches
    to the next one in the list. Wraps around to the first device after the last.
    Outputs the name of the newly selected device.

.EXAMPLE
    .\cycle_audio.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$repoRoot = Split-Path -Path $scriptDir -Parent
$logPath = Join-Path $repoRoot 'monitor-toggle.log'

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logLine = "[$timestamp] [$Level] $Message"
    try {
        Add-Content -Path $logPath -Value $logLine -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {
        # Silently ignore logging errors
    }
}

function Import-LatestModule {
    param([Parameter(Mandatory = $true)][string]$Name)

    $candidate = Get-Module -ListAvailable -Name $Name | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $candidate) {
        Write-Log -Message "Module '$Name' not found. Prompting user for installation." -Level 'WARN'
        $message = "Required module '$Name' is not installed. Install for the current user now?"
        $response = $Host.UI.PromptForChoice("Install Module", $message, @('&Yes','&No'), 0)
        if ($response -ne 0) {
            throw "Module '$Name' is required but was not installed."
        }
        try {
            Write-Log -Message "Installing module '$Name' for CurrentUser scope." -Level 'INFO'
            Write-Host "Module '$Name' not found. Attempting installation (CurrentUser scope)..."
            if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
                Install-PackageProvider -Name NuGet -Scope CurrentUser -Force -Confirm:$false -ErrorAction Stop | Out-null
            }
            if (-not (Get-PSRepository -Name 'PSGallery' -ErrorAction SilentlyContinue)) {
                Register-PSRepository -Default -ErrorAction Stop
            }
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction Stop
            Install-Module -Name $Name -Scope CurrentUser -Force -AllowClobber -Confirm:$false -ErrorAction Stop
            $candidate = Get-Module -ListAvailable -Name $Name | Sort-Object Version -Descending | Select-Object -First 1
        } catch {
            throw "Module '$Name' is not installed and automatic installation failed: $_"
        }
        if (-not $candidate) {
            throw "Module '$Name' remains unavailable after installation attempt."
        }
        Write-Log -Message "Module '$Name' installed successfully (version $($candidate.Version))."
    } else {
        Write-Log -Message "Module '$Name' available (latest version $($candidate.Version))."
    }

    $loaded = Get-Module -Name $candidate.Name | Where-Object { $_.Version -eq $candidate.Version }
    if (-not $loaded) {
        Import-Module -Name $candidate.Name -RequiredVersion $candidate.Version -ErrorAction Stop | Out-Null
        Write-Log -Message "Module '$Name' version $($candidate.Version) imported."
    }
}

# Main execution
Write-Log -Message "Audio cycle requested."

try {
    Import-LatestModule -Name 'AudioDeviceCmdlets'
} catch {
    $message = "Failed to import AudioDeviceCmdlets module: $_"
    Write-Error $message
    Write-Log -Message $message -Level 'ERROR'
    exit 1
}

try {
    # Get all playback devices
    $devices = Get-AudioDevice -List | Where-Object { $_.Type -eq 'Playback' }
    
    if ($devices.Count -eq 0) {
        Write-Log -Message "No playback audio devices found." -Level 'ERROR'
        Write-Error "No playback audio devices found."
        exit 1
    }
    
    if ($devices.Count -eq 1) {
        # Only one device - just output its name
        $deviceName = if ($devices[0].FriendlyName) { $devices[0].FriendlyName } else { $devices[0].Name }
        Write-Log -Message "Only one audio device available: $deviceName"
        Write-Output $deviceName
        exit 0
    }
    
    # Find current default device
    $currentDefault = Get-AudioDevice -Playback
    
    # Find index of current device in the list
    $currentIndex = -1
    for ($i = 0; $i -lt $devices.Count; $i++) {
        if ($devices[$i].ID -eq $currentDefault.ID) {
            $currentIndex = $i
            break
        }
    }
    
    # Calculate next index (wrap around)
    $nextIndex = ($currentIndex + 1) % $devices.Count
    $nextDevice = $devices[$nextIndex]
    
    # Set the next device as default
    Set-AudioDevice -ID $nextDevice.ID
    
    $deviceName = if ($nextDevice.FriendlyName) { $nextDevice.FriendlyName } else { $nextDevice.Name }
    Write-Log -Message "Switched audio to: $deviceName"
    
    # Output the device name for AHK to display
    Write-Output $deviceName
    
} catch {
    $message = "Failed to cycle audio device: $_"
    Write-Error $message
    Write-Log -Message $message -Level 'ERROR'
    exit 1
}

exit 0

