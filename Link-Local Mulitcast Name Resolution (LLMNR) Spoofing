# Step 1: Define the registry path for LLMNR configuration
$RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"

# Step 2: Create the registry key if it does not exist
If (!(Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}

# Step 3: Set the 'EnableMulticast' value to 0 (disable LLMNR)
New-ItemProperty -Path $RegPath -Name "EnableMulticast" -Value 0 -PropertyType DWORD -Force | Out-Null
