<#
.SYNOPSIS
  Pusha il branch corrente su entrambi i remote del monorepo (origin=Gitea, github=GitHub).
.DESCRIPTION
  Vedi develop_microapps.md §5.7. Il License Server NON passa da qui: vive in una repo
  separata con il solo remote origin, e non deve mai finire su GitHub (ADR-001).
  Lo script si rifiuta di pushare se trova contenuto del server tracciato nel monorepo.
#>
[CmdletBinding()]
param([string] $Branch)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_common.ps1')
Push-Location (Get-RepoRoot)

try {
    if (-not $Branch) { $Branch = (git rev-parse --abbrev-ref HEAD).Trim() }

    # Rete di sicurezza: il server non deve essere tracciato nel monorepo.
    $tracked = git ls-files 'server/*' 2>$null | Where-Object { $_ -and $_ -notmatch '\.gitkeep$' }
    if ($tracked) {
        Write-Host 'BLOCCATO: il monorepo traccia file del server:' -ForegroundColor Red
        $tracked | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        Write-Host 'Il server deve stare nella sua repo Gitea. Vedi ADR-001.' -ForegroundColor Red
        exit 1
    }

    foreach ($remote in @('origin', 'github')) {
        Write-Section "push $Branch -> $remote"
        git push -u $remote $Branch | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "push su $remote fallito" }
    }
    Write-Host ''
    Write-Host "$Branch pushato su origin e github." -ForegroundColor Green
} finally { Pop-Location }
