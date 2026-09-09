<#
.SYNOPSIS
  Verifica meccanicamente che un codebase_reference.md corrisponda al codice reale.

.DESCRIPTION
  Il rituale di fine fase (develop_microapps.md §6, punto 2) impone che l'atlante sia
  verificato a macchina e non a occhio: un atlante sbagliato e' peggio di nessun atlante,
  perche' fa prendere decisioni su informazioni false, e rileggerlo a mano smette di
  funzionare intorno alla terza fase.

  Lo script estrae dal codice i nomi pubblici di primo livello (classi, enum, mixin,
  extension, typedef per Dart; interfacce, tipi, classi e funzioni esportate per
  TypeScript) e li confronta con quelli citati nell'atlante.

  Non pretende di capire il linguaggio: e' un rilevatore di divergenze, tarato per essere
  rumoroso. Un falso positivo costa una riga in atlante; un falso negativo costa una
  decisione sbagliata.

.PARAMETER Project
  Percorso della cartella del progetto (deve contenere codebase_reference.md).

.PARAMETER Quiet
  Stampa solo il riepilogo.

.EXAMPLE
  pwsh tool/verify_atlas.ps1 -Project packages/micro_core
  pwsh tool/verify_atlas.ps1 -Project apps/trashcan
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $Project,
    [switch] $Quiet
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_common.ps1')

$projectPath = Resolve-Path (Join-Path (Get-RepoRoot) $Project) -ErrorAction SilentlyContinue
if (-not $projectPath) { $projectPath = Resolve-Path $Project }

$atlas = Join-Path $projectPath 'codebase_reference.md'
if (-not (Test-Path $atlas)) {
    Write-Error "Atlante mancante: $atlas`nOgni progetto deve avere il suo codebase_reference.md (§6 punto 2)."
    exit 1
}

$atlasText = Get-Content $atlas -Raw

# --- Estrazione dei simboli dal codice -------------------------------------------------
$symbols = [System.Collections.Generic.Dictionary[string, string]]::new()

$dartFiles = @()
$libDir = Join-Path $projectPath 'lib'
if (Test-Path $libDir) {
    $dartFiles = Get-ChildItem $libDir -Recurse -Filter *.dart |
        Where-Object { $_.Name -notmatch '\.(g|freezed|drift)\.dart$' }
}

foreach ($f in $dartFiles) {
    $rel = $f.FullName.Substring($projectPath.Path.Length + 1).Replace('\', '/')
    foreach ($line in (Get-Content $f.FullName)) {
        if ($line -match '^\s*(?:abstract\s+|final\s+|base\s+|sealed\s+|interface\s+|mixin\s+)*(class|enum|mixin|extension|typedef)\s+([A-Z_][A-Za-z0-9_]*)') {
            $name = $Matches[2]
            if ($name -notmatch '^_') { $symbols[$name] = $rel }
        }
    }
}

$tsFiles = @()
$srcDir = Join-Path $projectPath 'src'
if (Test-Path $srcDir) { $tsFiles = Get-ChildItem $srcDir -Recurse -Include *.ts, *.mts }

foreach ($f in $tsFiles) {
    $rel = $f.FullName.Substring($projectPath.Path.Length + 1).Replace('\', '/')
    foreach ($line in (Get-Content $f.FullName)) {
        if ($line -match '^\s*export\s+(?:declare\s+)?(?:abstract\s+)?(?:const\s+)?(class|interface|type|enum|function)\s+([A-Za-z_][A-Za-z0-9_]*)') {
            $symbols[$Matches[2]] = $rel
        }
    }
}

if ($symbols.Count -eq 0) {
    Write-Host "Nessun simbolo trovato in $Project. Il progetto e' vuoto o la struttura non e' quella attesa." -ForegroundColor Yellow
    exit 0
}

# --- Confronto -------------------------------------------------------------------------
$missingInDoc = @()
foreach ($name in ($symbols.Keys | Sort-Object)) {
    # Cerca il nome come parola intera: dentro backtick, in tabella o in un blocco di codice.
    if ($atlasText -notmatch "(?<![A-Za-z0-9_])$([regex]::Escape($name))(?![A-Za-z0-9_])") {
        $missingInDoc += [pscustomobject]@{ Name = $name; File = $symbols[$name] }
    }
}

# Nomi citati nell'atlante dentro backtick, con la forma di un tipo, che non esistono piu'.
$quoted = [regex]::Matches($atlasText, '`([A-Z][A-Za-z0-9_]{2,})`') |
    ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
$missingInCode = $quoted | Where-Object { -not $symbols.ContainsKey($_) }

# --- Esito -----------------------------------------------------------------------------
if (-not $Quiet) {
    if ($missingInDoc.Count -gt 0) {
        Write-Host ''
        Write-Host 'MISSING_IN_DOC - esistono nel codice, non compaiono nell atlante:' -ForegroundColor Red
        $missingInDoc | ForEach-Object { Write-Host ("  {0,-38} {1}" -f $_.Name, $_.File) -ForegroundColor Red }
    }
    if ($missingInCode.Count -gt 0) {
        Write-Host ''
        Write-Host 'MISSING_IN_CODE - citati nell atlante, non trovati nel codice (piu grave):' -ForegroundColor Yellow
        $missingInCode | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
        Write-Host '  Nota: puo trattarsi di tipi di terze parti o del framework. Valuta caso per caso.' -ForegroundColor DarkGray
    }
}

Write-Host ''
Write-Host ("Atlante {0}: {1} simboli nel codice, {2} non documentati, {3} citati ma assenti." -f `
    $Project, $symbols.Count, $missingInDoc.Count, @($missingInCode).Count)

if ($missingInDoc.Count -gt 0) {
    Write-Host 'Il rituale di fine fase non e concluso finche MISSING_IN_DOC non e vuoto.' -ForegroundColor Red
    exit 1
}
Write-Host 'Atlante allineato al codice.' -ForegroundColor Green
exit 0
