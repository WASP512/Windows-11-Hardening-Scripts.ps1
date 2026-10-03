<#
.SYNOPSIS
    Break-fix for Enable-SMBSigning.ps1: stops requiring SMB signing.

.DESCRIPTION
    Signing stays enabled (it is still used when the other side asks for it); it is just no
    longer required. Only relax the side that is actually broken:

      Server  Inbound connections to this device fail (e.g. a copier scanning to a share here).
      Client  Connections from this device fail (e.g. mapping a drive on an old NAS).

.PARAMETER Side
    Server, Client or Both. Defaults to Both.

.NOTES
    Reboot: No
    Run with -WhatIf to see what would change without changing anything.
#>
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('Server', 'Client', 'Both')]
    [string]$Side = 'Both'
)

$ErrorActionPreference = 'Stop'

try {
    if ($Side -in 'Server', 'Both') {
        if (-not (Get-SmbServerConfiguration).RequireSecuritySignature) {
            Write-Output "[OK] SMB server does not require signing."
        } elseif ($PSCmdlet.ShouldProcess('SMB server', 'Stop requiring SMB signing')) {
            Set-SmbServerConfiguration -RequireSecuritySignature $false -Force
            Write-Output "[CHANGED] SMB server no longer requires signing."
        }
    }

    if ($Side -in 'Client', 'Both') {
        if (-not (Get-SmbClientConfiguration).RequireSecuritySignature) {
            Write-Output "[OK] SMB client does not require signing."
        } elseif ($PSCmdlet.ShouldProcess('SMB client', 'Stop requiring SMB signing')) {
            Set-SmbClientConfiguration -RequireSecuritySignature $false -Force
            Write-Output "[CHANGED] SMB client no longer requires signing."
        }
    }
    exit 0
} catch {
    Write-Output "[FAIL] SMB signing: $($_.Exception.Message)"
    exit 1
}
