#!/usr/bin/env bash
# Antes/después de una corrección (Parte B de experiencia).
#   ANTES=<carpeta con las capturas previas> tools/experiencia/antes_despues.sh E1 F9-sos/pulsando_390 ...
# Copia cada captura previa (ANTES) y la actual (docs/capturas) a
# docs/capturas/antes-despues/<Id>/ y compone <estado>.png lado a lado.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ID="$1"; shift
ANTES="${ANTES:?Falta ANTES: carpeta con las capturas de antes}"
OUT="$ROOT/docs/capturas/antes-despues/$ID"
mkdir -p "$OUT"
for key in "$@"; do
  name="$(echo "$key" | tr '/' '_')"
  a="$ANTES/$key.png"; d="$ROOT/docs/capturas/$key.png"
  [ -f "$a" ] && [ -f "$d" ] || { echo "falta $key" >&2; continue; }
  montage -font DejaVu-Sans -pointsize 16 -label 'Antes' "$a" -label 'Después' "$d" \
    -tile 2x -geometry 'x700+8+8' -background white "$OUT/$name.png"
  echo "$OUT/$name.png"
done
