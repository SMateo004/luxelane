/// Datos del chófer y de su vehículo que el admin revisa al verificar.
/// Después de verificar, el chófer no los cambia: lo hace un admin (con
/// registro en admin_logs). firestore.rules usa las mismas listas; un test
/// comprueba que coinciden.
library;

/// Campos de driverProfiles/{uid} bloqueados tras la verificación.
const kLockedDriverProfileFields = [
  'licenseNumber',
  'licenseExpiry',
  'vehicleId'
];

/// Campos de vehicles/{id} que el chófer nunca cambia.
const kLockedVehicleFields = ['plate', 'class', 'make', 'model', 'year'];

/// Lo único del vehículo que el chófer edita.
const kEditableVehicleFields = ['color', 'photoUrl'];

const kLockedDocumentsMessage =
    'Para cambiar estos datos, contacta con central.';
