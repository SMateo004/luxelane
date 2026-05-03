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
      case VehicleClass.electric:      return 'Electric';
    }
  }

  String get description {
    switch (this) {
      case VehicleClass.business:    return 'Mercedes E-Class or similar';
      case VehicleClass.firstClass:  return 'Mercedes S-Class or similar';
      case VehicleClass.businessVan: return 'Mercedes V-Class · Up to 7';
      case VehicleClass.electric:    return 'Tesla Model S or similar';
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
      case ServiceType.oneWay:     return 'One Way';
      case ServiceType.byTheHour: return 'By the Hour';
    }
  }

  String get description {
    switch (this) {
      case ServiceType.oneWay:     return 'Fixed-price transfer to your destination';
      case ServiceType.byTheHour: return 'Chauffeur at your disposal for a set time';
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
      case BookingStatus.pending:        return 'Pending';
      case BookingStatus.confirmed:      return 'Confirmed';
      case BookingStatus.driverArriving: return 'En Route';
      case BookingStatus.driverArrived:  return 'Driver Arrived';
      case BookingStatus.inProgress:     return 'In Progress';
      case BookingStatus.completed:      return 'Completed';
      case BookingStatus.cancelled:      return 'Cancelled';
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
