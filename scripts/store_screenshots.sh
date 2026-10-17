#!/bin/bash
# Regenerates the store screenshots from the real screens (demo data):
#
#   ./scripts/store_screenshots.sh
#
# Output: docs/store/screenshots/<rider|driver>/<es|en|pt>/
#   play_*.png  — Google Play phone, 1080×1920
#   ios69_*.png — App Store iPhone 6.9", 1320×2868
# Run it again after changing the logo, colours or texts. Screens with a live
# map (trip in progress) aren't included: take those on a phone. Uses the
# fonts bundled in assets/google_fonts; no network needed.
set -euo pipefail
cd "$(dirname "$0")/.."

OUT_DIR="docs/store/screenshots" \
  flutter test tool/screenshots/store_screenshots_test.dart
echo "✓ docs/store/screenshots"
