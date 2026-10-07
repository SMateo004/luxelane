# Luxelane — Sistema de diseño y principios de UX

Este documento es el "método" que siguen todas las pantallas de Luxelane (web y app).
Nuestro cliente es un viajero de alto poder adquisitivo y el turista de alto nivel:
compra **certeza, tiempo y discreción**, no un trayecto. Cada decisión de diseño se
evalúa contra esa idea. Referencias de nivel: Blacklane, Uber Black.

---

## 1. Dos superficies, una marca

| Superficie | Cuándo | Tokens |
|---|---|---|
| **Medianoche** (oscura) | Momentos de marca y emoción: navegación, portadas, splash, mapa, seguimiento del viaje, cuenta | `LuxColors.*` (`app_theme.dart`) |
| **Marfil** (clara) | Momentos de tarea y lectura: elegir vehículo, detalles, resumen, FAQs, promesas | `LD.*` (`home_design.dart`) |

Regla: **se emociona en oscuro, se decide en claro.** Es el mismo patrón de Uber
(mapa oscuro + hojas claras) y de Blacklane (portadas oscuras + formularios limpios).

- Un solo acento: **zafiro** (`LD.sph` / `LuxColors.sapphire`). Sin dorados ni degradados llamativos.
- Sobre fondo oscuro, el texto/ícono de acento usa `LuxColors.sapphireBright` (el zafiro puro no cumple contraste).
- Botón primario: zafiro con texto **blanco**. Nunca texto negro sobre zafiro.

## 2. Tipografía

- **Cormorant Garamond** (serif, peso 300–400) para titulares editoriales. Frases cortas, con saltos de línea intencionados.
- **Montserrat** para interfaz. Etiquetas en mayúsculas con espaciado amplio (`uiLabel`, `LuxEyebrow`).
- Jerarquía por tamaño y aire, no por color ni negritas.

## 3. Marca

- Un único logotipo: `LuxelaneWordmark` (monograma "L" enmarcado + LUXELANE). No dibujar logos a mano.
- Un único nav público: `LuxSiteNav`; un único footer: `LuxSiteFooter` (`core/widgets/lux_site_chrome.dart`).
- El nav de la cuenta (`AppShell`) usa la misma barra medianoche para que web pública y cuenta se sientan un solo producto.

## 4. Promesas: una sola fuente de verdad

Todas las garantías se leen de `core/design/lux_promise.dart` (`LuxPromise` / `LuxAssurance`):

- Precio fijo, todo incluido
- Cancelación gratuita hasta 1 h antes
- 60 min de espera gratuita en aeropuertos · 15 min en otras recogidas
- Seguimiento de vuelo · Chóferes verificados · Atención 24/7

Nunca escribir una promesa como texto suelto en una pantalla. Para un cliente de alto
valor, dos cifras distintas para la misma promesa equivalen a ninguna.

## 5. Psicología aplicada

| Principio | Aplicación en Luxelane |
|---|---|
| **Reducción de la incertidumbre** | El precio final se ve antes de confirmar; las promesas aparecen justo bajo cada CTA. |
| **Compromiso progresivo** | El primer CTA es "Ver vehículos y precios" (bajo compromiso) + "Sin compromiso: verás el precio final antes de confirmar." |
| **Efecto de gradiente de meta** | Flujo de reserva en 3 pasos con nombre (Vehículo · Detalles · Confirmar). |
| **Sobrecarga de elección** | Máximo 3 clases de vehículo; una marcada como "La más elegida" (prueba social sutil). |
| **Anclaje** | "Desde Bs X" en las clases, calculado de las tarifas reales (`DefaultPricing`). |
| **Reconocimiento / estatus** | Saludo personal por nombre y momento del día en la app ("Buenas noches, Sai"). |
| **Calma y control** | Movimiento lento (curva expo-out, 250–900 ms), mucho aire, sin urgencia artificial, sin contadores ni "¡solo quedan 2!". El lujo no presiona. |
| **Honestidad** | Nunca datos de relleno frente al cliente (chóferes ficticios, botones sin acción, ofertas que no existen). Si algo aún no está, se dice con calma ("Asignando a tu chófer"). |

## 6. Voz y tono

- Español, **tuteo** en toda la marca (consistente con la app).
- Frases cortas, seguras, sin exclamaciones. "Aterriza. Nosotros nos ocupamos del resto."
- Terminología fija: **chófer** (no conductor), **recogida**, **trayecto**, **reserva**, **Bs**.

## 7. Páginas de servicio

Todas usan `ServicePageTemplate` (`features/services/presentation/widgets/`) y solo
cambian el contenido (`ServicePageContent`). La narrativa es siempre la misma:

1. Deseo — portada inmersiva + formulario de reserva funcional (`LuxServiceBookingCard`)
2. Certeza — "Tranquilidad, por escrito" (4 promesas)
3. Claridad — "Tres pasos. Nada más."
4. Historia — cómo se siente el servicio
5. Elección — 3 clases con precio "desde"
6. Objeciones — FAQ
7. Cierre — un único CTA tranquilo

Para crear un servicio nuevo: añadir su ruta en `LuxServiceRoutes`, crear un
`ServicePageContent` y registrar la ruta en el router. Sin maquetar nada nuevo.

## 8. Accesibilidad

- Contraste mínimo AA en texto; acento sobre oscuro con `sapphireBright`.
- Controles con `Semantics` (botones, pestañas, FAQs expandibles).
- Áreas táctiles ≥ 44 px en móvil.
