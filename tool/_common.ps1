<#
  Funzioni condivise dagli script di tool/. Non si esegue da solo.
#>

$script:RepoRoot = Split-Path -Parent $PSScriptRoot

function Get-RepoRoot { return $script:RepoRoot }

function Get-FlutterBat {
    $bat = Join-Path $script:RepoRoot '.flutter\bin\flutter.bat'
    if (-not (Test-Path $bat)) {
        throw "Toolchain Flutter del progetto assente. Esegui: pwsh tool/get_flutter.ps1"
    }
    return $bat
}

function Get-DartExe {
    $exe = Join-Path $script:RepoRoot '.flutter\bin\dart.bat'
    if (-not (Test-Path $exe)) {
        throw "Toolchain Flutter del progetto assente. Esegui: pwsh tool/get_flutter.ps1"
    }
    return $exe
}

# I progetti Dart del monorepo, in ordine di dipendenza: micro_core prima delle app.
function Get-DartProjects {
    $projects = @()
    $core = Join-Path $script:RepoRoot 'packages\micro_core'
    if (Test-Path (Join-Path $core 'pubspec.yaml')) {
        $projects += [pscustomobject]@{ Name = 'micro_core'; Path = $core }
    }
    # micro_share (F17.2b): ricezione da Share Sheet, prima delle app che lo usano.
    $share = Join-Path $script:RepoRoot 'packages\micro_share'
    if (Test-Path (Join-Path $share 'pubspec.yaml')) {
        $projects += [pscustomobject]@{ Name = 'micro_share'; Path = $share }
    }
    # micro_ocr (F12.2b): OCR sul telefono (plugin Android ORT + iOS Vision), prima delle app.
    $ocr = Join-Path $script:RepoRoot 'packages\micro_ocr'
    if (Test-Path (Join-Path $ocr 'pubspec.yaml')) {
        $projects += [pscustomobject]@{ Name = 'micro_ocr'; Path = $ocr }
    }
    $appsDir = Join-Path $script:RepoRoot 'apps'
    if (Test-Path $appsDir) {
        Get-ChildItem $appsDir -Directory | Sort-Object Name | ForEach-Object {
            if (Test-Path (Join-Path $_.FullName 'pubspec.yaml')) {
                $projects += [pscustomobject]@{ Name = $_.Name; Path = $_.FullName }
            }
        }
    }
    return $projects
}

function Write-Section([string] $Title) {
    Write-Host ''
    Write-Host ('=' * 72) -ForegroundColor DarkGray
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host ('=' * 72) -ForegroundColor DarkGray
}
