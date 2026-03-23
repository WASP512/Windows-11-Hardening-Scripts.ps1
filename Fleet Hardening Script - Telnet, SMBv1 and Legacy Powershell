# Fleet Hardening - Telnet, SMBv1, Legacy PowerShell Audit & Remediation
# Production-ready for Datto RMM (runs as SYSTEM) or manual execution as Administrator

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as an Administrator!"
    break
}

$OSCaption = (Get-CimInstance Win32_OperatingSystem).Caption
$IsServer  = $OSCaption -match "Server"
Write-Output "============================================"
Write-Output "Hardening Audit: $env:COMPUTERNAME ($OSCaption)"
Write-Output "============================================"

# ─── 1. TELNET ───────────────────────────────────────────────────────────────
Write-Output "`n[TELNET]"
try {
    if ($IsServer) {
        $F = Get-WindowsFeature -Name Telnet-Client -ErrorAction SilentlyContinue
        if ($F.Installed) {
            Remove-WindowsFeature -Name Telnet-Client -Confirm:$false | Out-Null
            Write-Output "[SUCCESS] Telnet-Client removed (Server)."
        } else { Write-Output "[INFO] Telnet-Client not installed." }
    } else {
        $F = Get-WindowsOptionalFeature -Online -FeatureName TelnetClient -ErrorAction SilentlyContinue
        if ($F.State -eq "Enabled") {
            Disable-WindowsOptionalFeature -Online -FeatureName TelnetClient -NoRestart | Out-Null
            Write-Output "[SUCCESS] TelnetClient disabled (Desktop)."
        } else { Write-Output "[INFO] TelnetClient already disabled." }
    }
} catch { Write-Error "[FAIL] Telnet: $($_.Exception.Message)" }

# ─── 2. SMBv1 ────────────────────────────────────────────────────────────────
Write-Output "`n[SMBv1]"
try {
    if ($IsServer) {
        $F = Get-WindowsFeature -Name FS-SMB1 -ErrorAction SilentlyContinue
        if ($F.Installed) {
            Remove-WindowsFeature -Name FS-SMB1 -Confirm:$false | Out-Null
            Write-Output "[SUCCESS] SMBv1 (FS-SMB1) removed (Server)."
        } else { Write-Output "[INFO] SMBv1 not installed (Server)." }
    } else {
        $F = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue
        if ($F.State -eq "Enabled") {
            Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart | Out-Null
            Write-Output "[SUCCESS] SMBv1 disabled (Desktop)."
        } else { Write-Output "[INFO] SMBv1 already disabled." }
    }
    # Belt-and-suspenders: disable via Set-SmbServerConfiguration regardless of feature state
    Set-SmbServerConfiguration -EnableSMB1Protocol $false -Confirm:$false
    Write-Output "[SUCCESS] SMBv1 disabled via SmbServerConfiguration."
} catch { Write-Error "[FAIL] SMBv1: $($_.Exception.Message)" }

# ─── 3. LEGACY POWERSHELL v2 ─────────────────────────────────────────────────
Write-Output "`n[PowerShell v2 Engine]"
try {
    if ($IsServer) {
        $F = Get-WindowsFeature -Name PowerShell-V2 -ErrorAction SilentlyContinue
        if ($F.Installed) {
            Remove-WindowsFeature -Name PowerShell-V2 -Confirm:$false | Out-Null
            Write-Output "[SUCCESS] PowerShell v2 Engine removed (Server)."
        } else { Write-Output "[INFO] PowerShell v2 Engine not installed (Server)." }
    } else {
        $F = Get-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root -ErrorAction SilentlyContinue
        if ($F.State -eq "Enabled") {
            Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root -NoRestart | Out-Null
            Write-Output "[SUCCESS] PowerShell v2 Engine disabled (Desktop)."
        } else { Write-Output "[INFO] PowerShell v2 Engine already disabled." }
    }
} catch { Write-Error "[FAIL] PowerShell v2: $($_.Exception.Message)" }

# ─── 4. PORT AUDIT ───────────────────────────────────────────────────────────
Write-Output "`n[Port Audit - 21, 23, 445]"
@(21, 23, 445) | ForEach-Object {
    $conn = Get-NetTCPConnection -LocalPort $_ -State Listen -ErrorAction SilentlyContinue
    if ($conn) {
        $proc = (Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue).ProcessName
        Write-Warning "[ALERT] Port $_ is LISTENING — Process: $proc (PID: $($conn.OwningProcess))"
    } else {
        Write-Output "[OK] Port $_ not listening."
    }
}

Write-Output "`n============================================"
Write-Output "Hardening Complete: $env:COMPUTERNAME"
Write-Output "============================================"
