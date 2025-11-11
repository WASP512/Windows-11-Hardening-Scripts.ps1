# Step 1: Get all network adapter names except for the Loopback adapter
$adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.InterfaceDescription -notmatch "Loopback"} | Select-Object -ExpandProperty Name

# Step 2: Loop through each adapter and disable IPv6 (ms_tcpip6 binding)
foreach ($adapter in $adapters) {
    Disable-NetAdapterBinding -Name $adapter -ComponentID ms_tcpip6 -Confirm:$false -PassThru | Out-Null
}

# Step 3: OPTIONAL - Also disable IPv6 at the system level for extra protection (requires reboot)
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" `
-Name "DisabledComponents" -PropertyType DWord -Value 0xFF -Force | Out-Null
