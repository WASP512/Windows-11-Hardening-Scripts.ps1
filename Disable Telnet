# Disable Telnet Client - Desktop & Server
# Production-ready for Datto RMM (SYSTEM) or manual execution as Administrator

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as an Administrator!"
    break
}

$OSCaption = (Get-CimInstance Win32_OperatingSystem).Caption
Write-Host "Running on: $OSCaption" -ForegroundColor Cyan

try {
    if ($OSCaption -match "Server") {
        $Feature = Get-WindowsFeature -Name Telnet-Client -ErrorAction SilentlyContinue
        if ($Feature.Installed) {
            Remove-WindowsFeature -Name Telnet-Client -Confirm:$false | Out-Null
            Write-Output "[SUCCESS] Telnet-Client removed from Server."
        } else {
            Write-Output "[INFO] Telnet-Client not installed."
        }
    } else {
        $Feature = Get-WindowsOptionalFeature -Online -FeatureName TelnetClient -ErrorAction SilentlyContinue
        if ($Feature.State -eq "Enabled") {
            Disable-WindowsOptionalFeature -Online -FeatureName TelnetClient -NoRestart | Out-Null
            Write-Output "[SUCCESS] TelnetClient disabled on Desktop."
        } else {
            Write-Output "[INFO] TelnetClient already disabled."
        }
    }
} catch {
    Write-Error "Critical Failure: $($_.Exception.Message)"
}
