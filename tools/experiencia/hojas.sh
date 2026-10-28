#!/usr/bin/env bash
# A3: hojas de contacto a partir de docs/capturas (requiere ImageMagick).
#   tools/experiencia/hojas.sh
# Una hoja por flujo (una fila por ancho, cada captura con su estado) y una
# hoja global con las pantallas principales a 390 px. Salida:
# docs/capturas/hojas/<flujo>.jpg y docs/capturas/hojas/00-global.jpg
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAP="$ROOT/docs/capturas"
OUT="$CAP/hojas"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$OUT"
FONT_ARGS=(-font DejaVu-Sans -pointsize 13)

for dir in "$CAP"/F* "$CAP"/P-* "$CAP"/A8-*; do
  [ -d "$dir" ] || continue
  flow="$(basename "$dir")"
  rows=()
  for w in 390 768 1280; do
    shopt -s nullglob
    imgs=("$dir"/*_"$w".png)
    shopt -u nullglob
    [ ${#imgs[@]} -gt 0 ] || continue
    h=$([ "$w" = 390 ] && echo 560 || echo 420)
    montage "${FONT_ARGS[@]}" -label '%t' "${imgs[@]}" -tile "$((${#imgs[@]} < 8 ? ${#imgs[@]} : 8))x" \
      -geometry "x${h}+6+6" -background '#F2F5FB' "$TMP/$flow-$w.png"
    convert "$TMP/$flow-$w.png" -gravity north -background white -splice 0x30 \
      "${FONT_ARGS[@]}" -pointsize 18 -annotate +0+6 "$flow · ${w} px" "$TMP/$flow-$w-t.png"
    rows+=("$TMP/$flow-$w-t.png")
  done
  [ ${#rows[@]} -gt 0 ] || continue
  convert "${rows[@]}" -background white -append -quality 82 "$OUT/$flow.jpg"
  echo "hoja: $OUT/$flow.jpg"
done

# Global: pantallas principales a 390 px.
MAIN=(F2-reserva/inicio F1-acceso/login F1-acceso/registro F7-viajes/lista F5-viaje/pendiente F5-viaje/llego-codigo
  F5-viaje/en-curso F6-cancelacion/con-recargo F9-sos/ayuda F14-chofer/inicio F14-chofer/solicitudes F14-chofer/en-recogida
  F14-chofer/ganancias F17-panel/panel F17-panel/operaciones F17-panel/finanzas)
args=()
for m in "${MAIN[@]}"; do [ -f "$CAP/${m}_390.png" ] && args+=(-label "$m" "$CAP/${m}_390.png"); done
montage "${FONT_ARGS[@]}" "${args[@]}" -tile 8x -geometry x560+6+6 -background '#F2F5FB' "$TMP/global.png"
convert "$TMP/global.png" -quality 82 "$OUT/00-global.jpg"
echo "hoja: $OUT/00-global.jpg"
