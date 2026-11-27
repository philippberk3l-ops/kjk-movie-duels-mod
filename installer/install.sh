#!/usr/bin/env bash
# Installs the KJK Lightsaber Mod on the Steam Deck and on Linux.
#
# Run it in Desktop Mode, from a terminal (Konsole) in this folder:
#     bash install.sh
# Do not run Install.bat through Proton or protontricks. A Proton prefix has
# no PowerShell, so Install.bat cannot work there.
#
# The mod ships only its own program. It reads KOTOR, Jedi Academy and Movie
# Duels from the player's own installs and never copies or changes them.
#
# Options:
#     --force       Install even when a requirement is not found.
#     --check-only  Only list what the mod needs and what was found.
#     --uninstall   Remove the mod and put back the kjk.exe it replaced.

set -u

name='KJK Lightsaber Mod'
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="${XDG_DATA_HOME:-$HOME/.local/share}/kjk-lightsaber-mod"
backup='kjk.exe.before-lightsaber-mod'
desktop_file="${XDG_DATA_HOME:-$HOME/.local/share}/applications/kjk-lightsaber-mod.desktop"

force=0
check_only=0
uninstall=0
for argument in "$@"; do
    case "$argument" in
        --force|-Force) force=1 ;;
        --check-only|-CheckOnly) check_only=1 ;;
        --uninstall) uninstall=1 ;;
        *) echo "Unknown option: $argument"; exit 2 ;;
    esac
done

green() { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }
red() { printf '\033[31m%s\033[0m\n' "$1"; }

if [ "$uninstall" = 1 ]; then
    if [ -f "$target/$backup" ]; then
        mv -f "$target/$backup" "$target/kjk.exe"
        green 'Your earlier kjk.exe is back.'
    else
        rm -f "$target/kjk.exe"
        green 'The mod'"'"'s kjk.exe is removed. There was no earlier KJK to put back.'
    fi
    rm -f "$target"/lightsaber-mod-* "$desktop_file"
    echo 'The mod is uninstalled. Your saves and settings are kept.'
    echo 'If you added kjk.exe to Steam as a non-Steam game, remove it from your library too.'
    exit 0
fi

# Every Steam library folder: the main Steam folders and each library that
# libraryfolders.vdf lists (a microSD card on the Steam Deck, for example).
steam_libraries() {
    local root vdf
    for root in "$HOME/.local/share/Steam" "$HOME/.steam/steam" "$HOME/.steam/root" \
        "$HOME/.var/app/com.valvesoftware.Steam/data/Steam"; do
        [ -d "$root/steamapps" ] || continue
        echo "$root"
        vdf="$root/steamapps/libraryfolders.vdf"
        [ -f "$vdf" ] && sed -n 's/^[[:space:]]*"path"[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p' "$vdf"
    done | awk '!seen[$0]++'
}

# The first Steam library folder that holds `file` in `folder`.
find_game() {
    local folder="$1" file="$2" library
    while IFS= read -r library; do
        if [ -e "$library/steamapps/common/$folder/$file" ]; then
            echo "$library/steamapps/common/$folder"
            return 0
        fi
    done < <(steam_libraries)
    return 1
}

# The Windows path a program run by Proton sees for a Linux path.
windows_path() {
    printf 'Z:%s\n' "$1" | sed 's#/#\\#g'
}

echo
printf '\033[36m%s\033[0m\n' "$name installer for the Steam Deck and Linux"
echo
echo 'Checking what the mod needs...'
echo

kotor1="$(find_game 'swkotor' 'swkotor.exe')"
kotor2="$(find_game 'Knights of the Old Republic II' 'swkotor2.exe')"
academy="$(find_game 'Jedi Academy' 'GameData/base/assets0.pk3')"
if [ -n "${KJK_MOVIEDUELS:-}" ]; then
    movie_duels="$KJK_MOVIEDUELS"
elif [ -n "$academy" ]; then
    movie_duels="$academy/GameData/MD"
else
    movie_duels=''
fi
movie_duels_found=0
if [ -n "$movie_duels" ] && [ -f "$movie_duels/MD_Hilts.pk3" ] && [ -f "$movie_duels/MD_Assets2.pk3" ]; then
    movie_duels_found=1
fi

missing=()
report() {
    if [ -n "$2" ]; then
        green "  Found:     $1 ($2)"
    else
        yellow "  Not found: $1. $3"
    fi
}
report 'Star Wars: Knights of the Old Republic' "$kotor1" 'You need it to play the KOTOR 1 campaign.'
report 'Star Wars: Knights of the Old Republic II' "$kotor2" 'KJK draws its menus and Lightsaber Creation from it.'
report 'Star Wars Jedi Knight: Jedi Academy' "$academy" 'KJK needs it for its combat.'
if [ "$movie_duels_found" = 1 ]; then
    green "  Found:     Movie Duels ($movie_duels)"
else
    yellow '  Not found: Movie Duels. The mod takes its hilts, stances and player models from it.'
    yellow '             Install Movie Duels into Jedi Academy'"'"'s GameData/MD folder, or set the'
    yellow '             KJK_MOVIEDUELS environment variable to the folder that holds MD_Hilts.pk3.'
fi
[ -z "$kotor2" ] && missing+=('KOTOR 2')
[ -z "$academy" ] && missing+=('Jedi Academy')
[ "$movie_duels_found" = 0 ] && missing+=('Movie Duels')
echo

join() { local IFS=','; echo "$*" | sed 's/,/, /g'; }

if [ "$check_only" = 1 ]; then
    if [ "${#missing[@]}" -gt 0 ]; then
        yellow "Missing: $(join "${missing[@]}")."
    else
        green 'Everything the mod needs is installed.'
    fi
    exit 0
fi
if [ "${#missing[@]}" -gt 0 ] && [ "$force" = 0 ]; then
    red "The mod cannot be installed yet. These are missing: $(join "${missing[@]}")."
    echo 'Install them and run this installer again. If they are installed in a place this'
    echo 'installer does not look, run "bash install.sh --force". KJK'"'"'s first-run setup'
    echo 'then lets you choose the game folders yourself.'
    exit 1
fi

# Install, keeping the KJK that was there.
mkdir -p "$target"
if [ -f "$target/kjk.exe" ] && [ ! -f "$target/$backup" ]; then
    cp -f "$target/kjk.exe" "$target/$backup"
    echo "Your current kjk.exe is kept as $backup. The uninstaller puts it back."
fi
if ! cp -f "$here/kjk.exe" "$target/kjk.exe"; then
    red 'kjk.exe could not be replaced. Close KJK and run the installer again.'
    exit 1
fi
chmod +x "$target/kjk.exe"
for file in README.txt LICENSE.txt NOTICE.txt THIRD-PARTY-LICENSES.html install.sh; do
    [ -f "$here/$file" ] && cp -f "$here/$file" "$target/lightsaber-mod-$file"
done

# A menu entry, so Steam's "Add a Non-Steam Game" window lists it.
mkdir -p "$(dirname "$desktop_file")"
cat > "$desktop_file" <<EOF
[Desktop Entry]
Type=Application
Name=$name
Comment=KJK with Lightsaber Creation, Movie Duels stances and player models
Exec="$target/kjk.exe"
Path=$target
Categories=Game;
Terminal=false
EOF

echo
green "$name is installed in $target."
echo
echo 'KJK is a Windows program, so Steam runs it with Proton. To add it to Steam:'
echo '  1. Open Steam in Desktop Mode and choose Games, then "Add a Non-Steam Game to My Library".'
echo "  2. Tick \"$name\". If it is not listed, choose Browse and pick"
echo "     $target/kjk.exe"
echo '  3. In your library, open the new entry'"'"'s Properties, then Compatibility.'
echo '     Tick "Force the use of a specific Steam Play compatibility tool" and choose'
echo '     Proton Experimental or the newest Proton.'
echo '  4. Start it from your library. It then also shows in Game Mode.'
echo
echo 'On its first start, KJK'"'"'s setup asks where your games are. Under Proton, your'
echo 'Linux folders are on drive Z. These are the folders to choose:'
[ -n "$kotor2" ] && echo "  KOTOR 2:       $(windows_path "$kotor2")"
[ -n "$kotor1" ] && echo "  KOTOR:         $(windows_path "$kotor1")"
[ -n "$academy" ] && echo "  Jedi Academy:  $(windows_path "$academy")"
echo
echo 'In the game, Lightsaber Creation is under Options > Gameplay, and the player model'
echo 'is under Options > Graphics > Interface.'
echo 'To uninstall, run "bash install.sh --uninstall" in this folder.'
