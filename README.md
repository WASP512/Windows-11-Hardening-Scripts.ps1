# Windows 11 Hardening Scripts

PowerShell scripts for hardening Windows 11 (and Windows Server) endpoints. They are built to
run from an RMM such as Datto RMM (as SYSTEM) or manually from an elevated PowerShell prompt.

## Conventions

Every script:

- Requires Administrator (or SYSTEM) and refuses to run otherwise.
- Checks the current state first and only changes what is not already compliant, so it is
  safe to run repeatedly.
- Supports `-WhatIf`, which shows what would change without changing anything. Run the fleet in
  `-WhatIf` mode first.
- Prints one line per check: `[OK]` already compliant, `[CHANGED]` fixed, `[WARN]` needs
  attention, `[ALERT]` finding, `[ACTION]` reboot required, `[FAIL]` error.
- Exits `0` on success and `1` on failure, so the RMM shows failed runs correctly.

```powershell
.\Disable-LLMNR.ps1 -WhatIf   # audit
.\Disable-LLMNR.ps1           # remediate
```

## Scripts

| Script | What it does | Reboot | Can break | Revert |
|---|---|---|---|---|
| `Invoke-FleetHardening.ps1` | Removes Telnet client, SMBv1 and PowerShell v2; audits ports 21/23/445 | If features removed | Legacy SMBv1 devices, scripts that use `powershell -Version 2` | Re-enable the features |
| `Disable-Telnet.ps1` | Removes the Telnet client | Rarely | Anyone using `telnet` for port tests (use `Test-NetConnection`) | Re-enable the feature |
| `Disable-SMB1.ps1` | Removes SMBv1 | If feature removed | Very old NAS boxes, copiers, XP/2003 | Re-enable the feature |
| `Disable-FTP.ps1` | Stops and disables the IIS FTP service | No | Anything served over FTP | `Set-Service FTPSVC -StartupType Automatic` |
| `Disable-AnonymousFTP.ps1` | Disables anonymous FTP, enables Basic auth, requires FTPS when a certificate is bound | No | Anonymous FTP clients; clients without FTPS support | Re-enable in IIS Manager |
| `Enable-SMBSigning.ps1` | Requires SMB signing (server and client) | No | Old NAS boxes and scan-to-folder copiers | `Disable-SMBSigning.ps1` |
| `Disable-SMBSigning.ps1` | **Break-fix:** stops requiring SMB signing. `-Side Server`, `Client` or `Both` | No | - | `Enable-SMBSigning.ps1` |
| `Restrict-NullSessions.ps1` | Blocks anonymous (null session) enumeration | Recommended | Legacy systems that enumerate shares anonymously | `Restore-NullSessionDefaults.ps1` |
| `Restore-NullSessionDefaults.ps1` | **Break-fix:** restores the Windows default null session settings | Recommended | - | `Restrict-NullSessions.ps1` |
| `Disable-LLMNR.ps1` | Disables LLMNR (Responder) | No | Name resolution on networks with no DNS | Delete `EnableMulticast` (see script) |
| `Disable-NetBIOS.ps1` | Disables NetBIOS name resolution, NBT-NS (Responder) | Recommended | Very old systems that rely on NetBIOS broadcasts | See script |
| `Disable-mDNS.ps1` | Disables mDNS | Yes | Casting (Chromecast/AirPlay), some printer discovery | Delete `EnableMDNS` (see script) |
| `Mitigate-IPv6DNSSpoofing.ps1` | Blocks rogue DHCPv6 and router advertisements (mitm6); prefers IPv4 | Yes | Networks that really use IPv6 | Remove firewall group `Hardening - IPv6 DNS Spoofing`; delete `DisabledComponents` |
| `Remove-OldProgramFolder.ps1` | Deletes a leftover program folder: `-Path "C:\Program Files\Avast Software"` | No | - | - |

Run `Disable-LLMNR.ps1` and `Disable-NetBIOS.ps1` together: Responder abuses both.

If you manage devices with Intune or Group Policy, configure these settings there as well so they
cannot drift back after a script has run.

## Contributing

Scripts must stay ASCII-only. Windows PowerShell 5.1 reads UTF-8 files without a BOM as ANSI,
and characters such as an em-dash can corrupt a string and stop the script parsing.
The `Lint` GitHub Actions workflow checks this, parses every script with Windows PowerShell 5.1
and runs PSScriptAnalyzer.
