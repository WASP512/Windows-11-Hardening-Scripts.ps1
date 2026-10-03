<#
.SYNOPSIS
    Disables NetBIOS name resolution (NBT-NS) to prevent NBT-NS spoofing.

.DESCRIPTION
    Tools such as Responder answer NBT-NS broadcasts, as well as LLMNR, to capture NTLM
    hashes. Run this together with Disable-LLMNR.ps1.

      NetbiosOptions=2   Disables NetBIOS over TCP/IP on every existing interface.
      NodeType=2         P-node: never resolve names by broadcast. This also covers
                         adapters added after the script has run.

    Very old systems that only resolve names by NetBIOS broadcast (no DNS) will stop resolving.

.NOTES
    Reboot: Recommended (interfaces pick up NetbiosOptions when they reconnect).
    Revert: Set NetbiosOptions back to 0 on each interface and delete NodeType.
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
        Write-Output "[OK] $Path\$Name is already $Value."
        return
    }
    $was = if ($null -eq $current) { 'not set' } else { $current }
    if ($PSCmdlet.ShouldProcess("$Path\$Name", "Set to $Value (currently $was)")) {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null
        Write-Output "[CHANGED] $Path\$Name set to $Value (was $was)."
    }
}

try {
    $NetBT = 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters'
    Get-ChildItem -Path "$NetBT\Interfaces" | ForEach-Object {
        Set-RegistryDword -Path $_.PSPath -Name 'NetbiosOptions' -Value 2
    }
    Set-RegistryDword -Path $NetBT -Name 'NodeType' -Value 2
    exit 0
} catch {
    Write-Output "[FAIL] NetBIOS: $($_.Exception.Message)"
    exit 1
}
