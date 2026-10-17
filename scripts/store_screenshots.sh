#!/bin/bash
# Regenerates the store screenshots from the real screens (demo data):
#
#   ./scripts/store_screenshots.sh
#
# Output: docs/store/screenshots/<rider|driver>/<es|en|pt>/
#   play_*.png  — Google Play phone, 1080×1920
#   ios69_*.png — App Store iPhone 6.9", 1320×2868
# Run it again after changing the logo, colours or texts. Screens with a live
# map (trip in progress) aren't included: take those on a phone.
set -euo pipefail
cd "$(dirname "$0")/.."

FONTS_DIR="build/store_fonts"
mkdir -p "$FONTS_DIR/gf"

# Brand fonts for the screens that name them directly…
css="$(curl -fsS -A 'Mozilla/4.0' 'https://fonts.googleapis.com/css2?family=Montserrat:wght@300;400;500;600;700' \
  'https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300;0,400;0,500;0,600;1,300;1,400')"
python3 - "$FONTS_DIR" "$css" <<'PY'
import re, sys, urllib.request, os
d, css = sys.argv[1], sys.argv[2]
for block in re.findall(r'@font-face\s*\{[^}]*\}', css):
    fam = re.search(r"font-family: '([^']+)'", block).group(1).replace(' ', '')
    italic = 'italic' in re.search(r'font-style: (\w+)', block).group(1)
    w = re.search(r'font-weight: (\d+)', block).group(1)
    url = re.search(r'url\((https://[^)]+)\)', block).group(1)
    path = os.path.join(d, f"{fam}-{w}{'i' if italic else ''}.ttf")
    if not os.path.exists(path):
        urllib.request.urlretrieve(url, path)
PY

# …and the exact files google_fonts (used by the theme) asks for, by hash.
GF_SRC="$(find "${PUB_CACHE:-$HOME/.pub-cache}/hosted/pub.dev" -maxdepth 1 -name 'google_fonts-*' | sort -V | tail -1)/lib/src/google_fonts_parts"
python3 - "$GF_SRC" "$FONTS_DIR/gf" <<'PY'
import re, sys, os, urllib.request
src, out = sys.argv[1], sys.argv[2]
for f, fn in [('part_m.g.dart', 'montserrat'), ('part_c.g.dart', 'cormorantGaramond')]:
    s = open(os.path.join(src, f)).read()
    i = s.index(f'static TextStyle {fn}(')
    for h in set(re.findall(r"'([0-9a-f]{64})'", s[i:s.index('static TextStyle', i + 10)])):
        path = os.path.join(out, h + '.ttf')
        if not os.path.exists(path):
            urllib.request.urlretrieve(f'https://fonts.gstatic.com/s/a/{h}.ttf', path)
PY

FONTS_DIR="$FONTS_DIR" OUT_DIR="docs/store/screenshots" \
  flutter test tool/screenshots/store_screenshots_test.dart
echo "✓ docs/store/screenshots"
