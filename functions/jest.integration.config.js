// Integración de los triggers de reservas contra el emulador de Firestore
// (demo-luxelane). Se ejecuta con `npm run test:integration` desde la raíz
// o desde tools/rules-tests, que levanta el emulador.
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['<rootDir>/src/integration/**/*.int.ts'],
  moduleFileExtensions: ['ts', 'js'],
  setupFiles: ['<rootDir>/src/integration/emulator_only.js'],
  testTimeout: 30000,
};
