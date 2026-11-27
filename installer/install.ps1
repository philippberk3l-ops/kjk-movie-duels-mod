# Installs the KJK Lightsaber and Player Model mod.
#
# The mod ships only its own program. It reads KOTOR, Jedi Academy and
# Movie Duels from the player's own installs, as KJK itself does, and never
# copies or changes their files.

param(
    # Install even when a requirement is not found.
    [switch]$Force,
    # Only list what the mod needs and what was found.
    [switch]$CheckOnly,
    # Make no desktop or Start menu shortcut.
    [switch]$NoShortcuts
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path $env:LOCALAPPDATA 'Programs\KJK'
$backup = 'kjk.exe.before-lightsaber-mod'
$name = 'KJK Lightsaber Mod'

function Say($text, $color = 'Gray') { Write-Host $text -ForegroundColor $color }

# Every Steam library folder on this computer.
function Steam-Libraries {
    $libraries = @()
    foreach ($key in 'HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam') {
        $steam = (Get-ItemProperty -Path $key -ErrorAction SilentlyContinue)
        $path = if ($steam.SteamPath) { $steam.SteamPath } else { $steam.InstallPath }
        if (-not $path) { continue }
        $path = $path -replace '/', '\'
        $libraries += $path
        $vdf = Join-Path $path 'steamapps\libraryfolders.vdf'
        if (Test-Path $vdf) {
            foreach ($line in Get-Content $vdf) {
                if ($line -match '"path"\s+"([^"]+)"') {
                    $libraries += ($Matches[1] -replace '\\\\', '\')
                }
            }
        }
    }
    $libraries | Select-Object -Unique
}

# Every game folder GOG Galaxy and GOG's installers registered.
function Gog-Folders {
    $folders = @()
    foreach ($key in 'HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games', 'HKLM:\SOFTWARE\GOG.com\Games') {
        if (-not (Test-Path $key)) { continue }
        foreach ($game in Get-ChildItem $key) {
            $path = (Get-ItemProperty -Path $game.PSPath -ErrorAction SilentlyContinue).path
            if ($path) { $folders += $path }
        }
    }
    $folders
}

# The first folder among the Steam and GOG installs that holds `file`.
function Find-Game($steamFolder, $file) {
    foreach ($library in Steam-Libraries) {
        $folder = Join-Path $library "steamapps\common\$steamFolder"
        if (Test-Path (Join-Path $folder $file)) { return $folder }
    }
    foreach ($folder in Gog-Folders) {
        if (Test-Path (Join-Path $folder $file)) { return $folder }
    }
    return $null
}

Say ''
Say "$name installer" 'Cyan'
Say ''
Say 'Checking what the mod needs...'
Say ''

$kotor1 = Find-Game 'swkotor' 'swkotor.exe'
$kotor2 = Find-Game 'Knights of the Old Republic II' 'swkotor2.exe'
$academy = Find-Game 'Jedi Academy' 'GameData\base\assets0.pk3'
$movieDuels = if ($env:KJK_MOVIEDUELS) { $env:KJK_MOVIEDUELS }
    elseif ($academy) { Join-Path $academy 'GameData\MD' }
$movieDuelsFiles = 'MD_Hilts.pk3', 'MD_Assets2.pk3'
$movieDuelsFound = $movieDuels -and -not ($movieDuelsFiles | Where-Object {
    -not (Test-Path (Join-Path $movieDuels $_))
})

$missing = @()
function Report($what, $folder, $need) {
    if ($folder) {
        Say "  Found:     $what ($folder)" 'Green'
    } else {
        Say "  Not found: $what. $need" 'Yellow'
    }
}
Report 'Star Wars: Knights of the Old Republic' $kotor1 'You need it to play the KOTOR 1 campaign.'
Report 'Star Wars: Knights of the Old Republic II' $kotor2 'KJK draws its menus and Lightsaber Creation from it.'
Report 'Star Wars Jedi Knight: Jedi Academy' $academy 'KJK needs it for its combat.'
if ($movieDuelsFound) {
    Say "  Found:     Movie Duels ($movieDuels)" 'Green'
} else {
    Say '  Not found: Movie Duels. The mod takes its hilts, stances and player models from it.' 'Yellow'
    Say '             Install Movie Duels into Jedi Academy''s GameData\MD folder, or set the' 'Yellow'
    Say '             KJK_MOVIEDUELS environment variable to the folder that holds MD_Hilts.pk3.' 'Yellow'
}
if (-not $kotor2) { $missing += 'KOTOR 2' }
if (-not $academy) { $missing += 'Jedi Academy' }
if (-not $movieDuelsFound) { $missing += 'Movie Duels' }
# The game needs Microsoft's Visual C++ runtime (2015 to 2022), as Movie
# Duels does. Nearly every PC has it; a fresh Windows may not. Proton has
# its own, so this is told only, never a reason to stop.
$runtime = Join-Path $env:SystemRoot 'System32\vcruntime140.dll'
if (-not (Test-Path $runtime)) {
    Say '  Not found: the Microsoft Visual C++ runtime. KJK needs it to start.' 'Yellow'
    Say '             Install it from https://aka.ms/vs/17/release/vc_redist.x64.exe' 'Yellow'
}
Say ''

if ($CheckOnly) {
    if ($missing.Count -gt 0) { Say "Missing: $($missing -join ', ')." 'Yellow' } else { Say 'Everything the mod needs is installed.' 'Green' }
    exit 0
}
if ($missing.Count -gt 0 -and -not $Force) {
    Say "The mod cannot be installed yet. These are missing: $($missing -join ', ')." 'Red'
    Say 'Install them and run this installer again. If they are installed in a place this'
    Say 'installer does not look, run "Install.bat -Force". KJK''s first-run setup then lets'
    Say 'you choose the game folders yourself.'
    exit 1
}

# Install, keeping the KJK that was there.
New-Item -ItemType Directory -Force -Path $target | Out-Null
$exe = Join-Path $target 'kjk.exe'
$kept = Join-Path $target $backup
if ((Test-Path $exe) -and -not (Test-Path $kept)) {
    Copy-Item $exe $kept
    Say "Your current kjk.exe is kept as $backup. The uninstaller puts it back."
}
try {
    Copy-Item (Join-Path $here 'kjk.exe') $exe -Force
} catch {
    Say 'kjk.exe could not be replaced. Close KJK and run the installer again.' 'Red'
    exit 1
}
foreach ($file in 'README.txt', 'LICENSE.txt', 'NOTICE.txt', 'THIRD-PARTY-LICENSES.html', 'uninstall.ps1', 'Uninstall.bat') {
    $from = Join-Path $here $file
    if (Test-Path $from) { Copy-Item $from (Join-Path $target "lightsaber-mod-$file") -Force }
}

# Shortcuts on the desktop and in the Start menu.
$shell = New-Object -ComObject WScript.Shell
$menu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$folders = if ($NoShortcuts) { @() } else { @([Environment]::GetFolderPath('Desktop'), $menu) }
foreach ($folder in $folders) {
    $link = $shell.CreateShortcut((Join-Path $folder "$name.lnk"))
    $link.TargetPath = $exe
    $link.WorkingDirectory = $target
    $link.Description = 'KJK with Lightsaber Creation, Movie Duels stances and player models'
    $link.Save()
}
# The uninstaller in the Start menu, beside the game.
if (-not $NoShortcuts) {
    $link = $shell.CreateShortcut((Join-Path $menu "Uninstall $name.lnk"))
    $link.TargetPath = Join-Path $target 'lightsaber-mod-Uninstall.bat'
    $link.WorkingDirectory = $target
    $link.Description = 'Removes the mod and puts back the earlier kjk.exe'
    $link.Save()
}

Say ''
Say "$name is installed in $target." 'Green'
if ($NoShortcuts) {
    Say "Start it with kjk.exe in that folder. On its first start, KJK's setup finds your games,"
} else {
    Say 'Start it from the desktop shortcut or the Start menu. On its first start, KJK''s setup'
    Say 'finds your games,'
}
Say 'or asks you where they are. In the game, Lightsaber Creation is under Options > Gameplay,'
Say 'and the player model is under Options > Graphics > Interface.'
