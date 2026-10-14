# Сборка дистрибутива (installer package) подсветки BSL для Notepad++.
# Скачивает плагин NppTreeSitter (x64 и x86), собирает грамматику tree-sitter-bsl
# и укладывает всё в dist\Notepad++-BSL + zip.
#
# Примеры:
#   .\make-release.ps1
#   .\make-release.ps1 -SkipBuild     # использовать уже собранные dist\grammars\*

[CmdletBinding()]
param(
    [string]$OutDir = '',
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if (-not $OutDir) { $OutDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'dist' }

function Info($m) { Write-Host $m }
function Err($m)  { Write-Host $m -ForegroundColor Red }

$Repo = Split-Path -Parent $PSScriptRoot
$Src  = Join-Path $Repo 'src'
$versions = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'versions.psd1')

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# --- 1. Грамматика (x64 + x86) ---------------------------------------------
$grammars = Join-Path $OutDir 'grammars'
if (-not $SkipBuild) {
    Info '=== Сборка грамматики tree-sitter-bsl (x64 + x86) ==='
    & (Join-Path $PSScriptRoot 'build-grammar.ps1') -Platform both -OutDir $grammars
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { Err 'build-grammar.ps1 завершился с ошибкой.'; exit 1 }
}
foreach ($a in @('x64', 'x86')) {
    if (-not (Test-Path -LiteralPath (Join-Path $grammars "$a\tree-sitter-bsl.dll"))) {
        Err "Нет грамматики для $a. Запустите без -SkipBuild."
        exit 1
    }
}

# --- 2. Плагин NppTreeSitter (x64 + x86) -----------------------------------
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('tsrel-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$pluginDll = @{}
try {
    $map = @{ x64 = $versions.NppTreeSitter.UrlX64; x86 = $versions.NppTreeSitter.UrlX86 }
    foreach ($a in @('x64', 'x86')) {
        $zip = Join-Path $tmp "$a.zip"
        Info "Скачивание плагина ($a): $($map[$a])"
        Invoke-WebRequest -UseBasicParsing -Uri $map[$a] -OutFile $zip
        $ex = Join-Path $tmp "npp-$a"
        Expand-Archive -LiteralPath $zip -DestinationPath $ex -Force
        $dll = Join-Path $ex 'TreeSitterLexer.dll'
        if (-not (Test-Path -LiteralPath $dll)) { Err "Нет TreeSitterLexer.dll в архиве $a."; exit 1 }
        $pluginDll[$a] = $dll
    }

    # --- 3. Сборка пакета ---------------------------------------------------
    $pkgRoot = Join-Path $OutDir 'Notepad++-BSL'
    $pkgFiles = Join-Path $pkgRoot 'files'
    Remove-Item -LiteralPath $pkgRoot -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path $pkgFiles | Out-Null

    # верхний уровень
    Copy-Item -LiteralPath (Join-Path $Src 'INSTALL.bat')        -Destination $pkgRoot -Force
    Copy-Item -LiteralPath (Join-Path $Src 'install.ps1')        -Destination $pkgRoot -Force
    Copy-Item -LiteralPath (Join-Path $Src 'README-install.txt') -Destination (Join-Path $pkgRoot 'README.txt') -Force
    Copy-Item -LiteralPath (Join-Path $Src 'example.bsl')        -Destination $pkgRoot -Force
    Copy-Item -LiteralPath (Join-Path $Repo 'LICENSE')           -Destination (Join-Path $pkgRoot 'LICENSE.txt') -Force -ErrorAction SilentlyContinue
    Copy-Item -LiteralPath (Join-Path $Repo 'NOTICE.md')         -Destination (Join-Path $pkgRoot 'NOTICE.txt') -Force -ErrorAction SilentlyContinue
    $licSrc = Join-Path $Repo 'LICENSES'
    if (Test-Path -LiteralPath $licSrc) {
        Copy-Item -LiteralPath $licSrc -Destination (Join-Path $pkgRoot 'LICENSES') -Recurse -Force
    }

    # общий конфиг
    $cfgDir = Join-Path $pkgFiles 'plugins\Config'
    New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null
    Copy-Item -LiteralPath (Join-Path $Src 'TreeSitterLexer.xml') -Destination (Join-Path $cfgDir 'TreeSitterLexer.xml') -Force

    # по архитектурам
    foreach ($a in @('x64', 'x86')) {
        $tsg = Join-Path $pkgFiles "$a\plugins\TreeSitterLexer\TreeSitterGrammars"
        New-Item -ItemType Directory -Force -Path $tsg | Out-Null
        Copy-Item -LiteralPath $pluginDll[$a]                          -Destination (Join-Path $pkgFiles "$a\plugins\TreeSitterLexer\TreeSitterLexer.dll") -Force
        Copy-Item -LiteralPath (Join-Path $grammars "$a\tree-sitter-bsl.dll") -Destination $tsg -Force
        Copy-Item -LiteralPath (Join-Path $Src 'bsl-highlights.scm')   -Destination $tsg -Force
    }

    # --- 4. ZIP -------------------------------------------------------------
    $zipOut = Join-Path $OutDir 'Notepad++-BSL.zip'
    Remove-Item -LiteralPath $zipOut -Force -ErrorAction SilentlyContinue
    Compress-Archive -Path $pkgRoot -DestinationPath $zipOut -Force

    Info ''
    Info "Пакет:  $pkgRoot"
    Info "Архив:  $zipOut ($((Get-Item -LiteralPath $zipOut).Length) байт)"
} finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
