// Pruebas de las reglas de Firestore. Solo corren dentro del emulador:
//   npm run test:rules   (desde la raíz del repo o desde tools/rules-tests)
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['<rootDir>/test/**/*.rules.ts'],
  moduleFileExtensions: ['ts', 'js'],
  testTimeout: 20000,
};
