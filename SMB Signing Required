#The first command ensures all inbound SMB communications to this device must be signed
#The second command ensures all outbound SMB communications from this device must also be signed

Set-SmbServerConfiguration -RequireSecuritySignature $true -EnableSecuritySignature $true -Force
Set-SmbClientConfiguration -RequireSecuritySignature $true -Force

#No reboot is required for these changes to take effect. You can verify the settings using the following

Get-SmbServerConfiguration | FL RequireSecuritySignature, EnableSecuritySignature
Get-SmbClientConfiguration | FL RequireSecuritySignature

#These commands will display True if SMB signing requirements are enabled for both server and client roles.          
