<#
.SYNOPSIS
  "flutter test" su tutti i progetti, o su uno solo.
.PARAMETER Project
  Nome del progetto (micro_core, trashcan, full_freezer, scorte_calore, film_tracker).
.PARAMETER Coverage
  Produce coverage/lcov.info per ogni progetto testato.
#>
[CmdletBinding()]
param([string] $Project, [switch] $Coverage)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_common.ps1')

$flutter  = Get-FlutterBat
$projects = Get-DartProjects
if ($Project) { $projects = $projects | Where-Object { $_.Name -eq $Project } }
if (-not $projects) { Write-Host 'Nessun progetto da testare.'; exit 0 }

$failed = @()
foreach ($p in $projects) {
    if (-not (Test-Path (Join-Path $p.Path 'test'))) {
        Write-Host "salto $($p.Name): nessuna cartella test/" -ForegroundColor DarkGray
        continue
    }
    Write-Section "test - $($p.Name)"
    Push-Location $p.Path
    try {
        if ($Coverage) { & $flutter test --coverage | Out-Host } else { & $flutter test | Out-Host }
        if ($LASTEXITCODE -ne 0) { $failed += $p.Name }
    } finally { Pop-Location }
}

Write-Host ''
if ($failed.Count -gt 0) {
    Write-Host "Test falliti in: $($failed -join ', ')" -ForegroundColor Red
    exit 1
}
Write-Host 'Tutti i test verdi.' -ForegroundColor Green
