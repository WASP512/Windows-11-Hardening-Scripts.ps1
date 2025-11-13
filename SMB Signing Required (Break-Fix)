#The first command disables the requirement for SMB signing on inbound connections (server side). The second disables the SMB signing requirement for outbound connections (client side). You may only need to use one of these to fix an issue. 
Set-SmbServerConfiguration -RequireSecuritySignature $false -Force
Set-SmbClientConfiguration -RequireSecuritySignature $false -Force
