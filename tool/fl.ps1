<#
.SYNOPSIS
  Wrapper sulla toolchain Flutter locale al progetto (.flutter/).

.DESCRIPTION
  Sulla macchina di sviluppo esiste un'installazione Flutter di sistema piu' vecchia, da cui
  dipendono altri progetti. Questo progetto NON deve usarla e NON deve aggiornarla.
  Ogni comando Flutter di MicroApps passa da qui.

  Vedi develop_microapps.md, ADR-002 e §5.8.

.EXAMPLE
  pwsh tool/fl.ps1 --version
  pwsh tool/fl.ps1 pub get
  pwsh tool/fl.ps1 run -d emulator-5554 --dart-define=BILLING=fake
#>
[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $Args
)

$ErrorActionPreference = 'Stop'

$repoRoot   = Split-Path -Parent $PSScriptRoot
$flutterDir = Join-Path $repoRoot '.flutter'
$flutterBin = Join-Path $flutterDir 'bin\flutter.bat'

if (-not (Test-Path $flutterBin)) {
    Write-Error @"
Toolchain Flutter del progetto non trovata in:
  $flutterDir

Scaricala con:
  pwsh tool/get_flutter.ps1

Non usare il Flutter di sistema: altri progetti di questa macchina dipendono dalla
versione vecchia. Vedi develop_microapps.md §5.8.
"@
    exit 1
}

# Isola la toolchain del progetto da quella di sistema per la durata del comando.
$env:PUB_CACHE = Join-Path $flutterDir '.pub-cache'
$env:PATH      = (Join-Path $flutterDir 'bin') + ';' + $env:PATH

& $flutterBin @Args
exit $LASTEXITCODE
