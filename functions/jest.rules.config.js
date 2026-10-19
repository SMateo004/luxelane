// Pruebas de las reglas de Firestore. Solo corren dentro del emulador:
//   npm run test:rules
// (no las incluye `npm test`, que no levanta el emulador).
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['<rootDir>/test-rules/**/*.rules.ts'],
  moduleFileExtensions: ['ts', 'js'],
  testTimeout: 20000,
};
