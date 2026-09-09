<#
.SYNOPSIS
  Scarica la toolchain Flutter del progetto in .flutter/, senza toccare quella di sistema.

.DESCRIPTION
  Legge il manifest ufficiale dei rilasci, scarica l'archivio del canale stable (o della
  versione richiesta), ne verifica lo SHA256 e lo estrae in .flutter/.
  La cartella .flutter/ e' ignorata da git: pesa oltre 1 GB e non va versionata.

.PARAMETER Version
  Versione esatta da installare (es. 3.47.3). Se omessa, usa la stable corrente.

.PARAMETER Force
  Rimuove una .flutter/ gia' presente invece di fermarsi.

.EXAMPLE
  pwsh tool/get_flutter.ps1
  pwsh tool/get_flutter.ps1 -Version 3.47.3 -Force
#>
[CmdletBinding()]
param(
    [string] $Version,
    [switch] $Force
)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

$repoRoot   = Split-Path -Parent $PSScriptRoot
$flutterDir = Join-Path $repoRoot '.flutter'

if (Test-Path $flutterDir) {
    if (-not $Force) {
        Write-Error ".flutter/ esiste gia'. Usa -Force per sostituirla."
        exit 1
    }
    Write-Host 'Rimuovo la toolchain esistente...'
    Remove-Item $flutterDir -Recurse -Force
}

Write-Host 'Leggo il manifest dei rilasci Flutter...'
$manifest = Invoke-RestMethod -Uri 'https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json' -TimeoutSec 120

if ($Version) {
    $release = $manifest.releases | Where-Object { $_.version -eq $Version -and $_.channel -eq 'stable' } | Select-Object -First 1
    if (-not $release) { Write-Error "Versione stable $Version non trovata nel manifest."; exit 1 }
} else {
    $hash    = $manifest.current_release.stable
    $release = $manifest.releases | Where-Object { $_.hash -eq $hash -and $_.channel -eq 'stable' } | Select-Object -First 1
}

$url = "$($manifest.base_url)/$($release.archive)"
$zip = Join-Path ([System.IO.Path]::GetTempPath()) "flutter_$($release.version).zip"

Write-Host "Versione : $($release.version)  (Dart $($release.dart_sdk_version))"
Write-Host "Archivio : $url"
Write-Host 'Download in corso, puo richiedere diversi minuti...'
Invoke-WebRequest -Uri $url -OutFile $zip -TimeoutSec 3600

$got = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
if ($got -ne $release.sha256.ToLower()) {
    Remove-Item $zip -Force
    Write-Error "SHA256 non corrisponde. Atteso $($release.sha256), ottenuto $got. Download scartato."
    exit 1
}
Write-Host 'Checksum verificato.'

Write-Host 'Estrazione...'
Expand-Archive -Path $zip -DestinationPath $repoRoot -Force
Rename-Item -Path (Join-Path $repoRoot 'flutter') -NewName '.flutter'
Remove-Item $zip -Force

# La versione installata e' un fatto del progetto: va versionata.
Set-Content -Path (Join-Path $repoRoot '.flutter-version') -Value $release.version -NoNewline

Write-Host ''
Write-Host "Toolchain pronta in $flutterDir"
Write-Host 'Verifica con:  pwsh tool/fl.ps1 --version'
