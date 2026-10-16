# Локальная сборка дистрибутива с ПРОПАТЧЕННЫМ плагином из собственного форка
# NppTreeSitter. Публичный make-release.ps1 при этом НЕ изменяется: этот скрипт
# вызывает его как есть (качает стоковый плагин, собирает грамматику), затем
# подменяет TreeSitterLexer.dll на собранный из форка и переупаковывает.
#
# Схема форка, ветки и порядок обновления из апстрима — в docs/HANDOFF.md
# (раздел «Форк плагина») и docs/UPSTREAM.md.
#
# Примеры:
#   .\make-release-local.ps1                 # взять уже собранные DLL из форка
#   .\make-release-local.ps1 -BuildPlugin    # сперва собрать плагин из форка
#   .\make-release-local.ps1 -ForkDir D:\path\to\NppTreeSitter

[CmdletBinding()]
param(
    [string]$ForkDir = 'D:\OpenCode\Форки\NppTreeSitter',
    [string]$OutDir  = '',
    [switch]$BuildPlugin
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Info($m) { Write-Host $m }
function Err($m)  { Write-Host $m -ForegroundColor Red }

$Build = $PSScriptRoot
$Repo  = Split-Path -Parent $Build
if (-not $OutDir) { $OutDir = Join-Path $Repo 'dist-local' }

# --- 1. Пути к собранному плагину в форке ----------------------------------
$plugins = @{
    x64 = Join-Path $ForkDir 'build\x64\Release\TreeSitterLexer.dll'
    x86 = Join-Path $ForkDir 'build\Win32\Release\TreeSitterLexer.dll'
}

# --- 2. При необходимости собрать плагин из форка (MSBuild) ----------------
if ($BuildPlugin) {
    if (-not (Test-Path -LiteralPath $ForkDir)) { Err "Нет каталога форка: $ForkDir"; exit 1 }
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (-not (Test-Path -LiteralPath $vswhere)) { Err 'Не найден vswhere.exe (Visual Studio Installer).'; exit 1 }
    $msbuild = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -find 'MSBuild\**\Bin\MSBuild.exe' | Select-Object -First 1
    if (-not $msbuild) { Err 'Не найден MSBuild. Нужны VS Build Tools с C++.'; exit 1 }
    $proj = Join-Path $ForkDir 'NppTreeSitter.vcxproj'
    if (-not (Test-Path -LiteralPath $proj)) { Err "Нет NppTreeSitter.vcxproj в $ForkDir"; exit 1 }
    Info '=== Сборка плагина из форка (x64 + Win32) ==='
    foreach ($plat in @('x64', 'Win32')) {
        Info "MSBuild -p:Platform=$plat"
        & $msbuild $proj -p:Configuration=Release -p:Platform=$plat -m -v:minimal
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { Err "Сборка плагина ($plat) не удалась."; exit 1 }
    }
}

foreach ($a in @('x64', 'x86')) {
    if (-not (Test-Path -LiteralPath $plugins[$a])) {
        Err "Нет DLL плагина ($a): $($plugins[$a]). Запустите с -BuildPlugin."
        exit 1
    }
}

# --- 3. Публичная сборка (стоковый плагин + наша грамматика) ----------------
Info "=== Публичная сборка в $OutDir ==="
$global:LASTEXITCODE = 0
& (Join-Path $Build 'make-release.ps1') -OutDir $OutDir
if (-not $? -or ($LASTEXITCODE -and $LASTEXITCODE -ne 0)) { Err 'make-release.ps1 завершился с ошибкой.'; exit 1 }

# --- 4. Подмена DLL на пропатченные из форка -------------------------------
$pkgFiles = Join-Path $OutDir 'Notepad++-BSL\files'
foreach ($a in @('x64', 'x86')) {
    $dst = Join-Path $pkgFiles "$a\plugins\TreeSitterLexer\TreeSitterLexer.dll"
    Copy-Item -LiteralPath $plugins[$a] -Destination $dst -Force
    Info "Подменён плагин $a -> $dst"
}

# --- 5. Переупаковка в отдельный архив (публичный zip не трогаем) -----------
$pkgRoot = Join-Path $OutDir 'Notepad++-BSL'
$zipOut  = Join-Path $OutDir 'Notepad++-BSL-local.zip'
Remove-Item -LiteralPath $zipOut -Force -ErrorAction SilentlyContinue
Compress-Archive -Path $pkgRoot -DestinationPath $zipOut -Force

$hash = (Get-FileHash -LiteralPath $zipOut -Algorithm SHA256).Hash
Info ''
Info "Пакет (локальный): $pkgRoot"
Info "Архив (локальный): $zipOut ($((Get-Item -LiteralPath $zipOut).Length) байт)"
Info "SHA256: $hash"
