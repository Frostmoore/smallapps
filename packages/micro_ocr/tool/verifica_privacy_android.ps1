<#
.SYNOPSIS
  Guardia di privacy sul BINARIO di un APK che include micro_ocr (F12.1.2 punto 3).

.DESCRIPTION
  Estrae da -Apk ogni lib/<abi>/libonnxruntime.so e cerca le stringhe della telemetria di
  ONNX Runtime (dalla 1.29: invio a mobile.events.data.microsoft.com con l'SDK «1DS» /
  OneCollector). Ne basta una per uscire con codice 1. Stampa anche i permessi dell'APK
  (aapt2 dump permissions), da leggere a occhio: INTERNET deve arrivare solo da Play Billing,
  e lo dimostra il task Gradle verificaPrivacyOcr dell'app sul report di fusione.

  ☠ Perche' anche sul binario e non solo in Gradle: `strictly("1.28.0")` e il controllo sulle
  dipendenze risolte proteggono la build, non un APK costruito altrove o con un ORT copiato a
  mano. Da lanciare dopo `flutter build apk --release` e, in F12.7, prima di ogni caricamento
  su Play.

  ⚑ Il controllo e' sulle stringhe e non sulla versione dichiarata: la versione si puo'
  sbagliare a scrivere, gli indirizzi a cui il codice manda dati no.

.PARAMETER Apk
  Percorso dell'APK (o di un .aab: stessa struttura zip, librerie in base/lib/<abi>/).

.EXAMPLE
  pwsh packages/micro_ocr/tool/verifica_privacy_android.ps1 -Apk apps/spending_review/build/app/outputs/flutter-apk/app-release.apk
#>
param(
  [Parameter(Mandatory = $true)][string] $Apk
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

if (-not (Test-Path $Apk)) { throw "APK non trovato: $Apk" }
$Apk = (Resolve-Path $Apk).Path

# Le stringhe vietate (F12.0 punto 8, f12-ocr.md §3.2).
$vietate = @('events.data.microsoft.com', 'OneCollector', '1DS', 'TelemetryInitializer')

$trovate = @()
$librerie = 0
$zip = [System.IO.Compression.ZipFile]::OpenRead($Apk)
try {
  foreach ($voce in $zip.Entries) {
    if ($voce.FullName -notmatch '(^|/)lib/[^/]+/libonnxruntime[^/]*\.so$' -and
        $voce.FullName -notmatch '\.dex$' -and $voce.FullName -ne 'AndroidManifest.xml' -and
        $voce.FullName -ne 'base/manifest/AndroidManifest.xml') { continue }
    if ($voce.FullName -match '\.so$') { $librerie++ }
    $flusso = $voce.Open()
    $mem = New-Object System.IO.MemoryStream
    try { $flusso.CopyTo($mem) } finally { $flusso.Dispose() }
    # Latin1: un byte = un carattere, cosi' le stringhe ASCII del binario si cercano come testo.
    $testo = [System.Text.Encoding]::Latin1.GetString($mem.ToArray())
    # Il manifest binario e i .dex tengono le stringhe anche in UTF-16: si cerca in tutte e due.
    $testo16 = [System.Text.Encoding]::Unicode.GetString($mem.ToArray())
    # ⚑ «1DS» e' corta: nei .dex (decine di MB di stringhe) potrebbe comparire per caso, quindi
    # li' si cercano solo le stringhe lunghe; nel .so di ORT si cercano tutte.
    $daCercare = if ($voce.FullName -match '\.so$') { $vietate } else { $vietate | Where-Object { $_.Length -gt 5 } }
    foreach ($s in $daCercare) {
      if ($s.Length -le 5) {
        # ☠ F12.7: nel .so di ORT per armeabi-v7a «1DS» compare 20 volte DENTRO il codice macchina
        # (istruzioni Thumb: «\x03 1DSDS \xf8»), mentre gli indirizzi veri della telemetria non ci
        # sono in nessuna ABI. Una stringa corta conta solo dentro una stringa STAMPABILE di almeno
        # 8 caratteri, come fa `strings` (una stringa del programma, non byte di codice). Le stringhe
        # lunghe si cercano ancora ovunque, in Latin1 e in UTF-16.
        $stampabili = @([regex]::Matches($testo, '[\x20-\x7E]{8,}') | Where-Object { $_.Value.Contains($s) })
        if ($stampabili.Count -gt 0) { $trovate += "$($voce.FullName): '$s' in '$($stampabili[0].Value)'" }
        continue
      }
      if ($testo.Contains($s) -or $testo16.Contains($s)) { $trovate += "$($voce.FullName): '$s'" }
    }
  }
} finally {
  $zip.Dispose()
}

Write-Host "APK: $Apk"
Write-Host "librerie libonnxruntime*.so controllate: $librerie"

# Permessi (solo da leggere): aapt2 dalla build-tools piu' recente, se c'e'.
$sdk = @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT, 'D:\androidvd', "$env:LOCALAPPDATA\Android\Sdk") |
  Where-Object { $_ -and (Test-Path (Join-Path $_ 'build-tools')) } | Select-Object -First 1
if ($sdk -and $Apk -match '\.apk$') {
  $aapt2 = Get-ChildItem (Join-Path $sdk 'build-tools') -Directory | Sort-Object { [version]$_.Name } -Descending |
    ForEach-Object { Join-Path $_.FullName 'aapt2.exe' } | Where-Object { Test-Path $_ } | Select-Object -First 1
  if ($aapt2) {
    Write-Host '--- aapt2 dump permissions'
    & $aapt2 dump permissions $Apk
  }
}

if ($trovate.Count -gt 0) {
  Write-Host ''
  Write-Host 'TELEMETRIA TROVATA: questo APK non si pubblica (F12.0 punto 8).' -ForegroundColor Red
  $trovate | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
  exit 1
}
if ($librerie -eq 0) {
  Write-Host 'Attenzione: nessuna libonnxruntime*.so nell''APK (micro_ocr non incluso?).' -ForegroundColor Yellow
}
Write-Host 'OK: nessuna stringa di telemetria.' -ForegroundColor Green
exit 0
