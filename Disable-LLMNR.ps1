<#
.SYNOPSIS
    Disables Link-Local Multicast Name Resolution (LLMNR) to prevent LLMNR spoofing.

.DESCRIPTION
    Tools such as Responder answer LLMNR queries to capture NTLM hashes. Disable NetBIOS
    name resolution as well (Disable-NetBIOS.ps1), because Responder uses both.

.NOTES
    Reboot: No (applies once the DNS Client service re-reads policy; a reboot guarantees it).
    Revert: Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient' -Name EnableMulticast
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
    Set-RegistryDword -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient' -Name 'EnableMulticast' -Value 0
    exit 0
} catch {
    Write-Output "[FAIL] LLMNR: $($_.Exception.Message)"
    exit 1
}
