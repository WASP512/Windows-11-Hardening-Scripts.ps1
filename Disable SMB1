# Disable SMB1 client feature on Windows
# This command disables the SMB1 client component at the system level
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol

# Disable SMB1 protocol for SMB server functionality
# This command prevents the SMB server from accepting SMB1 connections
Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
