#!/usr/bin/env bash
# Levanta la app contra los emuladores de demo-luxelane con datos de prueba.
#   tools/experiencia/levantar.sh            # compila y levanta
#   tools/experiencia/levantar.sh --sin-build
# Pasajero y panel: http://localhost:5050 · Chófer: http://localhost:5051
# Emuladores: Auth 9099, Firestore 8080, UI 4000. Functions: callables.cjs en
# :5001 (el emulador de Functions de firebase-tools no funciona tras el proxy
# de la sesión: manda por él hasta las llamadas a 127.0.0.1).
set -euo pipefail
PROJECT="${PROJECT:-demo-luxelane}"
if [ "$PROJECT" != "demo-luxelane" ]; then
  echo "Solo demo-luxelane (recibido: $PROJECT). No se levanta nada." >&2; exit 1
fi
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
FLUTTER="${FLUTTER:-flutter}"
FIREBASE="$ROOT/tools/rules-tests/node_modules/.bin/firebase"

# Secretos FICTICIOS para el emulador de Functions (ignorado por git).
cat > functions/.secret.local <<'SECRETS'
STRIPE_SECRET_KEY=sk_test_ficticio_emulador
MAPS_SERVER_KEY=
PICKUP_CODE_SECRET=secreto-ficticio-del-emulador
RATE_LIMIT_SALT=sal-ficticia-del-emulador
SECRETS

(cd functions && npm run build >/dev/null)
if [ "${1:-}" != "--sin-build" ]; then
  # CanvasKit local: no depende de www.gstatic.com.
  DEFINES=(--dart-define=USE_EMULATORS=true --dart-define=ENV=dev --no-web-resources-cdn)
  "$FLUTTER" build web --release -t lib/main.dart "${DEFINES[@]}" -o "$ROOT/build/web-emu"
  "$FLUTTER" build web --release -t lib/main_driver.dart "${DEFINES[@]}" -o "$ROOT/build/web-emu-driver"
fi

exec "$FIREBASE" emulators:exec --only auth,firestore --project "$PROJECT" \
  "node tools/experiencia/seed.cjs && (node tools/experiencia/callables.cjs & node tools/experiencia/serve.cjs)"
