<#
.SYNOPSIS
  Screenshot di TrashCan per Google Play, su un emulatore Android.

.DESCRIPTION
  Gira integration_test/screenshots_test.dart e fotografa lo schermo ogni volta che il
  test scrive SCATTO:<nome>. Vedi l'intestazione del test per il perche' lo scatto lo fa
  questo script e non il test.

  ☠ Lo schermo viene portato a 1080x1920 per la durata degli scatti. Gli screenshot di
  settembre erano 1080x2400, cioe' 2,22:1, e Play rifiuta ogni immagine il cui lato lungo
  superi il doppio del corto. 9:16 e' anche il formato che Play chiede per mettere l'app
  in evidenza.

  ⚑ La barra di stato va in "modalita' dimostrazione": ora fissa 9:41, batteria piena,
  nessuna notifica. Alla fine si esce e lo schermo torna alla misura vera, anche se il
  test fallisce.

.EXAMPLE
  pwsh tool/screenshots_android.ps1 it apps/trashcan/store/screenshots/android/it
#>
# NON aggiungere param(): vedi tool/fl.ps1.
$ErrorActionPreference = 'Stop'

$lingua = $args[0]
$uscita = $args[1]
if (-not $lingua -or -not $uscita) { throw 'uso: screenshots_android.ps1 <it|en> <cartella>' }

$repo = Split-Path -Parent $PSScriptRoot
$app = Join-Path $repo 'apps/trashcan'
New-Item -ItemType Directory -Force $uscita | Out-Null
$uscita = (Resolve-Path $uscita).Path

function Demo([string]$comando, [string[]]$extra) {
  adb shell am broadcast -a com.android.systemui.demo -e command $comando @extra | Out-Null
}

# Tocca il pulsante "Aggiungi" della finestra con cui il launcher chiede conferma.
#
# ⚑ Il pulsante si cerca nel dump dell'interfaccia, non per coordinate fisse: la finestra
#   cambia posizione con la misura dello schermo e con la versione del launcher, e un tocco
#   a vuoto lascerebbe uno screenshot della schermata principale senza widget.
function Conferma-Widget {
  for ($i = 0; $i -lt 15; $i++) {
    Start-Sleep -Seconds 1
    adb shell uiautomator dump /sdcard/ui.xml | Out-Null
    $xml = adb exec-out cat /sdcard/ui.xml
    $m = [regex]::Match($xml, 'text="(Add to home screen|Add|Aggiungi[^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"')
    if ($m.Success) {
      $x = ([int]$m.Groups[2].Value + [int]$m.Groups[4].Value) / 2
      $y = ([int]$m.Groups[3].Value + [int]$m.Groups[5].Value) / 2
      adb shell input tap $x $y | Out-Null
      Write-Host "confermato il widget ($($m.Groups[1].Value))"
      Start-Sleep -Seconds 2
      return
    }
  }
  Write-Warning 'finestra di conferma del widget non trovata'
}

adb shell wm size 1080x1920
adb shell settings put global sysui_demo_allowed 1
Demo 'enter' @()
Demo 'clock' @('-e', 'hhmm', '0941')
Demo 'battery' @('-e', 'level', '100', '-e', 'plugged', 'false')
# `fully` per il Wi-Fi senza il punto esclamativo, e niente rete mobile: il primo giro
# mostrava un "3G" che sa di telefono vecchio.
Demo 'network' @('-e', 'wifi', 'show', '-e', 'level', '4', '-e', 'fully', 'true')
Demo 'network' @('-e', 'mobile', 'hide')
Demo 'notifications' @('-e', 'visible', 'false')

$registro = New-TemporaryFile
try {
  $test = Start-Process -FilePath 'pwsh' -PassThru -NoNewWindow `
    -RedirectStandardOutput $registro.FullName -RedirectStandardError "$($registro.FullName).err" `
    -WorkingDirectory $app `
    -ArgumentList @('-NoProfile', '-File', (Join-Path $repo 'tool/fl.ps1'), 'test',
      'integration_test/screenshots_test.dart', '-d', 'emulator-5554', "--dart-define=LINGUA=$lingua")

  $fatti = @{}
  while (-not $test.HasExited) {
    $testo = Get-Content $registro.FullName -Raw -ErrorAction SilentlyContinue
    if ($testo) {
      foreach ($m in [regex]::Matches($testo, 'SCATTO:([a-z-]+)')) {
        $nome = $m.Groups[1].Value
        if ($fatti.ContainsKey($nome)) { continue }
        Start-Sleep -Seconds 1
        $file = Join-Path $uscita "$nome.png"
        # `exec-out` e non `shell`: `shell` passa per un terminale che su Windows
        # converte i fine riga dentro il PNG, e l'immagine esce corrotta.
        cmd /c "adb exec-out screencap -p > `"$file`""
        $fatti[$nome] = $true
        Write-Host "scattata $nome"
      }

      # Il widget: il test ha chiesto al launcher di aggiungerlo, la conferma tocca a noi.
      if ($testo -match 'FISSA:widget' -and -not $fatti.ContainsKey('widget')) {
        $fatti['widget'] = $true
        Conferma-Widget
        adb shell input keyevent HOME | Out-Null
        Start-Sleep -Seconds 3
        $file = Join-Path $uscita 'widget-schermata.png'
        cmd /c "adb exec-out screencap -p > `"$file`""
        Write-Host 'scattata widget-schermata'
      }
    }
    Start-Sleep -Milliseconds 500
  }
  Write-Host "fatto: $($fatti.Count) schermate in $uscita"
  if ((Get-Content $registro.FullName -Raw) -match 'Some tests failed') {
    Write-Warning 'il test e'' fallito: guarda il registro'
    Get-Content $registro.FullName -Tail 30
  }
}
finally {
  Demo 'exit' @()
  adb shell wm size reset
}
