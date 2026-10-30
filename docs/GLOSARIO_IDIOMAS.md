# Glosario de idiomas — Luxelane

Idiomas de las apps del pasajero y del chófer: **español** (base),
**inglés** y **portugués de Brasil** (código `pt`). El panel de admin y las
páginas legales siguen en español.

> **Estado: borrador para revisión del responsable.** Las traducciones al
> inglés y al portugués están redactadas por nosotros y quedan
> **pendientes de revisión por un hablante nativo**. Los textos legales no
> se traducen aquí: los entrega el abogado.

## Términos del producto

| Concepto | Español | English | Português (Brasil) | Nota |
|---|---|---|---|---|
| Persona que conduce | chófer | chauffeur | motorista | No «driver» en textos al pasajero; en la app del chófer, «chauffeur» también. |
| Persona que viaja | pasajero | passenger | passageiro | Neutro siempre que se pueda («tu viaje», «your trip»). |
| Reserva | reserva | booking | reserva | No «reservation». |
| Recogida (el momento) | recogida | pickup | embarque | |
| Punto de recogida | punto de recogida | pickup point | ponto de embarque | |
| Código de recogida | código de recogida | pickup code | código de embarque | El código nunca va en un aviso. |
| Destino | destino | destination | destino | |
| Viaje / trayecto | viaje, trayecto | trip, journey | viagem, trajeto | «trip» en botones y títulos; «journey» en frases. |
| Servicio por horas | servicio por horas | hourly service | serviço por hora | |
| Traslado al aeropuerto | traslado al aeropuerto | airport transfer | transfer para o aeroporto | |
| Clase del vehículo | clase | vehicle class | categoria do veículo | Los nombres (Business Class, First Class, Business Van, Business SUV) no se traducen; «Eléctrico» sí: Electric / Elétrico. |
| Invitado (reserva para otra persona) | invitado | guest | convidado | |
| Equipaje | equipaje | luggage | bagagem | |
| Preferencias para el chófer | preferencias | preferences | preferências | «Tu chófer verá estas preferencias» / «Your chauffeur will see these preferences» / «Seu motorista verá estas preferências». Nunca una promesa. |
| Nota para el chófer | nota | note | observação | |
| SOS | SOS | SOS | SOS | No se traduce. |
| Central (equipo que atiende) | central | operations team | central | En inglés, en frases: «our operations team». |
| Comprobante | comprobante | receipt | comprovante | |
| Pago | pago | payment | pagamento | |
| Plazo para pagar | plazo para pagar | payment window | prazo para pagamento | |
| Devolución | devolución | refund | reembolso | |
| Retención por cancelar | retención | cancellation fee | taxa de cancelamento | |
| Cancelación | cancelación | cancellation | cancelamento | |
| No se presentó | no se presentó | no-show | não comparecimento | |
| Solicitud abierta (chófer) | solicitud | trip request | solicitação | |
| Mis viajes | Mis viajes | My trips | Minhas viagens | |
| Perfil | perfil | profile | perfil | |
| Avisos (bandeja) | avisos | notifications | notificações | |
| Panel (admin) | panel | dashboard | painel | Solo en avisos de SOS a los admin. |
| Moneda | Bs | Bs | Bs | Siempre «Bs» delante de la cifra. |
| Idioma: seguir el teléfono | Sistema | System | Sistema | Los nombres de idioma van en su lengua: Español, English, Português. |

## Reglas de tono

1. Sobrio y de servicio: frases cortas, sin exclamaciones, sin humor, sin
   modismos ni jerga regional.
2. Trato: «tú» en español, «you» en inglés, «você» en portugués de Brasil.
3. Sin promesas: nada de «al instante», «garantizado», «siempre», «ahora
   mismo» / «instantly», «guaranteed» / «na hora», «garantido». Lo que
   depende de una persona se dice como un hecho o una intención («Estamos
   buscando a tu chófer»), nunca como un plazo.
4. Las marcas propias no se traducen (Luxelane, nombres de clase). No se
   nombran marcas de terceros.
5. Importes: «Bs» seguido de la cifra. Español y portugués «Bs 1.234,50»;
   inglés «Bs 1,234.50» (la misma cifra, sin que cambie de sentido).
   Fechas y horas con el formato de cada idioma (intl).
6. Los mensajes de error dicen qué pasó y qué hacer, sin culpar («No se
   pudo guardar…»; «Inténtalo de nuevo»).
7. Accesibilidad: las etiquetas de lector de pantalla se traducen igual
   que el texto visible; los nombres de idioma se anuncian en su lengua.

## Avisos del servidor (functions/src/i18n.ts)

Todos salen del catálogo, en el idioma de `users/{uid}.locale` (sin él,
español). Un test (`i18n.test.ts`) falla si un push o un aviso de la bandeja
lleva texto fijo, si falta un idioma o si cambian los marcadores.

| Tipo | Para | Cuándo | Título (es) |
|---|---|---|---|
| booking_confirmed | pasajero | reserva asignada (y acceptBooking) | Chófer asignado |
| driver_arriving | pasajero | el chófer sale hacia la recogida | El chófer está en camino |
| driver_arrived | pasajero | el chófer llegó | El chófer ha llegado |
| ride_started | pasajero | viaje iniciado | Viaje iniciado |
| ride_completed | pasajero | viaje completado | Viaje completado |
| booking_cancelled | pasajero | reserva cancelada | Reserva cancelada |
| booking_driver_released | pasajero | el chófer liberó la reserva | Buscamos otro chófer |
| rider_no_show | pasajero | no se presentó | No te encontramos |
| payment_receipt | pasajero | cobro capturado (push) | Pago confirmado |
| payment_confirmed | pasajero | central confirma el pago | Pago confirmado |
| payment_confirmed_cancelled | pasajero | pago confirmado de una reserva ya cancelada | Pago confirmado |
| payment_rejected | pasajero | central rechaza el pago | Pago no confirmado |
| payment_expired | pasajero | venció el plazo para pagar | Reserva cancelada |
| refund_recorded | pasajero | central anota una devolución | Devolución registrada |
| new_trip_available | chóferes disponibles | reserva pagada | Nuevo viaje disponible |
| driver_assigned | chófer | asignación automática | Nueva reserva |
| trip_cancelled_by_rider | chófer | el pasajero canceló (push) | Viaje cancelado |
| booking_cancelled_by_rider | chófer | el pasajero canceló (bandeja) | Reserva cancelada |
| incident_raised | admin | SOS nuevo | SOS en un viaje |
| incident_cancel_requested | admin | quien pidió ayuda canceló el SOS | SOS cancelado: verificar por llamada |
| incident_unacknowledged | admin | SOS sin reconocer (escalada) | SOS sin reconocer |

Otros textos del servidor que ve una persona: el nombre del destino en el
servicio por horas («Servicio por horas») y los nombres de las clases. Las
alertas del panel (`adminAlerts`), la auditoría y los scripts siguen en
español. Los nombres de ciudades y aeropuertos son nombres propios y no se
traducen.

Los textos de los tres idiomas de cada aviso están en
`functions/src/i18n.ts`; los de la app, en `lib/l10n/app_*.arb`.

## Pendientes de revisión nativa

- Todo el inglés y el portugués de `lib/l10n/app_en.arb`, `lib/l10n/app_pt.arb`
  y `functions/src/i18n.ts`.
- Decisiones de vocabulario que conviene confirmar: «chauffeur» también en la
  app del chófer; «embarque» para la recogida en portugués; «operations team»
  para central.
