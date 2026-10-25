/**
 * Dispositivos del chófer (decisión 5). En el piloto no se bloquea nada:
 * la app manda un identificador de instalación (aleatorio, guardado en el
 * almacenamiento seguro del teléfono) y el servidor lo anota. Un
 * dispositivo nuevo deja un evento y una alerta de severidad baja para el
 * admin, salvo el primero de un chófer aún sin verificar: es su alta (C2).
 * Un chófer ya verificado que aparece por primera vez sí avisa.
 *
 * driverDevices/{uid}/devices/{installationId} y .../events: solo el
 * servidor escribe; solo el admin lee (firestore.rules).
 */
import * as admin from 'firebase-admin';
import { z } from 'zod';

export const deviceSchema = z.strictObject({
  installationId: z.string().regex(/^[A-Za-z0-9-]{16,64}$/),
  platform: z.enum(['android', 'ios', 'web']),
  appVersion: z.string().trim().min(1).max(40),
});
export type DeviceInput = z.infer<typeof deviceSchema>;

export async function registerDriverDevice(db: admin.firestore.Firestore, uid: string, input: DeviceInput,
  now = admin.firestore.Timestamp.now()): Promise<{ isNew: boolean }> {
  const root = db.collection('driverDevices').doc(uid);
  const devices = root.collection('devices');
  const ref = devices.doc(input.installationId);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (snap.exists) {
      tx.update(ref, { lastSeenAt: now, platform: input.platform, appVersion: input.appVersion });
      return { isNew: false };
    }
    const first = (await tx.get(devices.limit(1))).empty;
    const verified = (await tx.get(db.collection('driverProfiles').doc(uid))).data()?.documentsVerified === true;
    tx.set(ref, { ...input, firstSeenAt: now, lastSeenAt: now });
    tx.set(root, { driverId: uid, updatedAt: now, deviceCount: admin.firestore.FieldValue.increment(1) }, { merge: true });
    tx.set(root.collection('events').doc(), {
      type: first ? 'first_device' : 'new_device',
      installationId: input.installationId,
      platform: input.platform,
      appVersion: input.appVersion,
      createdAt: now,
    });
    // El primero de un chófer sin verificar es el alta normal: no avisa.
    if (!first || verified) {
      tx.set(db.collection('adminAlerts').doc(), {
        type: 'new_driver_device',
        severity: 'low',
        driverId: uid,
        platform: input.platform,
        firstDevice: first,
        message: 'El chófer entró desde un dispositivo nuevo.',
        createdAt: now,
        resolved: false,
      });
    }
    return { isNew: true };
  });
}
