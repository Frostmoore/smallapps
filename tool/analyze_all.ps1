<#
.SYNOPSIS
  "dart analyze" su tutti i progetti Dart. Esce != 0 alla prima issue.
  Vedi develop_microapps.md §5.5: zero issue prima di ogni commit di fine fase.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_common.ps1')

$dart     = Get-DartExe
$projects = Get-DartProjects
if ($projects.Count -eq 0) { Write-Host 'Nessun progetto Dart ancora presente.'; exit 0 }

$failed = @()
foreach ($p in $projects) {
    Write-Section "analyze - $($p.Name)"
    Push-Location $p.Path
    try {
        & $dart analyze --fatal-infos | Out-Host
        if ($LASTEXITCODE -ne 0) { $failed += $p.Name }
    } finally { Pop-Location }
}

Write-Host ''
if ($failed.Count -gt 0) {
    Write-Host "Issue trovate in: $($failed -join ', ')" -ForegroundColor Red
    exit 1
}
Write-Host "Nessuna issue in $($projects.Count) progetti." -ForegroundColor Green
