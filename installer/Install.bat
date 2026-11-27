@echo off
rem Installs the KJK Lightsaber Mod. Pass -Force to install without every requirement found.
rem On the Steam Deck or Linux, run install.sh instead. Proton has no PowerShell.
reg query "HKCU\Software\Wine" >nul 2>nul && goto proton
if not exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" goto proton
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
pause
exit /b
:proton
echo This installer is for Windows. It cannot run through Proton, Wine or protontricks.
echo On the Steam Deck or on Linux, open a terminal in Desktop Mode in this folder and run:
echo     bash install.sh
echo README.txt explains the steps under "Steam Deck and Linux".
exit /b 1
