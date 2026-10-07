<#
.SYNOPSIS
  Costruisce il pacchetto firmato di un'app, collegato al License Server.

.DESCRIPTION
  Fa in un comando le quattro cose che servono a ogni pubblicazione, nell'ordine giusto:

    1. incrementa il versionCode in pubspec.yaml (Play rifiuta un numero gia' visto, e
       quel numero non si libera mai piu');
    2. recupera dal server il segreto HMAC dell'app;
    3. compila il bundle di release passando MA_LICENSE_URL e MA_APP_SECRET;
    4. copia il risultato in <app>/store/ e verifica che sia firmato.

  Il file con i define viene creato e **cancellato sempre**, anche se la compilazione
  fallisce: contiene il segreto e non deve restare su disco ne' finire nel repository.

.PARAMETER App
  Il nome della cartella sotto apps/. Per ora solo `trashcan`.

.PARAMETER NoBump
  Non toccare il versionCode. Serve a ricostruire lo stesso numero, per esempio dopo aver
  corretto un testo su un pacchetto **non ancora caricato**.

.EXAMPLE
  pwsh tool/build_release.ps1 -App trashcan
  pwsh tool/build_release.ps1 -App trashcan -NoBump
#>
param(
    [string] $App = 'trashcan',
    [switch] $NoBump
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$appDir = Join-Path $repoRoot "apps/$App"
$pubspec = Join-Path $appDir 'pubspec.yaml'

if (-not (Test-Path $pubspec)) {
    Write-Error "App non trovata: $appDir"
    exit 1
}

# ─── 1. versionCode ──────────────────────────────────────────────────────────
$testo = Get-Content $pubspec -Raw
if ($testo -notmatch '(?m)^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$') {
    Write-Error "version: non trovata o malformata in $pubspec"
    exit 1
}
$nome = $Matches[1]
$codice = [int]$Matches[2]

if (-not $NoBump) {
    $codice++
    $testo = $testo -replace '(?m)^version:\s*\d+\.\d+\.\d+\+\d+\s*$', "version: $nome+$codice"
    Set-Content -Path $pubspec -Value $testo -NoNewline
}

Write-Host "Versione: $nome+$codice" -ForegroundColor Cyan

# ─── 2. Segreto HMAC ─────────────────────────────────────────────────────────
#
# ☠ Vive SOLO in /opt/microapps/server/.env, mai nel repository e mai in un file locale
# permanente. Si legge in una variabile e non si stampa: il valore non deve finire ne'
# nel terminale ne' in un log di build.
Write-Host 'Recupero il segreto dal server...' -NoNewline
$riga = ssh clawserver 'sudo grep -m1 ^APP_SECRETS= /opt/microapps/server/.env'
# ⚑ Sul server gli id non hanno il trattino basso: la cartella `full_freezer` e' l'app
#   `fullfreezer` (vedi licenseAppId in apps/full_freezer/lib/app/app_config.dart).
$idServer = $App -replace '_', ''
$segreto = [regex]::Match((($riga | Out-String).Trim()), "(?:^|[=,])$idServer`:([^,\s]+)").Groups[1].Value

if ($segreto.Length -lt 16) {
    Write-Host ''
    Write-Error "Segreto per '$idServer' non trovato in APP_SECRETS sul server."
    exit 1
}
Write-Host " ok ($($segreto.Length) caratteri)" -ForegroundColor Green

# ─── 3. Compilazione ─────────────────────────────────────────────────────────
#
# ☠ Si usa --dart-define-from-file con un percorso **relativo**, non --dart-define.
# tool/fl.ps1 chiama un file batch di Windows, che spezza gli argomenti sui due punti:
# `--dart-define=MA_LICENSE_URL=https://...` arriva a Flutter tagliato in due e il build
# muore con "Target file //lic.smpmicroapps.it not found". Anche il percorso del file va
# relativo, perche' `C:\...` contiene a sua volta due punti.
Push-Location $appDir
$defines = 'release_defines.json'

try {
    @{
        MA_LICENSE_URL = 'https://lic.smpmicroapps.it'
        MA_APP_SECRET  = $segreto
    } | ConvertTo-Json -Compress | Set-Content -Path $defines -Encoding utf8 -NoNewline

    pwsh (Join-Path $repoRoot 'tool/fl.ps1') build appbundle --release "--dart-define-from-file=$defines"
    if ($LASTEXITCODE -ne 0) { throw "La compilazione e' fallita." }
}
finally {
    Remove-Item $defines -Force -ErrorAction SilentlyContinue
}

# ─── 4. Copia e verifica della firma ─────────────────────────────────────────
$bundle = 'build/app/outputs/bundle/release/app-release.aab'
$storeDir = 'store'
New-Item -ItemType Directory -Force -Path $storeDir | Out-Null
$destinazione = Join-Path $storeDir "$App-$nome-$codice.aab"
Copy-Item $bundle $destinazione -Force

$jarsigner = @(
    'C:\Program Files\Android\Android Studio\jbr\bin\jarsigner.exe',
    "$env:LOCALAPPDATA\Programs\Android Studio\jbr\bin\jarsigner.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $jarsigner) { $jarsigner = (Get-Command jarsigner -ErrorAction SilentlyContinue).Source }

if ($jarsigner) {
    # ☠ `$esito -match '...'` NON e' un booleano: su un array PowerShell restituisce gli
    # elementi che corrispondono, quindi il confronto con $true falliva sempre e lo script
    # dichiarava non firmato un pacchetto firmato benissimo. Serve -Quiet, che torna un
    # booleano vero.
    $esito = & $jarsigner -verify $destinazione 2>&1
    $firmato = [bool]($esito | Select-String -Pattern 'jar verified' -Quiet)
} else {
    $firmato = $null
}

Pop-Location

$mb = '{0:N1}' -f ((Get-Item (Join-Path $appDir $destinazione)).Length / 1MB)
Write-Host ''
Write-Host "Pacchetto: apps/$App/$destinazione  ($mb MB)" -ForegroundColor Green
if ($firmato -eq $true) {
    Write-Host 'Firma: verificata' -ForegroundColor Green
} elseif ($null -eq $firmato) {
    Write-Host 'Firma: jarsigner non trovato, verifica saltata' -ForegroundColor Yellow
} else {
    Write-Error 'Firma: NON VERIFICATA. Non caricare questo pacchetto.'
    exit 1
}
