// Servicios especiales: avisos (bandeja de la app + push) en cada cambio.
import * as admin from 'firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { logger } from './logger';
import { SpecialRequest, specialNotice } from './special';

const db = () => admin.firestore();

export const onSpecialRequestWritten = onDocumentWritten('specialRequests/{id}', async (event) => {
  const before = (event.data?.before.exists ? event.data.before.data() : null) as (SpecialRequest & { riderId: string }) | null;
  const after = (event.data?.after.exists ? event.data.after.data() : null) as (SpecialRequest & { riderId: string }) | null;
  const notice = specialNotice(before, after);
  if (!notice || !after) return;

  const ids = notice.to === 'rider'
    ? [after.riderId]
    : (await db().collection('users').where('role', '==', 'admin').get()).docs.map((d) => d.id);
  const batch = db().batch();
  const tokens: string[] = [];
  for (const uid of ids) {
    batch.set(db().collection('users').doc(uid).collection('notifications').doc(), {
      userId: uid, title: notice.title, body: notice.body, type: 'special_request',
      specialRequestId: event.params.id, isRead: false, createdAt: Timestamp.now(),
    });
    const u = await db().collection('users').doc(uid).get();
    tokens.push(...((u.data()?.fcmTokens as string[]) ?? []));
  }
  await batch.commit();
  if (tokens.length) {
    await admin.messaging().sendEachForMulticast({ tokens, notification: { title: notice.title, body: notice.body } })
      .catch((e) => logger.warn('special', 'push failed', { error: String(e) }));
  }
});
