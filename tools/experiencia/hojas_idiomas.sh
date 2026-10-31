#!/usr/bin/env bash
# B5: una hoja de contacto por idioma (una fila por ancho) a partir de
# docs/capturas/idiomas. Requiere ImageMagick. Salida:
# docs/capturas/idiomas/hojas/<idioma>.jpg
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAP="$ROOT/docs/capturas/idiomas"
OUT="$CAP/hojas"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$OUT"
FONT_ARGS=(-font DejaVu-Sans -pointsize 13)
for lang in es en pt; do
  [ -d "$CAP/$lang" ] || continue
  rows=()
  for w in 390 768 1280; do
    shopt -s nullglob
    imgs=("$CAP/$lang"/*_"$w".png)
    shopt -u nullglob
    [ ${#imgs[@]} -gt 0 ] || continue
    h=$([ "$w" = 390 ] && echo 560 || echo 420)
    montage "${FONT_ARGS[@]}" -label '%t' "${imgs[@]}" -tile 7x -geometry "x${h}+6+6" -background '#F2F5FB' "$TMP/$lang-$w.png"
    convert "$TMP/$lang-$w.png" -gravity north -background white -splice 0x30 \
      "${FONT_ARGS[@]}" -pointsize 18 -annotate +0+6 "$lang · ${w} px" "$TMP/$lang-$w-t.png"
    rows+=("$TMP/$lang-$w-t.png")
  done
  [ ${#rows[@]} -gt 0 ] || continue
  convert "${rows[@]}" -append -resize '2400x>' -quality 82 "$OUT/$lang.jpg"
  echo "$OUT/$lang.jpg"
done
