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
  # Pasajero y panel con lugares y rutas ficticios (F5): sin clave de mapas
  # se llega igual a la pantalla de reserva. Nunca es la build de producción.
  "$FLUTTER" build web --release -t tools/experiencia/main_capturas.dart "${DEFINES[@]}" -o "$ROOT/build/web-emu"
  # Chófer: CAPTURE_WEB_UPLOADS (solo con USE_EMULATORS) deja ver en la web
  # los pasos de la cámara del registro; en producción la web no sube.
  "$FLUTTER" build web --release -t lib/main_driver.dart "${DEFINES[@]}" \
    --dart-define=CAPTURE_WEB_UPLOADS=true -o "$ROOT/build/web-emu-driver"
fi

# Storage (registro de chóferes): sus reglas leen Firestore, y esa llamada
# no puede pasar por el proxy de la sesión.
exec env -u HTTPS_PROXY -u https_proxy -u GLOBAL_AGENT_HTTPS_PROXY -u npm_config_https_proxy \
  -u YARN_HTTPS_PROXY -u HTTP_PROXY -u http_proxy \
  "$FIREBASE" emulators:exec --only auth,firestore,storage --project "$PROJECT" \
  "node tools/experiencia/seed.cjs && node tools/experiencia/seed_registro.cjs && (node tools/experiencia/callables.cjs & node tools/experiencia/serve.cjs)"
