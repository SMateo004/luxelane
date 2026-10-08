# Protocolo de incidentes — Luxelane

Guía interna para el equipo de operaciones. Describe qué hacer ante cada tipo de incidente **con las herramientas que el sistema tiene hoy**. Si algo no existe todavía, se dice explícitamente, junto con el paso manual que lo reemplaza.

> Regla número uno: si hay riesgo para una persona, **primero la emergencia (110, Policía)** y después todo lo demás. La app le muestra al cliente el mismo aviso en el centro de ayuda.

---

## 1. Roles y canales

| Rol | Responsabilidad |
|---|---|
| **Operador de turno** | Mira Admin → Salud y Admin → Soporte, atiende avisos push y resuelve los incidentes de este documento. |
| **Responsable de operaciones** | Recibe las escalaciones (seguridad, accidentes, fallas del sistema) y decide reembolsos o bajas de chóferes. |
| **Responsable técnico** | Recibe el correo de alertas del servidor (`scripts/setup_alerts.sh`) y atiende las caídas del sistema. |

- **Avisos push a admins:** el sistema avisa a las cuentas con rol `admin` (hasta 20). Cada operador de turno debe usar una cuenta admin con la app instalada y las notificaciones activas.
- **Horario de atención:** se define en **Admin → Soporte → Horario de atención** y lo ve el cliente en el centro de ayuda. Fuera de horario, el cliente ve cuándo respondemos. **Los avisos de seguridad y de reservas sin chófer llegan igual a cualquier hora:** alguien debe quedar de guardia mientras haya viajes programados.

## 2. Severidad y tiempos de respuesta

| Nivel | Ejemplos | Primera respuesta | Escalar a |
|---|---|---|---|
| **S1 – Crítico** | Solicitud de **Seguridad**, accidente, cliente o chófer en peligro, caída total (nadie puede reservar) | Inmediata (≤ 5 min) | Responsable de operaciones; técnico si es caída |
| **S2 – Alto** | Recogida en < 30 min **sin chófer**, chófer que no llega, **ningún chófer en línea** con reservas próximas | ≤ 10 min | Responsable de operaciones si no se resuelve en 15 min |
| **S3 – Medio** | Cobro incorrecto, objeto perdido, queja sobre un chófer, errores web nuevos | Dentro del horario de atención, el mismo día | — |
| **S4 – Bajo** | Consultas, sugerencias | Dentro del horario de atención | — |

## 3. Monitoreo diario (inicio de cada turno)

1. **Admin → Salud:** revisar chóferes verificados en línea, reservas de las próximas 2 h, recogidas sin chófer en < 30 min, solicitudes urgentes abiertas y errores web. **Si dice que el monitor no informa hace más de 15 min, es un S1 técnico**: el monitor automático (`opsWatch`) dejó de correr y **nadie recibirá avisos automáticos**. Avisar al técnico y vigilar a mano Admin → Reservas (filtro *Sin chófer*).
2. **Admin → Soporte:** atender primero las urgentes (banner rojo) y después las pendientes, de la más antigua a la más nueva.
3. **Admin → Reservas → Sin chófer:** confirmar que las reservas del día tengan chófer.
4. **Admin → Chóferes:** revisar documentos por revisar o vencidos. Un documento vencido saca al chófer de línea automáticamente.

## 4. Procedimientos por incidente

### 4.1 Solicitud de Seguridad (S1)
El cliente o el chófer la abren desde **Ayuda → Nueva solicitud → Seguridad**. Llega como **push urgente** a los admins y aparece en el banner rojo de Admin → Soporte.

1. Abrir la solicitud y **responder en el chat en menos de 5 min**: "Te leemos. ¿Estás a salvo ahora?".
2. Si hay peligro inmediato: indicar llamar al **110**. Si está en un viaje, identificar la reserva (la solicitud puede traer el viaje asociado) y conseguir los teléfonos del chófer y del cliente (ver §6: hoy están en la consola de Firebase, colección `users`, campo `phone`).
3. Llamar por teléfono a la persona afectada. No resolver un S1 solo por chat.
4. Si el problema involucra al chófer: **retirarlo de servicio** rechazando un documento en Admin → Chóferes → Documentos, con el motivo "Suspensión preventiva por incidente". Eso lo saca de línea y del despacho al instante. Ver la limitación en §6.
5. Escalar al responsable de operaciones y dejar todo escrito en la solicitud. Marcarla como **Resuelta** solo cuando la persona esté a salvo y haya un siguiente paso acordado.

### 4.2 Recogida sin chófer (S2)
Push: **"Reserva sin chófer"** cuando falta menos de 30 min para la recogida.

1. Admin → Reservas → filtro **Sin chófer** → menú de la reserva → **Asignar el más cercano**. El sistema busca chóferes disponibles y verificados y asigna el primero en una transacción.
2. Si no hay ninguno: llamar a chóferes de confianza para que se conecten y repetir el paso 1.
3. Si no se consigue chófer: **llamar al cliente antes de la hora de recogida**, explicarle y ofrecerle otra hora. Si no acepta, cancelar la reserva desde el menú. Se libera la retención del pago y el cliente recibe el aviso.
4. Nota: si nadie hace nada, el sistema cancela solo las reservas pendientes 30 min después de la hora de recogida (motivo `no_driver_assigned`). **No hay que llegar a eso.**

### 4.3 Ningún chófer en línea (S2)
Push **"No hay chóferes en línea"** (como máximo uno por hora) cuando hay reservas en las próximas 2 h y ningún chófer verificado conectado.

1. Contactar a los chóferes con turno y pedirles que se conecten.
2. Revisar en Admin → Chóferes que tengan los documentos verificados. Uno con un documento vencido no puede conectarse.

### 4.4 Chófer asignado que no llega o no responde (S2)
1. Llamar al chófer (teléfono en la planilla de chóferes del equipo o en la consola de Firebase, `users/{id}.phone`).
2. Si no puede cumplir: **hoy no se puede cambiar el chófer de una reserva ya asignada**. Hay que cancelarla (menú → Cancelar) y crear una nueva para el cliente con los mismos datos; entra al despacho como reserva pendiente. Llamar al cliente para explicarle.
3. Registrar el incidente en una solicitud de soporte de categoría **Chófer**, para tener historial.

### 4.5 Accidente de tránsito (S1)
1. Confirmar si hay heridos → **110** (y emergencias médicas locales).
2. El chófer no debe mover el vehículo hasta que llegue la policía, salvo que haya riesgo.
3. Si el cliente puede seguir: organizar otro vehículo como en §4.4.
4. Pedir al chófer fotos, el acta policial y los datos del SOAT. Escalar al responsable de operaciones.

### 4.6 Cobros y reembolsos (S3)
- El cliente ve el precio fijo antes de confirmar. El recibo muestra el precio, los descuentos (código o Circle) y cualquier diferencia.
- **Hoy no hay botón de reembolso ni de ajuste de precio en el panel.** Los reembolsos los autoriza el responsable de operaciones y se hacen por fuera del panel (transferencia o QR), dejando constancia en la solicitud de soporte.
- **Cancelación tardía** (menos de 1 h antes): queda marcada y se ve en Admin → Reportes, pero **hoy no se cobra recargo**. La política está pendiente de revisión legal (ver DEPLOY.md).

### 4.7 Objeto perdido (S3)
1. La solicitud llega con la categoría **Objeto perdido** y, si se abrió desde el recibo, con el viaje asociado.
2. Contactar al chófer de ese viaje, coordinar la devolución y responder al cliente en el chat.

### 4.8 Queja sobre un chófer (S3; S1 si hay riesgo)
1. Leer la solicitud y la calificación del viaje, y pedir la versión del chófer.
2. Si corresponde retirarlo de servicio, usar el mismo método de §4.1, paso 4.

### 4.9 Falla del sistema
| Síntoma | Qué hacer |
|---|---|
| Correo **"más de 5 errores en 10 min"** | El técnico revisa los logs de Cloud Functions (`severity>=ERROR`) e identifica la función. |
| Muchos **errores web** nuevos en Admin → Salud | Mirar la pantalla y la versión del error. Si apareció con un despliegue reciente, volver a la versión anterior (abajo). |
| Monitor sin informar (> 15 min) | Ver §3.1. Revisar en la consola de Firebase que la función programada `opsWatch` esté activa. |
| Nadie puede reservar | S1. Avisar a los clientes con reservas próximas por teléfono mientras se resuelve. |

**Volver a una versión anterior:**
- **Web:** en Firebase Console → Hosting → historial de versiones → *Revertir* en la versión anterior.
- **Functions:** hacer checkout del último commit estable y `firebase deploy --only functions`.

## 5. Después de un incidente S1 o S2
En las 48 h siguientes, el responsable de operaciones escribe un resumen breve:
- qué pasó, cuándo y cómo nos enteramos;
- qué hicimos y cuánto tardamos;
- qué cambiaríamos: en el proceso, en la app o en la capacitación de chóferes.

Se guarda junto a la solicitud de soporte relacionada.

## 6. Límites actuales del sistema (a tener en cuenta)
Estas son cosas que el sistema **todavía no hace**. Están aquí para que nadie las dé por hechas.

- **No hay botón de pánico/SOS en el viaje.** El cliente pide ayuda desde Ayuda → Seguridad o llama al chófer o al 110. El centro de ayuda se abre desde el perfil y desde el recibo, no desde la pantalla del viaje en curso.
- **No se puede cambiar el chófer** de una reserva ya asignada: se cancela y se crea otra.
- **El panel no muestra teléfonos ni permite llamar** al cliente o al chófer: hay que buscarlos en la consola de Firebase (`users/{id}.phone`) o en la planilla de chóferes. Conviene tener esa planilla actualizada e impresa en el turno.
- **Desactivar un usuario** en Admin → Usuarios **todavía no le bloquea el acceso**. Para retirar a un chófer, usar el rechazo de documento (§4.1, paso 4).
- Si una solicitud urgente queda sin respuesta, **no hay un segundo aviso**: el turno debe revisar el banner rojo.
- Si el monitor automático se detiene, **no llega ningún aviso**: solo se ve en Admin → Salud.
- No hay reembolsos ni ajustes de precio desde el panel (§4.6).
- No hay enlace para compartir el viaje en vivo con terceros.
