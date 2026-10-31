// Reglas de Cloud Storage (registro de chóferes, A2), contra el emulador de
// Storage: el chófer dueño solo CREA en driverDocs/{uid}/{tipo}/{versión};
// nadie lee, sobrescribe ni borra; tipo y tamaño acotados; el resto,
// denegado. Datos FICTICIOS.
import { readFileSync } from 'fs';
import { resolve } from 'path';
import { assertFails, assertSucceeds, initializeTestEnvironment, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc } from 'firebase/firestore';
import { deleteObject, getBytes, ref, uploadBytes } from 'firebase/storage';

const STORAGE_RULES = process.env.STORAGE_RULES_PATH ?? resolve(__dirname, '../../../storage.rules');
const FIRESTORE_RULES = resolve(__dirname, '../../../firestore.rules');

let env: RulesTestEnvironment;
beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-luxelane',
    firestore: { rules: readFileSync(FIRESTORE_RULES, 'utf8') },
    storage: { rules: readFileSync(STORAGE_RULES, 'utf8') },
  });
});
// Sin clearStorage entre tests: tras borrar, el emulador no siempre ve que
// un objeto recreado ya existe (resource) y dejaría sobrescribir. Cada test
// que crea usa su propia ruta.
beforeAll(async () => { await env.clearStorage(); });
beforeEach(async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const f = ctx.firestore();
    for (const [uid, role, isActive] of [['chofer', 'driver', true], ['otro', 'driver', true], ['ana', 'rider', true],
      ['admin', 'admin', true], ['bloq', 'driver', false]] as const) {
      await setDoc(doc(f, 'users', uid), { role, isActive });
    }
  });
});
afterAll(async () => { await env?.cleanup(); });

// Cabecera JPEG de prueba (contenido ficticio).
const JPEG = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0, 0x10, 0x4a, 0x46, 0x49, 0x46, 0, 1]);
const PDF = new Uint8Array([0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, 0x34]);
const storage = (uid: string | null) =>
  (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).storage();
const put = (uid: string | null, path: string, data = JPEG, contentType = 'image/jpeg') =>
  uploadBytes(ref(storage(uid), path), data, { contentType });

describe('driverDocs/{uid}/{tipo}/{versión}', () => {
  test('el chófer dueño sube su documento', async () => {
    await assertSucceeds(put('chofer', 'driverDocs/chofer/license_front/1'));
  });

  test('el dueño no sobrescribe, no lee y no borra', async () => {
    await assertSucceeds(put('chofer', 'driverDocs/chofer/license_back/1'));
    await assertFails(put('chofer', 'driverDocs/chofer/license_back/1'));
    await assertFails(getBytes(ref(storage('chofer'), 'driverDocs/chofer/license_back/1')));
    await assertFails(deleteObject(ref(storage('chofer'), 'driverDocs/chofer/license_back/1')));
  });

  test('otro chófer, un pasajero, el admin y un anónimo no suben en la carpeta de otro', async () => {
    for (const uid of ['otro', 'ana', 'admin', null]) {
      await assertFails(put(uid, 'driverDocs/chofer/vehicle_photo_back/1'));
    }
  });

  test('el admin no lee con las reglas (usa una URL firmada del servidor)', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await uploadBytes(ref(ctx.storage(), 'driverDocs/chofer/vehicle_photo_front/1'), JPEG, { contentType: 'image/jpeg' });
    });
    await assertFails(getBytes(ref(storage('admin'), 'driverDocs/chofer/vehicle_photo_front/1')));
  });

  test('un pasajero no sube en su propia carpeta (solo chóferes)', async () => {
    await assertFails(put('ana', 'driverDocs/ana/license_front/1'));
  });

  test('una cuenta de chófer bloqueada no sube', async () => {
    await assertFails(put('bloq', 'driverDocs/bloq/license_front/1'));
  });

  test('tipo de archivo no permitido', async () => {
    await assertFails(put('chofer', 'driverDocs/chofer/national_id_front/1', new Uint8Array([1, 2, 3]), 'text/plain'));
    // PDF solo en los documentos que lo admiten.
    await assertFails(put('chofer', 'driverDocs/chofer/national_id_front/1', PDF, 'application/pdf'));
    await assertSucceeds(put('chofer', 'driverDocs/chofer/criminal_record/1', PDF, 'application/pdf'));
  });

  test('tamaño excedido (más de 10 MB) o vacío', async () => {
    const big = new Uint8Array(10 * 1024 * 1024 + 1);
    big.set(JPEG);
    await assertFails(put('chofer', 'driverDocs/chofer/national_id_back/1', big));
    await assertFails(put('chofer', 'driverDocs/chofer/national_id_back/1', new Uint8Array(0)));
  });

  test('tipo de documento desconocido o versión inválida', async () => {
    await assertFails(put('chofer', 'driverDocs/chofer/selfie/1'));
    await assertFails(put('chofer', 'driverDocs/chofer/license_front/0'));
    await assertFails(put('chofer', 'driverDocs/chofer/license_front/abc'));
  });

  test('ruta fuera de driverDocs, denegada', async () => {
    await assertFails(put('chofer', 'otros/chofer/license_front/1'));
    await assertFails(put('chofer', 'chofer/foto.jpg'));
    await assertFails(put('chofer', 'driverDocs/chofer/license_front/1/extra'));
  });
});
