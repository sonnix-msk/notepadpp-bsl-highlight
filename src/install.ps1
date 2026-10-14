# Установщик подсветки BSL (1С:Предприятие) для Notepad++.
# Ставит плагин NppTreeSitter + грамматику tree-sitter-bsl + конфиг.
# Запускается из INSTALL.bat. Права администратора нужны, если Notepad++
# установлен в Program Files. Поддерживаются 64- и 32-разрядный Notepad++ 8.x.

param(
    [string]$NppDir = ""
)

$ErrorActionPreference = 'Stop'
$Here = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Files = Join-Path $Here 'files'

function Info($m) { Write-Host $m }
function Ok($m)   { Write-Host $m -ForegroundColor Green }
function Warn($m) { Write-Host $m -ForegroundColor Yellow }
function Err($m)  { Write-Host $m -ForegroundColor Red }

function Test-Writable($dir) {
    try {
        if (-not (Test-Path -LiteralPath $dir)) { return $false }
        $f = Join-Path $dir ('.wtest_' + [guid]::NewGuid().ToString('N'))
        Set-Content -LiteralPath $f -Value 'x' -ErrorAction Stop
        Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue
        return $true
    } catch { return $false }
}

function Get-PEMachine($path) {
    try {
        $fs = [System.IO.File]::OpenRead($path)
        $br = New-Object System.IO.BinaryReader($fs)
        $fs.Position = 0x3C
        $pe = $br.ReadInt32()
        $fs.Position = $pe + 4
        $m = $br.ReadUInt16()
        $fs.Close()
        return $m
    } catch { return 0 }
}

function Resolve-Npp([string]$hint) {
    if ($hint -and (Test-Path -LiteralPath (Join-Path $hint 'notepad++.exe'))) { return $hint }
    foreach ($key in @('HKLM:\SOFTWARE\Notepad++', 'HKLM:\SOFTWARE\WOW6432Node\Notepad++')) {
        try {
            $v = (Get-ItemProperty -LiteralPath $key -ErrorAction Stop).'(default)'
            if ($v -and (Test-Path -LiteralPath (Join-Path $v 'notepad++.exe'))) { return $v }
        } catch {}
    }
    $cands = @(
        (Join-Path $env:ProgramFiles 'Notepad++'),
        (Join-Path ${env:ProgramFiles(x86)} 'Notepad++'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Notepad++'),
        'C:\Notepad++'
    )
    foreach ($c in $cands) {
        if ($c -and (Test-Path -LiteralPath (Join-Path $c 'notepad++.exe'))) { return $c }
    }
    return $null
}

Info ''
Info '====================================================='
Info '  Подсветка BSL (1C:Предприятие) для Notepad++'
Info '  Установщик'
Info '====================================================='
Info ''

# --- 1. Найти Notepad++ ----------------------------------------------------
$npp = Resolve-Npp $NppDir
if (-not $npp) {
    Warn 'Не удалось найти папку Notepad++ автоматически.'
    Info 'Укажите её вручную — перетащите папку Notepad++ в это окно'
    Info 'или вставьте путь (например: C:\Program Files\Notepad++) и нажмите Enter.'
    $npp = (Read-Host 'Папка Notepad++').Trim('"').Trim()
    if (-not (Test-Path -LiteralPath (Join-Path $npp 'notepad++.exe'))) {
        Err "В папке '$npp' нет notepad++.exe. Установка отменена."
        Read-Host 'Нажмите Enter для выхода'
        exit 1
    }
}
$npp = $npp.TrimEnd('\')

# --- 2. Разрядность --------------------------------------------------------
$nppExe = Join-Path $npp 'notepad++.exe'
$machine = Get-PEMachine $nppExe
switch ($machine) {
    0x8664  { $arch = 'x64' }
    0x014C  { $arch = 'x86' }
    0xAA64  { $arch = 'arm64' }
    default { $arch = 'x64' }
}
if ($arch -eq 'arm64') {
    Err 'Обнаружен Notepad++ для ARM64 — этот пакет пока поддерживает только x64 и x86.'
    Read-Host 'Нажмите Enter для выхода'
    exit 1
}
if (-not (Test-Path -LiteralPath (Join-Path $Files "$arch\plugins"))) {
    Err "В пакете нет файлов для $arch. Возьмите полный архив."
    Read-Host 'Нажмите Enter для выхода'
    exit 1
}

$pluginsDir = Join-Path $npp 'plugins'

# --- 3. Права --------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not (Test-Writable $npp)) {
    if (-not $isAdmin) {
        Warn 'Для записи в папку Notepad++ нужны права администратора.'
        Info 'Сейчас будет запрошено разрешение (кнопка «Да» в окне UAC)...'
        $args = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`" -NppDir `"$npp`""
        try {
            Start-Process -FilePath 'powershell.exe' -ArgumentList $args -Verb RunAs
        } catch {
            Err 'Запуск с правами администратора отменён. Установка не выполнена.'
            Read-Host 'Нажмите Enter для выхода'
            exit 1
        }
        exit 0
    } else {
        Err "Нет доступа на запись в '$npp' даже с правами администратора."
        Read-Host 'Нажмите Enter для выхода'
        exit 1
    }
}

# --- 4. Notepad++ должен быть закрыт ---------------------------------------
$running = Get-Process -Name 'notepad++' -ErrorAction SilentlyContinue
if ($running) {
    Err 'Notepad++ сейчас запущен.'
    Err 'Закройте все окна Notepad++ и запустите установку снова.'
    Read-Host 'Нажмите Enter для выхода'
    exit 1
}

Info "Notepad++ найден: $npp"
Info "Разрядность:      $arch"
Info ''

# --- 5. Копирование --------------------------------------------------------
function Copy-Tree($src, $dstRoot) {
    Get-ChildItem -LiteralPath $src -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($src.Length).TrimStart('\')
        $target = Join-Path $dstRoot $rel
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        Copy-Item -LiteralPath $_.FullName -Destination $target -Force
        Info ("  + " + $rel)
    }
}

Info 'Копирование плагина и грамматики:'
Copy-Tree (Join-Path $Files "$arch\plugins\TreeSitterLexer") (Join-Path $pluginsDir 'TreeSitterLexer')

Info ''
Info 'Настройка подсветки (Config):'
$cfgDstDir = Join-Path $pluginsDir 'Config'
New-Item -ItemType Directory -Force -Path $cfgDstDir | Out-Null
$cfgDst = Join-Path $cfgDstDir 'TreeSitterLexer.xml'
if (Test-Path -LiteralPath $cfgDst) {
    $bak = $cfgDst + '.bak-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
    Copy-Item -LiteralPath $cfgDst -Destination $bak -Force
    Warn "  прежний конфиг сохранён в: $bak"
}
Copy-Item -LiteralPath (Join-Path $Files 'plugins\Config\TreeSitterLexer.xml') -Destination $cfgDst -Force
Info '  + Config\TreeSitterLexer.xml'

# --- 6. Итог ---------------------------------------------------------------
Info ''
Ok 'Готово! Подсветка установлена.'
Info ''
Info 'Как проверить:'
Info '  1) Откройте Notepad++.'
Info '  2) Откройте файл .bsl (или example.bsl из этого архива).'
Info '  3) Код будет подсвечен. Язык виден в меню: Языки -> T -> treesitter.bsl.'
Info ''
Info 'Как удалить:'
Info "  удалите папку  $pluginsDir\TreeSitterLexer"
Info "  и файл         $pluginsDir\Config\TreeSitterLexer.xml"
Info ''
Read-Host 'Нажмите Enter для выхода'
