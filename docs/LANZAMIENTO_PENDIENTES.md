# Lanzamiento: lo que falta y quién puede hacerlo

Todo lo que se puede hacer en el código ya está hecho y subido. Lo que queda depende de cuentas, pagos, datos de la empresa o una computadora con herramientas que este entorno no tiene. Va en orden: cada bloque destraba el siguiente.

## 1. Solo tú (identidad, pagos o decisiones de la empresa)

| # | Qué | Por qué no lo puedo hacer yo |
|---|---|---|
| 1 | **Cuenta de Google Play Console** (pago único de USD 25) a nombre de la empresa | Requiere tu identidad y un pago |
| 2 | **Cuenta de Apple Developer** (USD 99 al año) | Igual; Apple además verifica la empresa (D-U-N-S) |
| 3 | **Datos legales** en `lib/core/config/legal.dart`: razón social, NIT, dirección, correo y WhatsApp de soporte, años de conservación de registros | Son datos de tu empresa; no los puedo inventar |
| 4 | **Revisión de un abogado** de `legal_content.dart` (cancelación tardía, espera extra, responsabilidad) | Decisión legal |
| 5 | **Logo oficial** (opcional para lanzar: hoy hay un ícono provisorio con el monograma) | Decisión de marca. Cuando lo tengas, reemplazo los íconos y regenero las capturas |

## 2. Con tu cuenta de Google Cloud / Firebase

Lo puedo hacer yo **si me das acceso**: crea una cuenta de servicio en Google Cloud (rol *Owner* del proyecto `luxelane-4e7ae`, o *Firebase Admin* + *Cloud Functions Admin* + *Service Account User*), descarga su clave JSON y cárgala en la configuración del entorno de Claude Code (menú del entorno → Editar → secretos o variables de entorno) como `GCP_SERVICE_ACCOUNT_JSON`. Una sesión nueva la toma. No la pegues en el chat.

Si prefieres hacerlo tú, desde tu computadora con `gcloud` y `firebase` iniciados con tu cuenta:

| # | Comando | Para qué |
|---|---|---|
| 6 | `firebase deploy --only functions,firestore,storage` | Sube el servidor y las reglas de todo lo hecho en las fases 3 y 4 |
| 7 | `PROJECT=luxelane-4e7ae ./scripts/setup_backups.sh` | Copias de seguridad (hoy no hay ninguna) |
| 8 | `PROJECT=luxelane-4e7ae ALERT_EMAIL=<tu correo> ./scripts/setup_alerts.sh` | Avisos por correo si el servidor falla |
| 9 | `./scripts/setup_mobile.sh` | Registra las 4 apps móviles en Firebase y escribe su configuración |
| 10 | Cargar en GitHub → Settings → Secrets: `FIREBASE_RIDER_ANDROID_ENV`, `FIREBASE_DRIVER_ANDROID_ENV`, `GOOGLE_MAPS_ANDROID_KEY`, `APP_CHECK_WEB_KEY` (lista completa en DEPLOY.md) | Para que la CI compile Android y la web |
| 11 | Claves de Maps restringidas para Android (paquete + SHA-1) e iOS (bundle id) en Google Cloud Console | Mapas en las apps móviles |
| 12 | Registrar las apps en Firebase → App Check (DEPLOY.md, "App Check") | Que solo las apps oficiales llamen al servidor |
| 13 | Opcional: `./scripts/setup_staging.sh` | Un proyecto de pruebas separado de producción |

## 3. En una computadora tuya (este entorno no puede descargar las herramientas de Android ni usar macOS)

| # | Qué | Notas |
|---|---|---|
| 14 | **Clave de subida de Android** (`keytool …`, DEPLOY.md, "Mobile release (Android)") y `android/key.properties` | Guárdala con copia de seguridad; nunca va al repositorio |
| 15 | **Compilar Android**: `APP=rider GOOGLE_MAPS_KEY=… ./scripts/build_mobile.sh` y lo mismo con `APP=driver` | Es la primera compilación real: si falla, pásame el error y lo corrijo |
| 16 | **iOS en una Mac**: firma en Xcode, clave APNs (.p8) subida a Firebase, `./scripts/build_ios.sh` y subir con Transporter | Requiere la cuenta de Apple (punto 2) |
| 17 | **Una captura del viaje en curso con el mapa**, tomada en un teléfono | El generador de capturas no dibuja mapas; las otras 30 ya están en `docs/store/screenshots/` |

## 4. Publicar

| # | Qué | Dónde está preparado |
|---|---|---|
| 18 | Fichas de Play Console (textos es/en/pt, seguridad de datos, declaración de ubicación del chófer con video) | `docs/PLAY_STORE.md` |
| 19 | Fichas de App Store (subtítulos, palabras clave, privacidad, notas para la revisión) | `docs/APP_STORE.md` |
| 20 | Cuentas de prueba para la revisión: un pasajero y un chófer con documentos aprobados | Crear en la app y aprobar desde el admin |
| 21 | Prueba interna → beta cerrada → 10 % → 100 % | DEPLOY.md, "Rollout" |
