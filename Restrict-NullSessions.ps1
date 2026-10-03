<#
.SYNOPSIS
    Restricts null session (anonymous) access to SAM accounts, shares and named pipes.

.DESCRIPTION
    RestrictAnonymous=1             Blocks anonymous enumeration of accounts and shares.
    RestrictAnonymousSAM=1          Blocks anonymous enumeration of SAM accounts (Windows default).
    EveryoneIncludesAnonymous=0     Keeps anonymous users out of the Everyone group (Windows default).
    RestrictNullSessAccess=1        Blocks null session access to shares and pipes (Windows default).

    RestrictAnonymous=1 can break legacy systems that enumerate shares or accounts anonymously.
    If that happens, run Restore-NullSessionDefaults.ps1.

.NOTES
    Reboot: Recommended
    Revert: Restore-NullSessionDefaults.ps1
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
    Set-RegistryDword -Path $Lsa -Name 'RestrictAnonymous' -Value 1
    Set-RegistryDword -Path $Lsa -Name 'RestrictAnonymousSAM' -Value 1
    Set-RegistryDword -Path $Lsa -Name 'EveryoneIncludesAnonymous' -Value 0
    Set-RegistryDword -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -Name 'RestrictNullSessAccess' -Value 1
    exit 0
} catch {
    Write-Output "[FAIL] Null sessions: $($_.Exception.Message)"
    exit 1
}
