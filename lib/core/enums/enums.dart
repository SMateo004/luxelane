enum UserRole { rider, driver, admin }

enum VehicleClass { business, firstClass, businessVan, electric }

enum ServiceType { oneWay, byTheHour }

enum BookingStatus {
  pending,
  confirmed,
  driverArriving,
  driverArrived,
  inProgress,
  completed,
  cancelled,
}

enum PaymentStatus { pending, captured, refunded, failed }

// ---------------------------------------------------------------------------
// Extensions
// ---------------------------------------------------------------------------

extension VehicleClassX on VehicleClass {
  String get label {
    switch (this) {
      case VehicleClass.business:      return 'Business Class';
      case VehicleClass.firstClass:    return 'First Class';
      case VehicleClass.businessVan:   return 'Business Van';
      case VehicleClass.electric:      return 'Eléctrico';
    }
  }

  String get description {
    switch (this) {
      case VehicleClass.business:    return 'Mercedes E-Class o similar';
      case VehicleClass.firstClass:  return 'Mercedes S-Class o similar';
      case VehicleClass.businessVan: return 'Mercedes V-Class · Hasta 7';
      case VehicleClass.electric:    return 'Tesla Model S o similar';
    }
  }

  int get capacity {
    switch (this) {
      case VehicleClass.businessVan: return 7;
      default:                       return 3;
    }
  }
}

extension ServiceTypeX on ServiceType {
  String get label {
    switch (this) {
      case ServiceType.oneWay:     return 'Solo ida';
      case ServiceType.byTheHour: return 'Por horas';
    }
  }

  String get description {
    switch (this) {
      case ServiceType.oneWay:     return 'Traslado a precio fijo a tu destino';
      case ServiceType.byTheHour: return 'Chófer a tu disposición por un tiempo determinado';
    }
  }
}

extension BookingStatusX on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.pending:        return 'pending';
      case BookingStatus.confirmed:      return 'confirmed';
      case BookingStatus.driverArriving: return 'driver_arriving';
      case BookingStatus.driverArrived:  return 'driver_arrived';
      case BookingStatus.inProgress:     return 'in_progress';
      case BookingStatus.completed:      return 'completed';
      case BookingStatus.cancelled:      return 'cancelled';
    }
  }

  String get displayLabel {
    switch (this) {
      case BookingStatus.pending:        return 'Pendiente';
      case BookingStatus.confirmed:      return 'Confirmado';
      case BookingStatus.driverArriving: return 'En camino';
      case BookingStatus.driverArrived:  return 'Chófer llegó';
      case BookingStatus.inProgress:     return 'En progreso';
      case BookingStatus.completed:      return 'Completado';
      case BookingStatus.cancelled:      return 'Cancelado';
    }
  }

  static BookingStatus fromString(String v) => BookingStatus.values.firstWhere(
        (e) => e.label == v,
        orElse: () => BookingStatus.pending,
      );
}

// Keep backward-compatible alias
// ignore: non_constant_identifier_names
BookingStatus Function(String) get BookingStatusLabel => BookingStatusX.fromString;

extension PaymentStatusX on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.pending:  return 'pending';
      case PaymentStatus.captured: return 'captured';
      case PaymentStatus.refunded: return 'refunded';
      case PaymentStatus.failed:   return 'failed';
    }
  }

  static PaymentStatus fromString(String v) => PaymentStatus.values.firstWhere(
        (e) => e.label == v,
        orElse: () => PaymentStatus.pending,
      );
}

// Keep backward-compatible alias
// ignore: non_constant_identifier_names
PaymentStatus Function(String) get PaymentStatusLabel => PaymentStatusX.fromString;
