<#
.SYNOPSIS
    Disables anonymous authentication on an IIS FTP site and enables Basic authentication.

.DESCRIPTION
    FTP authentication is configured on the site's ftpServer settings, not under
    system.webServer (that section only applies to HTTP sites).

    Basic authentication sends credentials in cleartext unless FTPS is enforced, so the
    script also requires SSL on the control and data channels when the site has a
    certificate bound. If no certificate is bound it warns instead of enforcing SSL,
    because enforcing SSL without a certificate would stop the site accepting connections.

.PARAMETER SiteName
    Name of the FTP site in IIS. Defaults to "Default FTP Site".

.NOTES
    Reboot: No
    Run with -WhatIf to see what would change without changing anything.
#>
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$SiteName = 'Default FTP Site'
)

$ErrorActionPreference = 'Stop'

function Get-SiteSetting {
    param([string]$Name)
    $value = Get-ItemProperty -Path $SitePath -Name $Name
    # Some IIS settings come back wrapped in a ConfigurationAttribute
    if ($value.PSObject.Properties['Value']) { $value.Value } else { $value }
}

function Set-SiteSetting {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Name, $Value)
    $current = Get-SiteSetting -Name $Name
    if ("$current" -eq "$Value") {
        Write-Output "[OK] $Name is already $Value."
        return
    }
    if ($PSCmdlet.ShouldProcess("$SiteName : $Name", "Set to $Value (currently $current)")) {
        Set-ItemProperty -Path $SitePath -Name $Name -Value $Value
        Write-Output "[CHANGED] $Name set to $Value (was $current)."
    }
}

try {
    if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
        Write-Output "[OK] IIS is not installed; nothing to do."
        exit 0
    }
    Import-Module WebAdministration

    $SitePath = "IIS:\Sites\$SiteName"
    if (-not (Test-Path $SitePath)) {
        Write-Output "[OK] IIS site '$SiteName' does not exist; nothing to do."
        exit 0
    }

    Set-SiteSetting -Name 'ftpServer.security.authentication.anonymousAuthentication.enabled' -Value $false
    Set-SiteSetting -Name 'ftpServer.security.authentication.basicAuthentication.enabled' -Value $true

    $certHash = Get-SiteSetting -Name 'ftpServer.security.ssl.serverCertHash'
    if ([string]::IsNullOrWhiteSpace($certHash)) {
        Write-Output "[WARN] No SSL certificate is bound to '$SiteName'. Basic authentication sends passwords in cleartext."
        Write-Output "[WARN] Bind a certificate to the FTP site and re-run this script to enforce FTPS."
    } else {
        Set-SiteSetting -Name 'ftpServer.security.ssl.controlChannelPolicy' -Value 'SslRequire'
        Set-SiteSetting -Name 'ftpServer.security.ssl.dataChannelPolicy' -Value 'SslRequire'
    }
    exit 0
} catch {
    Write-Output "[FAIL] Anonymous FTP: $($_.Exception.Message)"
    exit 1
}
