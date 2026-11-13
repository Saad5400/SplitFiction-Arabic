#!/usr/bin/env bash
# Split Fiction - Arabic translation installer for Linux / Steam Deck (by Saad5400)
# https://github.com/Saad5400/SplitFiction-Arabic
#
#   curl -fsSL https://raw.githubusercontent.com/Saad5400/SplitFiction-Arabic/main/installer/install.sh | bash
#
# Options:  --game-path "<dir>"   --uninstall   --dry-run   --yes
set -euo pipefail

REPO="Saad5400/SplitFiction-Arabic"
PAK="Saad5400_SplitFiction_Arabic_999_P.pak"
OLD_PAKS=("MohammadFadel1987_P.pak" "zArabicTest_999_P.pak" "Arabic_Test_P.pak")
GAME_PATH=""; UNINSTALL=0; DRYRUN=0; YES=0

while [ $# -gt 0 ]; do
  case "$1" in
    --game-path) GAME_PATH="$2"; shift 2 ;;
    --uninstall) UNINSTALL=1; shift ;;
    --dry-run)   DRYRUN=1; shift ;;
    --yes|-y)    YES=1; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

c() { printf '\033[%sm%s\033[0m\n' "$1" "$2"; }
step() { echo; c "36" "==> $1"; }
is_game() { [ -f "$1/Split/Content/Paks/pakchunk0-Windows.pak" ]; }
ask() { # ask "question" default -> echoes answer
  if [ "$YES" = 1 ] || [ ! -r /dev/tty ]; then echo "$2"; return; fi
  local a; read -r -p "$1" a < /dev/tty || true; echo "${a:-$2}"
}

declare -a GAMES=()
add() { local d="$1" src="$2"; [ -n "$d" ] && is_game "$d" || return 0
  d="$(cd "$d" && pwd -P)"; for g in "${GAMES[@]:-}"; do [ "$g" = "$d" ] && return 0; done
  GAMES+=("$d"); c "32" "  found ($src): $d"; }

find_games() {
  # Steam (native, Flatpak, Snap) + every library folder listed in libraryfolders.vdf
  local roots=("$HOME/.steam/steam" "$HOME/.local/share/Steam" "$HOME/.steam/root"
               "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam" "$HOME/snap/steam/common/.local/share/Steam")
  local libs=()
  for r in "${roots[@]}"; do
    [ -d "$r/steamapps" ] || continue; libs+=("$r")
    local vdf="$r/steamapps/libraryfolders.vdf"
    if [ -f "$vdf" ]; then while IFS= read -r p; do libs+=("$p"); done < <(grep -o '"path"[[:space:]]*"[^"]*"' "$vdf" | sed 's/^"path"[[:space:]]*"\(.*\)"$/\1/'); fi
  done
  for l in "${libs[@]:-}"; do
    [ -n "$l" ] || continue
    local dir="Split Fiction" acf="$l/steamapps/appmanifest_2001120.acf"
    if [ -f "$acf" ]; then local x; x="$(sed -n 's/^[[:space:]]*"installdir"[[:space:]]*"\(.*\)".*/\1/p' "$acf" | head -1)"; [ -n "$x" ] && dir="$x"; fi
    add "$l/steamapps/common/$dir" "Steam"
  done
  # Heroic (Epic / GOG / Amazon via Legendary) and other launchers
  for j in "$HOME/.config/heroic/legendaryConfig/legendary/installed.json" \
           "$HOME/.var/app/com.heroicgameslauncher.hgl/config/heroic/legendaryConfig/legendary/installed.json" \
           "$HOME/.config/legendary/installed.json"; do
    [ -f "$j" ] || continue
    while IFS= read -r p; do add "$p" "Heroic/Epic"; done < <(grep -o '"install_path": *"[^"]*"' "$j" | sed 's/.*: *"\(.*\)"/\1/' | grep -i 'split')
  done
  for d in "$HOME/Games/Heroic/Split Fiction" "$HOME/Games/Split Fiction" "$HOME/Games/split-fiction" \
           "$HOME/Games/ea-app/drive_c/Program Files/EA Games/Split Fiction" \
           "$HOME/.wine/drive_c/Program Files/EA Games/Split Fiction" \
           "$HOME/Games/Heroic/Prefixes/default/drive_c/Program Files/EA Games/Split Fiction"; do
    add "$d" "Folder"
  done
}

search_all() {
  local places=("$HOME" /run/media /media /mnt)
  for p in "${places[@]}"; do
    [ -d "$p" ] || continue; echo "  searching $p ..."
    while IFS= read -r f; do add "$(dirname "$(dirname "$(dirname "$(dirname "$f")")")")" "Search"; done \
      < <(find "$p" -xdev -type f -name 'pakchunk0-Windows.pak' -path '*/Split/Content/Paks/*' 2>/dev/null)
  done
}

echo; c "1" "  Split Fiction - Arabic translation (Saad5400)"; echo "  https://github.com/$REPO"

step "Looking for Split Fiction"
if [ -n "$GAME_PATH" ]; then is_game "$GAME_PATH" || { c "31" "  Not a Split Fiction folder: $GAME_PATH"; exit 1; }; add "$GAME_PATH" "given"
else
  find_games
  if [ ${#GAMES[@]} -eq 0 ]; then
    c "33" "  Not found in the usual places."
    a="$(ask '  Search all drives? This can take a few minutes [Y/n] ' y)"; case "$a" in n|N) ;; *) search_all ;; esac
  fi
  if [ ${#GAMES[@]} -eq 0 ]; then
    m="$(ask '  Paste the game folder path (contains the "Split" folder), or Enter to cancel: ' '')"
    [ -n "$m" ] && { is_game "$m" && add "$m" "given" || { c "31" "  Not a Split Fiction folder: $m"; exit 1; }; }
  fi
fi
[ ${#GAMES[@]} -gt 0 ] || { c "31" "  Split Fiction was not found. Run again with --game-path \"<game folder>\"."; exit 1; }

if [ ${#GAMES[@]} -gt 1 ] && [ "$YES" = 0 ]; then
  for i in "${!GAMES[@]}"; do echo "  [$((i+1))] ${GAMES[$i]}"; done
  p="$(ask '  Install to which one? Number, or A for all [A] ' A)"
  if [[ "$p" =~ ^[0-9]+$ ]] && [ "$p" -ge 1 ] && [ "$p" -le ${#GAMES[@]} ]; then GAMES=("${GAMES[$((p-1))]}"); fi
fi

if [ "$UNINSTALL" = 1 ]; then
  step "Removing the Arabic translation"
  for g in "${GAMES[@]}"; do f="$g/Split/Content/Paks/$PAK"
    if [ -f "$f" ]; then [ "$DRYRUN" = 1 ] && echo "  would remove $f" || { rm -f "$f"; c "32" "  removed $f"; }; else echo "  not installed in $g"; fi
  done
  echo; c "32" "Done. The game is back to English."; exit 0
fi

step "Downloading the latest translation"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
URL="https://github.com/$REPO/releases/latest/download/$PAK"
DIGEST="$(curl -fsSL -H 'User-Agent: SplitFiction-Arabic-installer' "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null \
  | tr ',' '\n' | awk -v p="\"$PAK\"" 'index($0, "\"name\"") && index($0, p) {f=1} f && /"digest"/ { if (match($0, /[0-9a-f]{64}/)) { print substr($0, RSTART, 64); exit } }' || true)"
if [ "$DRYRUN" = 1 ]; then echo "  would download $URL"; else
  curl -fL --progress-bar -o "$TMP/$PAK" "$URL"
  if [ -n "$DIGEST" ]; then
    got="$(sha256sum "$TMP/$PAK" | cut -d' ' -f1)"
    [ "$got" = "$DIGEST" ] || { c "31" "  Checksum mismatch: expected $DIGEST, got $got"; exit 1; }
    c "32" "  downloaded, checksum OK"
  else c "32" "  downloaded"; fi
fi

for g in "${GAMES[@]}"; do
  P="$g/Split/Content/Paks"; step "Installing to $P"
  for o in "${OLD_PAKS[@]}"; do
    if [ -f "$P/$o" ]; then
      if [ "$DRYRUN" = 1 ]; then echo "  would move old translation $o to _old_arabic_backup"
      else mkdir -p "$P/_old_arabic_backup"; mv -f "$P/$o" "$P/_old_arabic_backup/"; c "33" "  moved old translation $o to _old_arabic_backup"; fi
    fi
  done
  if [ "$DRYRUN" = 1 ]; then echo "  would copy $PAK"; else cp -f "$TMP/$PAK" "$P/$PAK"; c "32" "  installed $PAK"; fi
done

echo; c "32" "  Done! Start the game and set the language to English."
