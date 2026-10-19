// Nunca contra un proyecto real: sin emulador de Firestore no se ejecuta.
if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error('Las pruebas de integración solo corren con el emulador (FIRESTORE_EMULATOR_HOST).');
}
process.env.GCLOUD_PROJECT = 'demo-luxelane';
