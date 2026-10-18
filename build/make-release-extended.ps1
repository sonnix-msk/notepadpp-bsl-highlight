# Сборка РАСШИРЕННОЙ (авторской) вариации дистрибутива: с ПРОПАТЧЕННЫМ плагином из
# собственного форка NppTreeSitter. Стандартная (публичная) вариация собирается
# make-release.ps1 и НЕ изменяется: этот скрипт вызывает её как есть (качает стоковый
# плагин, собирает грамматику), затем подменяет TreeSitterLexer.dll на собранный из
# форка и переупаковывает в отдельный архив.
#
# Две вариации (см. docs/HANDOFF.md, «Две вариации дистрибутива»):
#   Standard  : build\make-release.ps1          -> dist\Notepad++-BSL.zip
#   Extended  : build\make-release-extended.ps1 -> dist-extended\Notepad++-BSL-extended.zip
#
# Расширенная вариация добавляет: авто-детект .bsl/.os, фикс сворачивания, корректные
# стили/шрифт, подсветку запросов SDBL (фрагменты в строках .bsl и отдельные .sdbl/.1cquery).
# Требует пропатченного лексера и грамматики tree-sitter-sdbl.dll.
#
# Примеры:
#   .\make-release-extended.ps1                 # взять уже собранные DLL из форка
#   .\make-release-extended.ps1 -BuildPlugin    # сперва собрать плагин из форка
#   .\make-release-extended.ps1 -SkipSdbl       # не собирать sdbl (нет MSVC/сеть)
#   .\make-release-extended.ps1 -ForkDir D:\path\to\NppTreeSitter

[CmdletBinding()]
param(
    [string]$ForkDir = 'D:\OpenCode\Форки\NppTreeSitter',
    [string]$OutDir  = '',
    [switch]$BuildPlugin,
    [switch]$SkipSdbl
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Info($m) { Write-Host $m }
function Err($m)  { Write-Host $m -ForegroundColor Red }

$Build = $PSScriptRoot
$Repo  = Split-Path -Parent $Build
$Src   = Join-Path $Repo 'src'
if (-not $OutDir) { $OutDir = Join-Path $Repo 'dist-extended' }

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

# --- 3. Базовая сборка (стоковый плагин + наша грамматика) -----------------
Info "=== Базовая сборка в $OutDir ==="
$global:LASTEXITCODE = 0
& (Join-Path $Build 'make-release.ps1') -OutDir $OutDir
if (-not $? -or ($LASTEXITCODE -and $LASTEXITCODE -ne 0)) { Err 'make-release.ps1 завершился с ошибкой.'; exit 1 }

# --- 3б. Грамматика SDBL (язык запросов) -----------------------------------
$sdblReady = $false
if (-not $SkipSdbl) {
    Info '=== Сборка грамматики tree-sitter-sdbl ==='
    try {
        & (Join-Path $Build 'build-sdbl-grammar.ps1') -Platform both -OutDir (Join-Path $OutDir 'grammars')
        $sdblReady = ($LASTEXITCODE -eq 0 -or -not $LASTEXITCODE)
    } catch {
        Err "Грамматика sdbl не собрана: $($_.Exception.Message)"
        $sdblReady = $false
    }
    foreach ($a in @('x64', 'x86')) {
        if (-not (Test-Path -LiteralPath (Join-Path $OutDir "grammars\$a\tree-sitter-sdbl.dll"))) { $sdblReady = $false }
    }
    if (-not $sdblReady) {
        Err 'Нет tree-sitter-sdbl.dll — подсветка запросов в пакете будет отключена.'
        Err 'Повторите с сетью/MSVC или уберите -SkipSdbl, когда сможете собрать.'
    }
}

# --- 4. Подмена DLL на пропатченные из форка -------------------------------
$pkgFiles = Join-Path $OutDir 'Notepad++-BSL\files'
foreach ($a in @('x64', 'x86')) {
    $tsg = Join-Path $pkgFiles "$a\plugins\TreeSitterLexer\TreeSitterGrammars"
    New-Item -ItemType Directory -Force -Path $tsg | Out-Null

    $dst = Join-Path $pkgFiles "$a\plugins\TreeSitterLexer\TreeSitterLexer.dll"
    Copy-Item -LiteralPath $plugins[$a] -Destination $dst -Force
    Info "Подменён плагин $a -> $dst"

    if ($sdblReady) {
        Copy-Item -LiteralPath (Join-Path $OutDir "grammars\$a\tree-sitter-sdbl.dll") -Destination $tsg -Force
        Copy-Item -LiteralPath (Join-Path $Src 'sdbl-highlights.scm') -Destination $tsg -Force
        # Scorer lexicon: the plugin reads it from the grammar dir, one file per
        # architecture. Without it the SDBL fragment pass silently does nothing.
        $lexicon = Join-Path $Src 'bsl-query-fragments.json'
        if (-not (Test-Path -LiteralPath $lexicon)) {
            Err "Нет $lexicon — подсветка фрагментов запросов не будет работать."
            exit 1
        }
        Copy-Item -LiteralPath $lexicon -Destination $tsg -Force
        Info "Добавлена грамматика SDBL ($a) + sdbl-highlights.scm + bsl-query-fragments.json"
    }
}

# --- 5. Переупаковка в архив расширенной вариации --------------------------
$pkgRoot     = Join-Path $OutDir 'Notepad++-BSL'
$zipOut      = Join-Path $OutDir 'Notepad++-BSL-extended.zip'
$strayStock  = Join-Path $OutDir 'Notepad++-BSL.zip'   # базовая сборка его создала
Remove-Item -LiteralPath $zipOut -Force -ErrorAction SilentlyContinue
Compress-Archive -Path $pkgRoot -DestinationPath $zipOut -Force
Remove-Item -LiteralPath $strayStock -Force -ErrorAction SilentlyContinue

$hash = (Get-FileHash -LiteralPath $zipOut -Algorithm SHA256).Hash
Info ''
Info "Пакет (расширенный): $pkgRoot"
Info "Архив (расширенный): $zipOut ($((Get-Item -LiteralPath $zipOut).Length) байт)"
Info "SHA256: $hash"
