<#
.SYNOPSIS
    Stops and disables the IIS FTP service (FTPSVC).

.NOTES
    Reboot: No
    Run with -WhatIf to see what would change without changing anything.
#>
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'
$ServiceName = 'FTPSVC'

try {
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if (-not $service) {
        Write-Output "[OK] FTP service is not installed."
        exit 0
    }

    if ($service.StartType -eq 'Disabled' -and $service.Status -eq 'Stopped') {
        Write-Output "[OK] FTP service is already stopped and disabled."
        exit 0
    }

    if ($PSCmdlet.ShouldProcess($ServiceName, 'Stop and disable service')) {
        Stop-Service -Name $ServiceName -Force
        Set-Service -Name $ServiceName -StartupType Disabled
        Write-Output "[CHANGED] FTP service stopped and disabled."
    }
    exit 0
} catch {
    Write-Output "[FAIL] FTP service: $($_.Exception.Message)"
    exit 1
}
