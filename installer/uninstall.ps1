# Removes the KJK Lightsaber and Player Model mod and puts back the
# kjk.exe the installer kept. Saves and settings are left as they are.

$ErrorActionPreference = 'Stop'
$target = Join-Path $env:LOCALAPPDATA 'Programs\KJK'
$exe = Join-Path $target 'kjk.exe'
$kept = Join-Path $target 'kjk.exe.before-lightsaber-mod'
$name = 'KJK Lightsaber Mod'

try {
    if (Test-Path $kept) {
        Copy-Item $kept $exe -Force
        Remove-Item $kept
        Write-Host 'Your earlier kjk.exe is back.' -ForegroundColor Green
    } else {
        Remove-Item $exe -ErrorAction SilentlyContinue
        Write-Host 'The mod''s kjk.exe is removed. There was no earlier KJK to put back.' -ForegroundColor Green
    }
} catch {
    Write-Host 'kjk.exe could not be changed. Close KJK and run the uninstaller again.' -ForegroundColor Red
    exit 1
}
Get-ChildItem $target -Filter 'lightsaber-mod-*' | Remove-Item
$menu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
foreach ($folder in [Environment]::GetFolderPath('Desktop'), $menu) {
    Remove-Item (Join-Path $folder "$name.lnk") -ErrorAction SilentlyContinue
}
Remove-Item (Join-Path $menu "Uninstall $name.lnk") -ErrorAction SilentlyContinue
Write-Host 'The mod is uninstalled. Your saves and settings are kept.'
