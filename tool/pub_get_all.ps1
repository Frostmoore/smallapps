<#
.SYNOPSIS
  Esegue "flutter pub get" su micro_core e su tutte le app, nell'ordine giusto.
.PARAMETER Clean
  Esegue "flutter clean" prima di ogni pub get.
#>
[CmdletBinding()]
param([switch] $Clean)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_common.ps1')

$flutter  = Get-FlutterBat
$projects = Get-DartProjects
if ($projects.Count -eq 0) { Write-Host 'Nessun progetto Dart ancora presente.'; exit 0 }

foreach ($p in $projects) {
    Write-Section "pub get - $($p.Name)"
    Push-Location $p.Path
    try {
        if ($Clean) { & $flutter clean | Out-Host }
        & $flutter pub get | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "pub get fallito su $($p.Name)" }
    } finally { Pop-Location }
}
Write-Host ''
Write-Host "Fatto: $($projects.Count) progetti." -ForegroundColor Green
