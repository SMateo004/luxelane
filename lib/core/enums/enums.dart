enum UserRole { rider, driver, admin }

/// Order matters only for serialisation (`name`); never reorder or rename.
enum VehicleClass { business, firstClass, businessVan, electric, businessSuv }

enum ServiceType { oneWay, byTheHour }

enum BookingStatus {
  pending,
  confirmed,
  driverArriving,
  driverArrived,

  /// El chófer comprobó el código de recogida del pasajero (verifyPickup) o
  /// el admin lo forzó (adminOverrideVerify). Solo desde aquí empieza el viaje.
  verified,
  inProgress,
  completed,
  cancelled,

  /// El chófer esperó el tiempo de la política y el pasajero no apareció
  /// (Parte B, B4). Central revisa y decide; no hay cobro automático.
  noShow,
}

enum PaymentStatus { pending, captured, refunded, failed }

// ---------------------------------------------------------------------------
// Extensions
// ---------------------------------------------------------------------------

extension VehicleClassX on VehicleClass {
  String get label {
    switch (this) {
      case VehicleClass.business:
        return 'Business Class';
      case VehicleClass.businessSuv:
        return 'Business SUV';
      case VehicleClass.firstClass:
        return 'First Class';
      case VehicleClass.businessVan:
        return 'Business Van';
      case VehicleClass.electric:
        return 'Eléctrico';
    }
  }

  /// What the client gets, never a car make or model: we promise the
  /// experience, not a badge we can't always guarantee.
  String get description {
    switch (this) {
      case VehicleClass.business:
        return 'Sedán ejecutivo';
      case VehicleClass.businessSuv:
        return 'SUV ejecutiva, más espacio';
      case VehicleClass.firstClass:
        return 'Sedán insignia';
      case VehicleClass.businessVan:
        return 'Van ejecutiva para grupos';
      case VehicleClass.electric:
        return 'Sedán ejecutivo eléctrico';
    }
  }

  /// Maximum passengers.
  int get capacity {
    switch (this) {
      case VehicleClass.businessVan:
        return 7;
      case VehicleClass.businessSuv:
        return 4;
      default:
        return 3;
    }
  }

  /// Maximum standard checked suitcases.
  int get luggageCapacity {
    switch (this) {
      case VehicleClass.businessVan:
        return 2;
      case VehicleClass.businessSuv:
        return 4;
      case VehicleClass.business:
        return 3;
      default:
        return 2;
    }
  }

  /// Asset folder under assets/images/vehicles/.
  String get assetKey {
    switch (this) {
      case VehicleClass.business:
        return 'business_class';
      case VehicleClass.businessSuv:
        return 'business_suv';
      case VehicleClass.firstClass:
        return 'first_class';
      case VehicleClass.businessVan:
        return 'van';
      case VehicleClass.electric:
        return 'electric';
    }
  }
}

extension ServiceTypeX on ServiceType {
  String get label {
    switch (this) {
      case ServiceType.oneWay:
        return 'Solo ida';
      case ServiceType.byTheHour:
        return 'Por horas';
    }
  }

  String get description {
    switch (this) {
      case ServiceType.oneWay:
        return 'Traslado a precio fijo a tu destino';
      case ServiceType.byTheHour:
        return 'Chófer a tu disposición por un tiempo determinado';
    }
  }
}

extension BookingStatusX on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.driverArriving:
        return 'driver_arriving';
      case BookingStatus.driverArrived:
        return 'driver_arrived';
      case BookingStatus.verified:
        return 'verified';
      case BookingStatus.inProgress:
        return 'in_progress';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.noShow:
        return 'no_show';
    }
  }

  String get displayLabel {
    switch (this) {
      case BookingStatus.pending:
        return 'Pendiente';
      case BookingStatus.confirmed:
        return 'Confirmado';
      case BookingStatus.driverArriving:
        return 'En camino';
      case BookingStatus.driverArrived:
        return 'Chófer llegó';
      case BookingStatus.verified:
        return 'Verificada';
      case BookingStatus.inProgress:
        return 'En progreso';
      case BookingStatus.completed:
        return 'Completado';
      case BookingStatus.cancelled:
        return 'Cancelado';
      case BookingStatus.noShow:
        return 'No se presentó';
    }
  }

  static BookingStatus fromString(String v) => BookingStatus.values.firstWhere(
        (e) => e.label == v,
        orElse: () => BookingStatus.pending,
      );
}

// Keep backward-compatible alias
// ignore: non_constant_identifier_names
BookingStatus Function(String) get BookingStatusLabel =>
    BookingStatusX.fromString;

extension PaymentStatusX on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.captured:
        return 'captured';
      case PaymentStatus.refunded:
        return 'refunded';
      case PaymentStatus.failed:
        return 'failed';
    }
  }

  static PaymentStatus fromString(String v) => PaymentStatus.values.firstWhere(
        (e) => e.label == v,
        orElse: () => PaymentStatus.pending,
      );
}

// Keep backward-compatible alias
// ignore: non_constant_identifier_names
PaymentStatus Function(String) get PaymentStatusLabel =>
    PaymentStatusX.fromString;
