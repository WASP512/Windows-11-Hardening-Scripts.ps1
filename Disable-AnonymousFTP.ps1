# Import IIS administration module
Import-Module WebAdministration

# Define FTP site name (replace if different)
$ftpSiteName = "Default FTP Site"

# Unlock the anonymousAuthentication section to allow changes
& "$env:SystemRoot\system32\inetsrv\appcmd.exe" unlock config /section:anonymousAuthentication

# Unlock the basicAuthentication section (optional, for enabling basic auth)
& "$env:SystemRoot\system32\inetsrv\appcmd.exe" unlock config /section:basicAuthentication

# Disable Anonymous Authentication for the FTP site silently
Set-WebConfigurationProperty -PSPath "IIS:\Sites\$ftpSiteName" `
  -Filter "system.webServer/security/authentication/anonymousAuthentication" `
  -Name "enabled" -Value $false

# OPTIONAL: Enable Basic Authentication
Set-WebConfigurationProperty -PSPath "IIS:\Sites\$ftpSiteName" `
  -Filter "system.webServer/security/authentication/basicAuthentication" `
  -Name "enabled" -Value $true

