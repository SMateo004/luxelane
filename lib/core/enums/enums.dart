import 'package:flutter/foundation.dart' show immutable;

import '../vehicles/vehicle_catalog.dart';

enum UserRole { rider, driver, admin }

/// A vehicle type, by id. The id is what bookings, vehicles and promos store;
/// names, photos, capacity and prices live in the catalog
/// (lib/core/vehicles/vehicle_catalog.dart), editable by admins.
@immutable
class VehicleClass {
  const VehicleClass(this.id);
  final String id;

  static const business = VehicleClass('business');
  static const firstClass = VehicleClass('firstClass');
  static const businessVan = VehicleClass('businessVan');
  static const electric = VehicleClass('electric');
  static const businessSuv = VehicleClass('businessSuv');

  /// Every type in the catalog (built-ins and admin-added, archived
  /// included), in display order.
  static List<VehicleClass> get values =>
      [for (final v in VehicleCatalog.instance.all) VehicleClass(v.id)];

  /// Same as [id] (kept from when this was an enum).
  String get name => id;

  /// Reads a stored id; unknown ids are kept (types added by admins).
  static VehicleClass fromId(Object? id) => id is String && id.isNotEmpty ? VehicleClass(id) : business;

  @override
  bool operator ==(Object other) => other is VehicleClass && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}

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

// Display names live in lib/l10n (ServiceTypeL10n, BookingStatusL10n) and,
// for vehicles, in the catalog. These Spanish getters remain only for non-UI
// uses such as logs and admin exports.
extension VehicleClassX on VehicleClass {
  /// Passengers it seats (from the catalog).
  int get capacity => VehicleCatalog.instance.info(this).capacity;

  /// Display name (Spanish), for logs, admin exports and audit entries.
  /// UI text uses localizedLabel(context.l10n).
  String get label {
    final name = VehicleCatalog.instance.info(this).name;
    return name['es'] ?? (name.isNotEmpty ? name.values.first : id);
  }

  /// Short description (Spanish): the experience, never a car make.
  String get description {
    final d = VehicleCatalog.instance.info(this).description;
    return d['es'] ?? (d.isNotEmpty ? d.values.first : '');
  }

  /// Maximum standard checked suitcases (from the catalog).
  int get luggageCapacity => VehicleCatalog.instance.info(this).checked;

  /// Asset folder under assets/images/vehicles/ (types added by admins use
  /// their id; their photos come from the catalog image instead).
  String get assetKey => switch (id) {
        'business' => 'business_class',
        'businessSuv' => 'business_suv',
        'firstClass' => 'first_class',
        'businessVan' => 'van',
        _ => id,
      };
}

extension ServiceTypeX on ServiceType {
  @Deprecated('UI text must use localizedLabel(context.l10n)')
  String get label {
    switch (this) {
      case ServiceType.oneWay:
        return 'Solo ida';
      case ServiceType.byTheHour:
        return 'Por horas';
    }
  }

  @Deprecated('UI text must use localizedDescription(context.l10n)')
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
      case BookingStatus.inProgress:
        return 'in_progress';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
    }
  }

  @Deprecated('UI text must use localizedLabel(context.l10n)')
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
      case BookingStatus.inProgress:
        return 'En progreso';
      case BookingStatus.completed:
        return 'Completado';
      case BookingStatus.cancelled:
        return 'Cancelado';
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
PaymentStatus Function(String) get PaymentStatusLabel => PaymentStatusX.fromString;

/// Extra charge or correction added by an admin to a ride's price
/// (mirrors functions/src/adjustments.ts).
enum AdjustmentType { waiting, toll, parking, extraStop, correction }
