# Define the FTP service name
$ServiceName = "FTPSVC"

# Check if the FTP service is installed
if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
    # Stop the FTP service if it's running
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue

    # Disable the FTP service from starting automatically
    Set-Service -Name $ServiceName -StartupType Disabled

    # Optionally, output a confirmation message (comment out for complete silence)
    # Write-Output "FTP service has been stopped and disabled."
} else {
    # FTP service not found; optionally handle this case silently
    # Write-Output "FTP service is not installed."
}
