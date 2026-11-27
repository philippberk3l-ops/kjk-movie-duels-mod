@echo off
rem Uninstalls the KJK Lightsaber Mod and puts back the earlier kjk.exe.
rem On the Steam Deck or Linux, run "bash install.sh --uninstall" instead.
reg query "HKCU\Software\Wine" >nul 2>nul && goto proton
if not exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" goto proton
if exist "%~dp0lightsaber-mod-uninstall.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0lightsaber-mod-uninstall.ps1"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
)
pause
exit /b
:proton
echo This uninstaller is for Windows. On the Steam Deck or on Linux, run:
echo     bash install.sh --uninstall
exit /b 1
