@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
if errorlevel 1 goto fail
exit /b 0
:fail
echo.
echo [!] N e u d a l o s   z a p u s t i t   u s t a n o v k u.
echo [!] Proverte, chto PowerShell dostupen, i zapustite USTANOVIT.bat snova.
echo.
pause
