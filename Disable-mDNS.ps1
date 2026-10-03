# Step 1: Define the registry path and value for mDNS disablement
$RegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters"
$Name = "EnableMDNS"
$Value = 0

# Step 2: Create the registry key if it does not exist
If (!(Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}

# Step 3: Set the 'EnableMDNS' registry value to 0 (disable mDNS)
New-ItemProperty -Path $RegPath -Name $Name -Value $Value -PropertyType DWORD -Force | Out-Null
#
