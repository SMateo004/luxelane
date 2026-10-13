# App Store — fichas y privacidad

Complemento de `docs/PLAY_STORE.md`, que tiene las descripciones completas. Esas descripciones sirven también para App Store: van en el campo **Descripción** de cada idioma. Aquí está solo lo que App Store pide distinto.

Dos apps, con el mismo proyecto `ios/` (ver DEPLOY.md, "Mobile release (iOS)"):
- **Luxelane**, bundle id `com.luxelane.rider`.
- **Luxelane Chófer**, bundle id `com.luxelane.driver`.

## 1. Campos de texto

Límites de App Store: nombre y subtítulo, 30 caracteres cada uno; palabras clave, 100.

### Luxelane (pasajero)

| Campo | Español (es-MX) | English (en-US) | Português (pt-BR) |
|---|---|---|---|
| Nombre | Luxelane | Luxelane | Luxelane |
| Subtítulo | Chófer privado en Santa Cruz | Private chauffeur, Santa Cruz | Motorista privado, Santa Cruz |
| Palabras clave | chofer,chófer,traslado,aeropuerto,Viru Viru,Santa Cruz,Bolivia,taxi ejecutivo,hotel,transfer | chauffeur,driver,airport transfer,Viru Viru,Santa Cruz,Bolivia,private car,hotel,ride | motorista,traslado,aeroporto,Viru Viru,Santa Cruz,Bolívia,carro executivo,hotel,transfer |
| Texto promocional | Precio fijo antes de confirmar y seguimiento de tu chófer en vivo. | Fixed price before you confirm and live tracking of your chauffeur. | Preço fixo antes de confirmar e acompanhamento do motorista ao vivo. |

### Luxelane Chófer

| Campo | Español (es-MX) | English (en-US) | Português (pt-BR) |
|---|---|---|---|
| Nombre | Luxelane Chófer | Luxelane Chauffeur | Luxelane Motorista |
| Subtítulo | Viajes para chóferes Luxelane | For Luxelane chauffeurs | Para motoristas da Luxelane |
| Palabras clave | chofer,conductor,viajes,Luxelane,Santa Cruz,ganancias | chauffeur,driver,rides,Luxelane,Santa Cruz,earnings | motorista,viagens,Luxelane,Santa Cruz,ganhos |
| Texto promocional | Recibe viajes cercanos y gestiona tu semana. | Get nearby rides and manage your week. | Receba viagens próximas e gerencie sua semana. |

**Categoría:** Viajes (principal) y Navegación (secundaria) para las dos apps. **Clasificación:** 17+ no es necesario; responder "ninguno" a todo da **4+**. Aun así, el uso es para mayores de edad, y eso se aclara en los términos.

## 2. Privacidad (etiquetas de App Store)

- **¿Datos usados para rastrearte?** No. No hay publicidad, Analytics ni datos compartidos con brókers.
- **Datos vinculados a ti:**

| Categoría de Apple | Pasajero | Chófer | Uso |
|---|---|---|---|
| Información de contacto: nombre, correo, teléfono | ✓ | ✓ | Funcionalidad de la app |
| Ubicación precisa | ✓ | ✓ | Funcionalidad de la app |
| Contenido del usuario: atención al cliente, otro contenido (notas, calificaciones) | ✓ | ✓ | Funcionalidad de la app |
| Contenido del usuario: fotos o videos (documentos) | — | ✓ | Funcionalidad de la app (verificación del chófer) |
| Identificadores: ID de usuario | ✓ | ✓ | Funcionalidad de la app, analítica (Crashlytics usa el ID de usuario) |
| Compras: historial de compras | ✓ | — | Funcionalidad de la app |
| Diagnóstico: datos de fallos y de rendimiento | ✓ | ✓ | Analítica |

- **Datos no vinculados a ti:** ninguno adicional.

> Si se activan los pagos con tarjeta, hay que agregar **Información financiera → Información de pago**.

## 3. Notas para la revisión de Apple

**Cuentas de prueba:** las mismas que para Google Play: un pasajero y un chófer con documentos aprobados.

**Luxelane Chófer, ubicación en segundo plano** (Apple la revisa especialmente). Texto para "Notas":
> The chauffeur app shares the driver's location only while they switch on "Available" (Disponible), so nearby rides can be assigned and the passenger can see the car arrive. It keeps working while the driver navigates with another maps app; iOS shows the blue location indicator, and sharing stops when they go offline. Background mode: location. Test account: <correo> / <contraseña>.

**Cuenta de chófer:** la app es solo para chóferes contratados por Luxelane. Si Apple pregunta, se puede distribuir por **Apple Business Manager / distribución no listada**. Para empezar, la publicación normal con cuenta de prueba suele bastar.

**Eliminar cuenta:** desde la app (Perfil → Eliminar cuenta), como exige Apple (guía 5.1.1(v)).

## 4. Recursos gráficos

- Ícono de 1024×1024, sin transparencia: ya está en `AppIcon.appiconset` (copia en `docs/store/icon-1024.png`). Es provisorio, ver `docs/PLAY_STORE.md`.
- Capturas para iPhone de 6,9" (1320×2868) y, si se publica también para iPad, de iPad de 13".
