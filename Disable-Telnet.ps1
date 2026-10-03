<#
.SYNOPSIS
    Removes the Telnet client on Windows desktops and servers.

.DESCRIPTION
    Removes TelnetClient on desktops and Telnet-Client on servers.
    Invoke-FleetHardening.ps1 includes this step.

.NOTES
    Reboot: Only if Windows reports one is needed.
    Run with -WhatIf to see what would change without changing anything.
#>
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'
$IsServer = (Get-CimInstance Win32_OperatingSystem).ProductType -ne 1
$RestartNeeded = $false

try {
    if ($IsServer) {
        $feature = Get-WindowsFeature -Name Telnet-Client
        if (-not $feature -or -not $feature.Installed) {
            Write-Output "[OK] Telnet-Client is not installed."
        } elseif ($PSCmdlet.ShouldProcess('Telnet-Client', 'Uninstall Windows feature')) {
            $result = Uninstall-WindowsFeature -Name Telnet-Client
            if ("$($result.RestartNeeded)" -ne 'No') { $RestartNeeded = $true }
            Write-Output "[CHANGED] Telnet-Client removed."
        }
    } else {
        $feature = Get-WindowsOptionalFeature -Online | Where-Object FeatureName -eq 'TelnetClient'
        if (-not $feature -or $feature.State -notin 'Enabled', 'EnablePending') {
            Write-Output "[OK] TelnetClient is not enabled."
        } elseif ($PSCmdlet.ShouldProcess('TelnetClient', 'Disable Windows optional feature')) {
            $result = Disable-WindowsOptionalFeature -Online -FeatureName TelnetClient -NoRestart
            if ($result.RestartNeeded) { $RestartNeeded = $true }
            Write-Output "[CHANGED] TelnetClient disabled."
        }
    }

    if ($RestartNeeded) { Write-Output "[ACTION] Reboot required to finish removing the Telnet client." }
    exit 0
} catch {
    Write-Output "[FAIL] Telnet: $($_.Exception.Message)"
    exit 1
}
