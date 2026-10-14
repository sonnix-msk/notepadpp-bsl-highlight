# Сборка tree-sitter-bsl.dll из исходников грамматики.
# Скачивает исходники tree-sitter-bsl нужной версии и компилирует parser.c
# для выбранных архитектур через MSVC (Build Tools).
#
# Примеры:
#   .\build-grammar.ps1 -Platform both -OutDir ..\dist\grammars
#   .\build-grammar.ps1 -Platform x86

[CmdletBinding()]
param(
    [ValidateSet('x64', 'x86', 'both')]
    [string]$Platform = 'both',
    [string]$Version = '',
    [string]$OutDir = ''
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if (-not $OutDir) { $OutDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'dist\grammars' }

function Info($m) { Write-Host $m }
function Err($m)  { Write-Host $m -ForegroundColor Red }

$versions = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'versions.psd1')
if (-not $Version) { $Version = $versions.TreeSitterBsl.Version }
$Url = $versions.TreeSitterBsl.Url
# подставить версию, если в psd1 она зашита — оставляем URL как есть, но напоминаем
if ($Version -ne $versions.TreeSitterBsl.Version) {
    $Url = "https://github.com/alkoleft/tree-sitter-bsl/archive/refs/tags/v$Version.zip"
}

# --- MSVC ------------------------------------------------------------------
function Find-Vcvars {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (-not (Test-Path -LiteralPath $vswhere)) { return $null }
    $vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if (-not $vs) { return $null }
    $vcvars = Join-Path $vs 'VC\Auxiliary\Build\vcvarsall.bat'
    if (Test-Path -LiteralPath $vcvars) { return $vcvars }
    return $null
}

$vcvars = Find-Vcvars
if (-not $vcvars) {
    Err 'Не найден MSVC (Visual Studio Build Tools с C++). Установите Build Tools.'
    exit 1
}
Info "MSVC: $vcvars"

# --- Исходники грамматики --------------------------------------------------
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('tsbsl-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
try {
    $zip = Join-Path $tmp 'grammar.zip'
    Info "Скачивание $Url"
    Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $zip
    Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force

    $srcRoot = (Get-ChildItem -LiteralPath $tmp -Directory -Filter 'tree-sitter-bsl-*' | Select-Object -First 1).FullName
    if (-not $srcRoot) { Err 'Не найдена папка исходников в архиве.'; exit 1 }
    $bsl = Join-Path $srcRoot 'grammars\bsl'
    $parser = Join-Path $bsl 'src\parser.c'
    if (-not (Test-Path -LiteralPath $parser)) { Err "Нет parser.c: $parser"; exit 1 }
    Info "Исходники: $bsl"

    $targets = switch ($Platform) { 'both' { @('x64', 'x86') } default { @($Platform) } }

    # Version resource (gives the DLL real metadata; reduces AV false positives).
    $RcFile = Join-Path $PSScriptRoot 'grammar.rc'
    $resFile = Join-Path $tmp 'grammar.res'
    if (Test-Path -LiteralPath $RcFile) {
        $rcCmd = 'call "{0}" x64 >nul 2>&1 && rc /nologo /fo "{1}" "{2}"' -f $vcvars, $resFile, $RcFile
        cmd /c $rcCmd
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $resFile)) {
            Err 'Не удалось скомпилировать ресурс версии (grammar.rc).'
            exit 1
        }
        Info "Ресурс версии: $resFile"
    } else {
        Info 'grammar.rc не найден — DLL будет без метаданных.'
    }

    foreach ($arch in $targets) {
        $outArch = Join-Path $OutDir $arch
        New-Item -ItemType Directory -Force -Path $outArch | Out-Null
        $foDir = Join-Path $tmp ("obj-$arch")
        New-Item -ItemType Directory -Force -Path $foDir | Out-Null
        $dll = Join-Path $outArch 'tree-sitter-bsl.dll'

        $inputs = '"src\parser.c"'
        if (Test-Path -LiteralPath $resFile) { $inputs += ' "' + $resFile + '"' }
        $cmd = 'call "{0}" {1} >nul 2>&1 && cd /d "{2}" && cl /nologo /LD /O2 /DNDEBUG /std:c11 /I "src" {3} /Fo:"{4}\\" /link /OUT:"{5}"' -f $vcvars, $arch, $bsl, $inputs, $foDir, $dll
        Info ''
        Info "=== Сборка $arch ==="
        cmd /c $cmd
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $dll)) {
            Err "Сборка $arch не удалась."
            exit 1
        }
        $size = (Get-Item -LiteralPath $dll).Length
        Info "OK: $dll ($size байт)"
    }
} finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Info ''
Info 'Готово.'
