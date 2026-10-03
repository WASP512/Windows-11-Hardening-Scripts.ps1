<#
.SYNOPSIS
    Disables Multicast DNS (mDNS) in the Windows DNS Client to prevent mDNS spoofing.

.DESCRIPTION
    mDNS is used for local discovery of devices such as Chromecasts, AirPlay receivers and
    some network printers. Expect that discovery to stop working after this change.

.NOTES
    Reboot: Required (or restart the DNS Client service).
    Revert: Remove-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' -Name EnableMDNS
    Run with -WhatIf to see what would change without changing anything.
#>
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'

function Set-RegistryDword {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Path, [string]$Name, [int]$Value)
    $current = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
    if ($current -eq $Value) {
        Write-Output "[OK] $Name is already $Value."
        return
    }
    $was = if ($null -eq $current) { 'not set' } else { $current }
    if ($PSCmdlet.ShouldProcess("$Path\$Name", "Set to $Value (currently $was)")) {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null
        Write-Output "[CHANGED] $Name set to $Value (was $was). Reboot required."
    }
}

try {
    Set-RegistryDword -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' -Name 'EnableMDNS' -Value 0
    exit 0
} catch {
    Write-Output "[FAIL] mDNS: $($_.Exception.Message)"
    exit 1
}
