<#
.SYNOPSIS
    Disables SMBv1 on Windows desktops and servers.

.DESCRIPTION
    Removes the SMB1 feature (SMB1Protocol on desktops, FS-SMB1 on servers) and turns off
    SMBv1 in the SMB server configuration. Invoke-FleetHardening.ps1 includes this step.

.NOTES
    Reboot: Required if the SMB1 feature was removed.
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
        $feature = Get-WindowsFeature -Name FS-SMB1
        if (-not $feature -or -not $feature.Installed) {
            Write-Output "[OK] SMBv1 feature (FS-SMB1) is not installed."
        } elseif ($PSCmdlet.ShouldProcess('FS-SMB1', 'Uninstall Windows feature')) {
            $result = Uninstall-WindowsFeature -Name FS-SMB1
            if ("$($result.RestartNeeded)" -ne 'No') { $RestartNeeded = $true }
            Write-Output "[CHANGED] SMBv1 feature (FS-SMB1) removed."
        }
    } else {
        $feature = Get-WindowsOptionalFeature -Online | Where-Object FeatureName -eq 'SMB1Protocol'
        if (-not $feature -or $feature.State -notin 'Enabled', 'EnablePending') {
            Write-Output "[OK] SMBv1 feature (SMB1Protocol) is not enabled."
        } elseif ($PSCmdlet.ShouldProcess('SMB1Protocol', 'Disable Windows optional feature')) {
            $result = Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart
            if ($result.RestartNeeded) { $RestartNeeded = $true }
            Write-Output "[CHANGED] SMBv1 feature (SMB1Protocol) disabled."
        }
    }

    if (-not (Get-SmbServerConfiguration).EnableSMB1Protocol) {
        Write-Output "[OK] SMBv1 is already disabled in the SMB server configuration."
    } elseif ($PSCmdlet.ShouldProcess('SMB server', 'Disable SMBv1 protocol')) {
        Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
        Write-Output "[CHANGED] SMBv1 disabled in the SMB server configuration."
    }

    if ($RestartNeeded) { Write-Output "[ACTION] Reboot required to finish removing SMBv1." }
    exit 0
} catch {
    Write-Output "[FAIL] SMBv1: $($_.Exception.Message)"
    exit 1
}
