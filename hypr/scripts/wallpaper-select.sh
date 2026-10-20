#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIRS=(
  "$HOME/dotfiles/wallpapers"
  "$HOME/dotfiles/wallpapers/misc"
)

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-thumbs"
THEME="$HOME/.config/rofi/wallpaper-select.rasi"
CURRENT_LINK="${XDG_CACHE_HOME:-$HOME/.cache}/current-wallpaper"

THUMB_SIZE=400
TRANSITION_TYPE=grow
TRANSITION_FPS=60
TRANSITION_DURATION=1.2

if command -v magick >/dev/null; then IM=magick; else IM=convert; fi
mkdir -p "$CACHE_DIR"

mapfile -t IMAGES < <(
  find "${WALLPAPER_DIRS[@]}" -type f \
    \( -iname '*.jpg'  -o -iname '*.jpeg' -o -iname '*.png' \
    -o -iname '*.webp' -o -iname '*.gif'  -o -iname '*.bmp' \) \
    2>/dev/null | sort
)

if (( ${#IMAGES[@]} == 0 )); then
  notify-send "Wallpaper" "No images found in the configured directories."
  exit 1
fi

thumb_path() {
  local key
  key=$(printf '%s|%s|%s' "$1" "$(stat -c %Y -- "$1")" "$THUMB_SIZE" \
        | sha256sum | cut -d' ' -f1)
  printf '%s/%s.png' "$CACHE_DIR" "$key"
}

THUMBS=()
pending=()
for img in "${IMAGES[@]}"; do
  t=$(thumb_path "$img")
  THUMBS+=("$t")
  [[ -f $t ]] || pending+=("$img" "$t")
done

if (( ${#pending[@]} )); then
  notify-send -t 3000 "Wallpaper" "Generating $(( ${#pending[@]} / 2 )) thumbnails…"
  export THUMB_SIZE IM
  printf '%s\0' "${pending[@]}" |
    xargs -0 -n2 -P "$(nproc)" bash -c '
      "$IM" "$1[0]" -auto-orient \
        -thumbnail "${THUMB_SIZE}x${THUMB_SIZE}^" \
        -gravity center -extent "${THUMB_SIZE}x${THUMB_SIZE}" \
        -strip "$2"
    ' _ 2>/dev/null || true
fi

build_menu() {
  local i name
  for i in "${!IMAGES[@]}"; do
    name=$(basename "${IMAGES[$i]}")
    printf '%s\0icon\x1f%s\n' "${name%.*}" "${THUMBS[$i]}"
  done
}

index=$(build_menu | rofi -dmenu -i -show-icons -format i \
          -p "Wallpaper" -theme "$THEME") || exit 0
[[ -n ${index:-} ]] || exit 0
selected=${IMAGES[$index]}

if ! awww query >/dev/null 2>&1; then
  setsid -f awww-daemon >/dev/null 2>&1
  sleep 0.4
fi

awww img "$selected" \
  --transition-type "$TRANSITION_TYPE" \
  --transition-fps "$TRANSITION_FPS" \
  --transition-duration "$TRANSITION_DURATION"

ln -sf "$selected" "$CURRENT_LINK"

{
  printf '%s\n' "${THUMBS[@]}" | sort -u > "$CACHE_DIR/.keep"
  find "$CACHE_DIR" -maxdepth 1 -type f -name '*.png' | sort > "$CACHE_DIR/.have"
  comm -13 "$CACHE_DIR/.keep" "$CACHE_DIR/.have" | xargs -r rm -f
  rm -f "$CACHE_DIR/.keep" "$CACHE_DIR/.have"
} >/dev/null 2>&1 || true
