<#
.SYNOPSIS
    Mitigates IPv6 DNS takeover (mitm6) by blocking rogue DHCPv6 and router advertisements.

.DESCRIPTION
    mitm6 answers the DHCPv6 requests Windows sends by default and hands out an
    attacker-controlled IPv6 DNS server, which Windows then prefers over IPv4 DNS.

    This script:
      1. Adds Windows Firewall rules that block inbound DHCPv6 (UDP 546), outbound DHCPv6
         (UDP 547) and inbound ICMPv6 router advertisements (type 134). Block rules take
         precedence over the built-in "Core Networking" allow rules.
      2. Sets DisabledComponents=0x20 so Windows prefers IPv4 over IPv6. This replaces the
         unsupported 0xFF value (IPv6 fully disabled), which breaks some Windows components.

    On networks that really use IPv6 (SLAAC or DHCPv6), these rules remove IPv6 connectivity.
    Revert by removing the firewall rules in the group below and deleting DisabledComponents.

.PARAMETER UnbindAllAdapters
    Also removes the IPv6 binding from every network adapter, including adapters that are
    currently down. Not recommended: the firewall rules are enough to stop mitm6.

.NOTES
    Reboot: Required for the DisabledComponents change. The firewall rules apply immediately.
    Run with -WhatIf to see what would change without changing anything.
#>
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$UnbindAllAdapters
)

$ErrorActionPreference = 'Stop'
$RuleGroup = 'Hardening - IPv6 DNS Spoofing'

$Rules = @(
    @{ DisplayName = 'Block DHCPv6 In (mitm6)';   Direction = 'Inbound';  Protocol = 'UDP';    LocalPort = 546 }
    @{ DisplayName = 'Block DHCPv6 Out (mitm6)';  Direction = 'Outbound'; Protocol = 'UDP';    RemotePort = 547 }
    @{ DisplayName = 'Block ICMPv6 Router Advertisement In (mitm6)'; Direction = 'Inbound'; Protocol = 'ICMPv6'; IcmpType = 134 }
)

try {
    foreach ($rule in $Rules) {
        if (Get-NetFirewallRule -DisplayName $rule.DisplayName -ErrorAction SilentlyContinue) {
            Write-Output "[OK] Firewall rule '$($rule.DisplayName)' already exists."
            continue
        }
        if ($PSCmdlet.ShouldProcess($rule.DisplayName, 'Create firewall block rule')) {
            New-NetFirewallRule @rule -Group $RuleGroup -Action Block -Profile Any -Enabled True | Out-Null
            Write-Output "[CHANGED] Firewall rule '$($rule.DisplayName)' created."
        }
    }

    $TcpipPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters'
    $current = (Get-ItemProperty -Path $TcpipPath -Name DisabledComponents -ErrorAction SilentlyContinue).DisabledComponents
    if ($current -eq 0x20) {
        Write-Output "[OK] DisabledComponents is already 0x20 (prefer IPv4)."
    } else {
        $was = if ($null -eq $current) { 'not set' } else { '0x{0:X}' -f $current }
        if ($PSCmdlet.ShouldProcess("$TcpipPath\DisabledComponents", "Set to 0x20 (currently $was)")) {
            New-ItemProperty -Path $TcpipPath -Name DisabledComponents -PropertyType DWord -Value 0x20 -Force | Out-Null
            Write-Output "[CHANGED] DisabledComponents set to 0x20 (was $was). Reboot required."
        }
    }

    if ($UnbindAllAdapters) {
        $bindings = Get-NetAdapterBinding -ComponentID ms_tcpip6 | Where-Object Enabled
        foreach ($binding in $bindings) {
            if ($PSCmdlet.ShouldProcess($binding.Name, 'Disable IPv6 binding')) {
                Disable-NetAdapterBinding -Name $binding.Name -ComponentID ms_tcpip6 -Confirm:$false
                Write-Output "[CHANGED] IPv6 binding disabled on '$($binding.Name)'."
            }
        }
        if (-not $bindings) { Write-Output "[OK] IPv6 is already unbound from all adapters." }
    }
    exit 0
} catch {
    Write-Output "[FAIL] IPv6 DNS spoofing: $($_.Exception.Message)"
    exit 1
}
