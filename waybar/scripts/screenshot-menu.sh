#!/bin/bash
DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"

case "$1" in
  screen)  grimblast copysave screen "$DIR/$(date +%Y%m%d_%H%M%S).png" ;;
  area)    grimblast copysave area   "$DIR/$(date +%Y%m%d_%H%M%S).png" ;;
  active)  grimblast copysave active "$DIR/$(date +%Y%m%d_%H%M%S).png" ;;
esac
