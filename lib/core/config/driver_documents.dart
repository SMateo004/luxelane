/// Datos del chófer y de su vehículo que el admin revisa al verificar.
/// Después de verificar, el chófer no los cambia: lo hace un admin (con
/// registro en admin_logs). firestore.rules usa las mismas listas; un test
/// comprueba que coinciden.
library;

import '../../l10n/l10n.dart';

/// Todo lo que el chófer escribe en driverProfiles/{uid}; el resto
/// (documentsVerified, rating, ratingCount, totalRides…) es del admin o del
/// servidor.
const kDriverOwnerFields = [
  'userId',
  'licenseNumber',
  'licenseExpiry',
  'vehicleId',
  'isAvailable',
  'online',
  'currentLocation',
];

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

/// Sigue siendo `const` porque el perfil lo usa en un `const Text`; el texto
/// traducido es L10n.current.commonLockedDocuments.
String get kLockedDocumentsMessage => L10n.current.commonLockedDocuments;
