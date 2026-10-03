<#
.SYNOPSIS
    Deletes a leftover program folder, e.g. after an uninstaller left files behind.

.PARAMETER Path
    The folder to delete, e.g. "C:\Program Files\Avast Software".

.EXAMPLE
    .\Remove-OldProgramFolder.ps1 -Path "C:\Program Files\Avast Software" -WhatIf
    Shows what would be deleted without deleting anything.

.NOTES
    Reboot: No
    Refuses drive roots and top-level system folders (Program Files, Windows, Users, ...).
#>
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$Path
)

$ErrorActionPreference = 'Stop'

try {
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        Write-Output "[OK] '$Path' does not exist; nothing to do."
        exit 0
    }

    $fullPath = (Resolve-Path -LiteralPath $Path).ProviderPath.TrimEnd('\')
    $protected = @(
        $env:SystemDrive, $env:SystemRoot, $env:ProgramFiles, ${env:ProgramFiles(x86)},
        $env:ProgramData, "$env:SystemDrive\Users"
    ) | Where-Object { $_ } | ForEach-Object { $_.TrimEnd('\') }

    if ($fullPath -in $protected -or $fullPath -match '^[A-Za-z]:$') {
        Write-Output "[FAIL] Refusing to delete protected folder '$fullPath'."
        exit 1
    }

    if ($PSCmdlet.ShouldProcess($fullPath, 'Delete folder and all contents')) {
        Remove-Item -LiteralPath $fullPath -Recurse -Force
        Write-Output "[CHANGED] Deleted '$fullPath'."
    }
    exit 0
} catch {
    Write-Output "[FAIL] Remove folder: $($_.Exception.Message)"
    exit 1
}
