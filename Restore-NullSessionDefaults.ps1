<#
.SYNOPSIS
    Break-fix for Restrict-NullSessions.ps1: restores the Windows default null session settings.

.DESCRIPTION
    Restores the values Windows ships with, rather than opening anonymous access further:

    RestrictAnonymous=0             Windows default. This is the setting that usually breaks legacy
                                    systems, and resetting it alone normally fixes the issue.
    RestrictAnonymousSAM=1          Windows default. Leaving this at 1 still blocks anonymous
                                    enumeration of SAM accounts.
    EveryoneIncludesAnonymous=0     Windows default. Never set this to 1: it gives anonymous users
                                    every permission granted to Everyone.

    RestrictNullSessAccess is left at 1, which is also the Windows default.

.NOTES
    Reboot: Recommended
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
        Write-Output "[CHANGED] $Name set to $Value (was $was)."
    }
}

try {
    $Lsa = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
    Set-RegistryDword -Path $Lsa -Name 'RestrictAnonymous' -Value 0
    Set-RegistryDword -Path $Lsa -Name 'RestrictAnonymousSAM' -Value 1
    Set-RegistryDword -Path $Lsa -Name 'EveryoneIncludesAnonymous' -Value 0
    exit 0
} catch {
    Write-Output "[FAIL] Null session defaults: $($_.Exception.Message)"
    exit 1
}
