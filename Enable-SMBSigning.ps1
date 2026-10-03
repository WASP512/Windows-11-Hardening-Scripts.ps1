<#
.SYNOPSIS
    Requires SMB signing for inbound (server) and outbound (client) SMB connections.

.DESCRIPTION
    Older NAS devices, copiers and scan-to-folder targets that do not support SMB signing
    will stop working. If that happens, run Disable-SMBSigning.ps1 on the affected side.
    Windows 11 24H2 and later already require signing by default.

.NOTES
    Reboot: No
    Revert: Disable-SMBSigning.ps1
    Run with -WhatIf to see what would change without changing anything.
#>
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'

try {
    $server = Get-SmbServerConfiguration
    if ($server.RequireSecuritySignature -and $server.EnableSecuritySignature) {
        Write-Output "[OK] SMB server already requires signing."
    } elseif ($PSCmdlet.ShouldProcess('SMB server', 'Require SMB signing')) {
        Set-SmbServerConfiguration -RequireSecuritySignature $true -EnableSecuritySignature $true -Force
        Write-Output "[CHANGED] SMB server now requires signing."
    }

    if ((Get-SmbClientConfiguration).RequireSecuritySignature) {
        Write-Output "[OK] SMB client already requires signing."
    } elseif ($PSCmdlet.ShouldProcess('SMB client', 'Require SMB signing')) {
        Set-SmbClientConfiguration -RequireSecuritySignature $true -Force
        Write-Output "[CHANGED] SMB client now requires signing."
    }
    exit 0
} catch {
    Write-Output "[FAIL] SMB signing: $($_.Exception.Message)"
    exit 1
}
