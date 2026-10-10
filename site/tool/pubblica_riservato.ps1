<#
.SYNOPSIS
  Rigenera i dati dell'area riservata e carica SOLO var/riservato/dati.json su clawserver.

.DESCRIPTION
  Da lanciare ogni volta che si aggiorna StatusMicroApps.md (decisione del proprietario del
  2026-10-11). Passi:

    1. python site/tool/genera_riservato.py  ->  site/var/riservato/dati.json
    2. controllo che il file sia JSON valido, con "formato": 1 e almeno un'app
    3. scp del solo dati.json in /tmp di clawserver
    4. ssh: install in /var/www/smpmicroapps/var/riservato/ (cartella creata se manca),
       poi `sudo chown -R www-data:www-data` sulla cartella e permessi 750/640

  Non tocca nient'altro del sito: ne' public/, ne' src/, ne' config.local.php.

  ⚑ Usa l'ssh.exe/scp.exe di Windows ($env:WINDIR\System32\OpenSSH): la chiave di clawserver ha
  una passphrase ed e' caricata nell'agent di Windows, con cui l'ssh di Git Bash non dialoga
  (sintomo: "Permission denied (publickey)" subito dopo "Server accepts key").

.PARAMETER SoloGenera
  Rigenera e controlla il file, ma non si collega al server.

.EXAMPLE
  powershell -File site/tool/pubblica_riservato.ps1 -SoloGenera
  powershell -File site/tool/pubblica_riservato.ps1
#>
[CmdletBinding()]
param(
  [switch]$SoloGenera,
  [string]$Server = 'clawserver',
  [string]$Destinazione = '/var/www/smpmicroapps/var/riservato'
)

$ErrorActionPreference = 'Stop'

$sito = Split-Path -Parent $PSScriptRoot           # site/
$generatore = Join-Path $PSScriptRoot 'genera_riservato.py'
$dati = Join-Path $sito 'var/riservato/dati.json'

# ─── 1. Generazione ─────────────────────────────────────────────────────────
# Niente operatore ?? : deve girare anche in Windows PowerShell 5.1.
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) { $python = Get-Command py -ErrorAction SilentlyContinue }
if (-not $python) { throw 'Python non trovato nel PATH.' }
& $python.Source $generatore
if ($LASTEXITCODE -ne 0) { throw "genera_riservato.py e' uscito con $LASTEXITCODE" }

# ─── 2. Controllo ───────────────────────────────────────────────────────────
if (-not (Test-Path $dati)) { throw "Manca $dati" }
$json = Get-Content -Raw -Encoding UTF8 $dati | ConvertFrom-Json
if ($json.formato -ne 1) { throw "dati.json: formato $($json.formato), atteso 1" }
if (@($json.app).Count -lt 1) { throw 'dati.json: nessuna app' }
$kb = [math]::Round((Get-Item $dati).Length / 1KB)
Write-Host ("Controllo superato: {0} app, {1} nella tabella, {2} KB, status del {3}" -f `
  @($json.app).Count, @($json.tabella).Count, $kb, $json.aggiornamento_status)

if ($SoloGenera) {
  Write-Host 'SoloGenera: nessun collegamento al server.'
  exit 0
}

# ─── 3-4. Caricamento ───────────────────────────────────────────────────────
$ssh = Join-Path $env:WINDIR 'System32\OpenSSH\ssh.exe'
$scp = Join-Path $env:WINDIR 'System32\OpenSSH\scp.exe'
foreach ($exe in @($ssh, $scp)) { if (-not (Test-Path $exe)) { throw "Manca $exe (OpenSSH di Windows)" } }

$tmp = "/tmp/riservato-dati-$([guid]::NewGuid().ToString('N')).json"
& $scp -q $dati "${Server}:$tmp"
if ($LASTEXITCODE -ne 0) { throw "scp fallito ($LASTEXITCODE)" }

# Un comando solo, su una riga: niente script con fini riga di Windows (vedi atlante §8).
$remoto = "sudo install -d -m 750 -o www-data -g www-data '$Destinazione' && " +
          "sudo install -m 640 -o www-data -g www-data '$tmp' '$Destinazione/dati.json' && " +
          "rm -f '$tmp' && sudo chown -R www-data:www-data '$Destinazione' && " +
          "sudo ls -l '$Destinazione'"
& $ssh $Server $remoto
if ($LASTEXITCODE -ne 0) { throw "ssh fallito ($LASTEXITCODE)" }

Write-Host "Caricato in ${Server}:$Destinazione/dati.json"
