<#
.SYNOPSIS
    Fleet hardening: removes Telnet, SMBv1 and the PowerShell v2 engine, then audits legacy ports.

.DESCRIPTION
    Built for Datto RMM (runs as SYSTEM) or manual execution as Administrator.

    Exit codes:
      0  Every step succeeded (check the output for [ACTION] and [ALERT] lines).
      1  At least one step failed, see the [FAIL] lines.

.NOTES
    Reboot: Required if any feature was removed; the script prints [ACTION] Reboot required.
    Run with -WhatIf to audit without changing anything.
#>
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'

$OS = Get-CimInstance Win32_OperatingSystem
$IsServer = $OS.ProductType -ne 1    # 1 = workstation, 2 = domain controller, 3 = server
$script:Failures = 0
$script:RestartNeeded = $false
$script:OptionalFeatures = $null

function Disable-LegacyFeature {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Label,
        [string]$ServerFeature,
        [string]$DesktopFeature
    )
    Write-Output "`n[$Label]"
    try {
        if ($IsServer) {
            $feature = Get-WindowsFeature -Name $ServerFeature
            if (-not $feature -or -not $feature.Installed) {
                Write-Output "[OK] $ServerFeature is not installed."
                return
            }
            if ($PSCmdlet.ShouldProcess($ServerFeature, 'Uninstall Windows feature')) {
                $result = Uninstall-WindowsFeature -Name $ServerFeature
                if ("$($result.RestartNeeded)" -ne 'No') { $script:RestartNeeded = $true }
                Write-Output "[CHANGED] $ServerFeature removed."
            }
        } else {
            # Query the full list once: asking for a feature that does not exist on this
            # build (e.g. PowerShell v2 on Windows 11 24H2) throws instead of returning nothing.
            if (-not $script:OptionalFeatures) {
                $script:OptionalFeatures = Get-WindowsOptionalFeature -Online
            }
            $feature = $script:OptionalFeatures | Where-Object FeatureName -eq $DesktopFeature
            if (-not $feature -or $feature.State -notin 'Enabled', 'EnablePending') {
                Write-Output "[OK] $DesktopFeature is not enabled."
                return
            }
            if ($PSCmdlet.ShouldProcess($DesktopFeature, 'Disable Windows optional feature')) {
                $result = Disable-WindowsOptionalFeature -Online -FeatureName $DesktopFeature -NoRestart
                if ($result.RestartNeeded) { $script:RestartNeeded = $true }
                Write-Output "[CHANGED] $DesktopFeature disabled."
            }
        }
    } catch {
        $script:Failures++
        Write-Output "[FAIL] ${Label}: $($_.Exception.Message)"
    }
}

Write-Output "============================================"
Write-Output "Hardening: $env:COMPUTERNAME ($($OS.Caption))"
Write-Output "============================================"

# --- 1. Telnet client --------------------------------------------------------
Disable-LegacyFeature -Label 'TELNET' -ServerFeature 'Telnet-Client' -DesktopFeature 'TelnetClient'

# --- 2. SMBv1 ----------------------------------------------------------------
Disable-LegacyFeature -Label 'SMBv1' -ServerFeature 'FS-SMB1' -DesktopFeature 'SMB1Protocol'
try {
    # Also turn SMBv1 off in the server configuration, whatever the feature state
    if (-not (Get-SmbServerConfiguration).EnableSMB1Protocol) {
        Write-Output "[OK] SMBv1 is disabled in the SMB server configuration."
    } elseif ($PSCmdlet.ShouldProcess('SMB server', 'Disable SMBv1 protocol')) {
        Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
        Write-Output "[CHANGED] SMBv1 disabled in the SMB server configuration."
    }
} catch {
    $script:Failures++
    Write-Output "[FAIL] SMBv1 server configuration: $($_.Exception.Message)"
}

# --- 3. Legacy PowerShell v2 engine ------------------------------------------
Disable-LegacyFeature -Label 'PowerShell v2 Engine' -ServerFeature 'PowerShell-V2' -DesktopFeature 'MicrosoftWindowsPowerShellV2Root'

# --- 4. Port audit -----------------------------------------------------------
# 21 (FTP) and 23 (Telnet) should never be listening. 445 is normal for SMB2/3,
# so it is reported for information only.
Write-Output "`n[Port Audit]"
try {
    foreach ($port in 21, 23, 445) {
        $listeners = @(Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue)
        if (-not $listeners) {
            Write-Output "[OK] Port $port is not listening."
            continue
        }
        $processes = $listeners.OwningProcess | Sort-Object -Unique | ForEach-Object {
            $name = (Get-Process -Id $_ -ErrorAction SilentlyContinue).ProcessName
            "$name (PID $_)"
        }
        if ($port -eq 445) {
            Write-Output "[INFO] Port 445 is listening (SMB2/3, expected): $($processes -join ', ')"
        } else {
            Write-Output "[ALERT] Port $port is LISTENING: $($processes -join ', ')"
        }
    }
} catch {
    $script:Failures++
    Write-Output "[FAIL] Port audit: $($_.Exception.Message)"
}

Write-Output "`n============================================"
if ($script:RestartNeeded) { Write-Output "[ACTION] Reboot required to finish removing features." }
if ($script:Failures) {
    Write-Output "Hardening finished with $($script:Failures) failure(s): $env:COMPUTERNAME"
    Write-Output "============================================"
    exit 1
}
Write-Output "Hardening complete: $env:COMPUTERNAME"
Write-Output "============================================"
exit 0
