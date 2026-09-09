<#
.SYNOPSIS
  Calcola il prossimo branch di versione secondo develop_microapps.md §5.3.
.DESCRIPTION
  I branch si chiamano come le versioni, da v1.0.0 in poi.
    -Small   +0.0.1  fix, refactor locale, test, documentazione
    -Medium  +0.1.0  sottofase rilevante, feature utente nuova
    -Large   +1.0.0  fase completata, o modifica che tocca tutte e quattro le app
  Con -Create crea il branch e ci si sposta.
.EXAMPLE
  pwsh tool/bump_version.ps1 -Medium
  pwsh tool/bump_version.ps1 -Large -Create
#>
[CmdletBinding(DefaultParameterSetName = 'Small')]
param(
    [Parameter(ParameterSetName = 'Small')]  [switch] $Small,
    [Parameter(ParameterSetName = 'Medium')] [switch] $Medium,
    [Parameter(ParameterSetName = 'Large')]  [switch] $Large,
    [switch] $Create
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_common.ps1')
Push-Location (Get-RepoRoot)

try {
    $names = @()
    $names += (git branch --format='%(refname:short)' 2>$null)
    $names += (git branch -r --format='%(refname:short)' 2>$null) | ForEach-Object { ($_ -split '/', 2)[1] }

    $versions = $names |
        Where-Object { $_ -match '^v(\d+)\.(\d+)\.(\d+)$' } |
        ForEach-Object {
            $null = $_ -match '^v(\d+)\.(\d+)\.(\d+)$'
            [pscustomobject]@{
                Name  = $_
                Major = [int]$Matches[1]; Minor = [int]$Matches[2]; Patch = [int]$Matches[3]
            }
        } | Sort-Object Major, Minor, Patch

    if (-not $versions) {
        $next = 'v1.0.0'
    } else {
        $last = $versions[-1]
        switch ($PSCmdlet.ParameterSetName) {
            'Large'  { $next = "v$($last.Major + 1).0.0" }
            'Medium' { $next = "v$($last.Major).$($last.Minor + 1).0" }
            default  { $next = "v$($last.Major).$($last.Minor).$($last.Patch + 1)" }
        }
        Write-Host "Ultima versione: $($last.Name)" -ForegroundColor DarkGray
    }

    Write-Host $next

    if ($Create) {
        if ($names -contains $next) { Write-Error "Il branch $next esiste gia'. Una versione e' immutabile."; exit 1 }
        git checkout -b $next | Out-Host
    }
} finally { Pop-Location }
