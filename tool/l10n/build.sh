#!/usr/bin/env bash
# Regenera los .arb desde lib/l10n/src y el código de lib/l10n/gen.
set -euo pipefail
cd "$(dirname "$0")/../.."
FLUTTER="${FLUTTER:-flutter}"
dart run tool/l10n/build_arb.dart
# pub get genera lib/l10n/gen (generate: true) con el formato de l10n.yaml.
"$FLUTTER" pub get --offline >/dev/null
