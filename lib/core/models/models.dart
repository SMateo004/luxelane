import 'package:cloud_firestore/cloud_firestore.dart';

import '../enums/enums.dart';
import 'place_model.dart';

export 'place_model.dart';

// ---------------------------------------------------------------------------
// User
// ---------------------------------------------------------------------------

class User {
  const User({
    required this.id,
    required this.email,
    required this.phone,
    required this.displayName,
    this.photoUrl,
    required this.role,
    this.vehicleClass, // Added for driver category
    required this.createdAt,
    required this.isVerified,
    required this.isActive,
    this.stripeCustomerId,
    required this.fcmTokens,
    this.ridePreferences = RidePreferences.none,
  });

  final String id;
  final String email;
  final String phone;
  final String displayName;
  final String? photoUrl;
  final UserRole role;
  final VehicleClass? vehicleClass;
  final DateTime createdAt;
  final bool isVerified;
  final bool isActive;
  final String? stripeCustomerId;
  final List<String> fcmTokens;

  /// Cómo le gusta viajar (silencio, temperatura…); el chófer lo ve.
  final RidePreferences ridePreferences;

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as String,
        email: j['email'] as String,
        phone: j['phone'] as String? ?? '',
        displayName: j['displayName'] as String,
        photoUrl: j['photoUrl'] as String?,
        role: UserRole.values.firstWhere(
          (e) => e.name == j['role'],
          orElse: () => UserRole.rider,
        ),
        vehicleClass: j['class'] != null || j['vehicleClass'] != null
            ? VehicleClass.values.firstWhere(
                (e) => e.name == (j['class'] ?? j['vehicleClass']),
                orElse: () => VehicleClass.business,
              )
            : null,
        createdAt: (j['createdAt'] as Timestamp).toDate(),
        isVerified: j['isVerified'] as bool? ?? false,
        isActive: j['isActive'] as bool? ?? true,
        stripeCustomerId: j['stripeCustomerId'] as String?,
        fcmTokens: List<String>.from(j['fcmTokens'] ?? []),
        ridePreferences: RidePreferences.fromJson(j['ridePreferences']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'phone': phone,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'role': role.name,
        'class': vehicleClass?.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'isVerified': isVerified,
        'isActive': isActive,
        'stripeCustomerId': stripeCustomerId,
        'fcmTokens': fcmTokens,
        'ridePreferences': ridePreferences.toJson(),
      };

  User copyWith({
    String? phone,
    String? displayName,
    String? photoUrl,
    UserRole? role,
    VehicleClass? vehicleClass,
    bool? isVerified,
    bool? isActive,
    String? stripeCustomerId,
    List<String>? fcmTokens,
    RidePreferences? ridePreferences,
  }) =>
      User(
        id: id,
        email: email,
        phone: phone ?? this.phone,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        role: role ?? this.role,
        vehicleClass: vehicleClass ?? this.vehicleClass,
        createdAt: createdAt,
        isVerified: isVerified ?? this.isVerified,
        isActive: isActive ?? this.isActive,
        stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
        fcmTokens: fcmTokens ?? this.fcmTokens,
        ridePreferences: ridePreferences ?? this.ridePreferences,
      );
}

// ---------------------------------------------------------------------------
// RidePreferences — el "estilo de viaje" del pasajero
// ---------------------------------------------------------------------------

enum CabinTemperature {
  cool('Fresca', '20 °C'),
  mild('Templada', '22 °C'),
  warm('Cálida', '24 °C');

  const CabinTemperature(this.label, this.hint);
  final String label;
  final String hint;
}

/// Lo que el pasajero prefiere en cada viaje. Se guarda en su perfil, se
/// copia a cada reserva y el chófer lo ve antes de recogerlo: nadie tiene
/// que pedir lo mismo dos veces.
class RidePreferences {
  const RidePreferences({
    this.quiet = false,
    this.temperature,
    this.music = true,
    this.luggageHelp = false,
    this.openDoor = false,
  });

  static const none = RidePreferences();

  /// Prefiere viajar sin conversación.
  final bool quiet;
  final CabinTemperature? temperature;

  /// Música suave de fondo (false: viaje sin música).
  final bool music;

  /// Ayuda con el equipaje al subir y bajar.
  final bool luggageHelp;

  /// Que el chófer le abra la puerta.
  final bool openDoor;

  bool get isEmpty =>
      !quiet && temperature == null && music && !luggageHelp && !openDoor;

  /// Indicaciones breves para el chófer, en el orden en que las aplicará.
  List<String> get driverNotes => [
        if (openDoor) 'Abrir la puerta',
        if (luggageHelp) 'Ayuda con el equipaje',
        if (temperature != null)
          'Cabina ${temperature!.label.toLowerCase()} (${temperature!.hint})',
        if (quiet) 'Viaje en silencio',
        if (!music) 'Sin música',
      ];

  factory RidePreferences.fromJson(Object? raw) {
    if (raw is! Map) return none;
    final t = raw['temperature'];
    return RidePreferences(
      quiet: raw['quiet'] == true,
      temperature:
          CabinTemperature.values.where((e) => e.name == t).firstOrNull,
      music: raw['music'] != false,
      luggageHelp: raw['luggageHelp'] == true,
      openDoor: raw['openDoor'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'quiet': quiet,
        'temperature': temperature?.name,
        'music': music,
        'luggageHelp': luggageHelp,
        'openDoor': openDoor,
      };

  RidePreferences copyWith({
    bool? quiet,
    CabinTemperature? temperature,
    bool clearTemperature = false,
    bool? music,
    bool? luggageHelp,
    bool? openDoor,
  }) =>
      RidePreferences(
        quiet: quiet ?? this.quiet,
        temperature:
            clearTemperature ? null : (temperature ?? this.temperature),
        music: music ?? this.music,
        luggageHelp: luggageHelp ?? this.luggageHelp,
        openDoor: openDoor ?? this.openDoor,
      );

  @override
  bool operator ==(Object other) =>
      other is RidePreferences &&
      other.quiet == quiet &&
      other.temperature == temperature &&
      other.music == music &&
      other.luggageHelp == luggageHelp &&
      other.openDoor == openDoor;

  @override
  int get hashCode =>
      Object.hash(quiet, temperature, music, luggageHelp, openDoor);
}

// ---------------------------------------------------------------------------
// DriverProfile
// ---------------------------------------------------------------------------

class DriverProfile {
  const DriverProfile({
    required this.userId,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.vehicleId,
    required this.documentsVerified,
    required this.rating,
    required this.totalRides,
    required this.isAvailable,
    this.currentLocation,
  });

  final String userId;
  final String licenseNumber;
  final DateTime licenseExpiry;
  final String vehicleId;
  final bool documentsVerified;
  final double rating;
  final int totalRides;
  final bool isAvailable;
  final GeoPoint? currentLocation;

  factory DriverProfile.fromJson(Map<String, dynamic> j) => DriverProfile(
        userId: j['userId'] as String,
        licenseNumber: j['licenseNumber'] as String? ?? '',
        licenseExpiry: j['licenseExpiry'] != null
            ? (j['licenseExpiry'] as Timestamp).toDate()
            : DateTime.now().add(const Duration(days: 365)),
        vehicleId: j['vehicleId'] as String? ?? '',
        documentsVerified: j['documentsVerified'] as bool? ?? false,
        rating: (j['rating'] as num?)?.toDouble() ?? 5.0,
        totalRides: j['totalRides'] as int? ?? 0,
        isAvailable: j['isAvailable'] as bool? ?? false,
        currentLocation: j['currentLocation'] as GeoPoint?,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'licenseNumber': licenseNumber,
        'licenseExpiry': Timestamp.fromDate(licenseExpiry),
        'vehicleId': vehicleId,
        'documentsVerified': documentsVerified,
        'rating': rating,
        'totalRides': totalRides,
        'isAvailable': isAvailable,
        'currentLocation': currentLocation,
      };

  DriverProfile copyWith({
    bool? isAvailable,
    GeoPoint? currentLocation,
    double? rating,
    int? totalRides,
  }) =>
      DriverProfile(
        userId: userId,
        licenseNumber: licenseNumber,
        licenseExpiry: licenseExpiry,
        vehicleId: vehicleId,
        documentsVerified: documentsVerified,
        rating: rating ?? this.rating,
        totalRides: totalRides ?? this.totalRides,
        isAvailable: isAvailable ?? this.isAvailable,
        currentLocation: currentLocation ?? this.currentLocation,
      );
}

// ---------------------------------------------------------------------------
// Vehicle
// ---------------------------------------------------------------------------

class Vehicle {
  const Vehicle({
    required this.id,
    required this.driverId,
    required this.make,
    required this.model,
    required this.year,
    required this.plate,
    required this.vehicleClass,
    required this.color,
    this.photoUrl,
    required this.capacity,
    required this.isActive,
  });

  final String id;
  final String driverId;
  final String make;
  final String model;
  final int year;
  final String plate;
  final VehicleClass vehicleClass;
  final String color;
  final String? photoUrl;
  final int capacity;
  final bool isActive;

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: j['id'] as String,
        driverId: j['driverId'] as String,
        make: j['make'] as String? ?? '',
        model: j['model'] as String? ?? '',
        year: j['year'] as int? ?? 2024,
        plate: j['plate'] as String? ?? '',
        vehicleClass: VehicleClass.values.firstWhere(
          (e) => e.name == j['class'],
          orElse: () => VehicleClass.business,
        ),
        color: j['color'] as String? ?? 'Black',
        photoUrl: j['photoUrl'] as String?,
        capacity: j['capacity'] as int? ?? 3,
        isActive: j['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'driverId': driverId,
        'make': make,
        'model': model,
        'year': year,
        'plate': plate,
        'class': vehicleClass.name,
        'color': color,
        'photoUrl': photoUrl,
        'capacity': capacity,
        'isActive': isActive,
      };
}

// ---------------------------------------------------------------------------
// BookingSettlement
// ---------------------------------------------------------------------------

/// Comisión de plataforma por defecto, mientras el admin no configure otra
/// (el servidor usa el mismo valor: functions/src/settlement.ts).
const double kDefaultCommissionPct = 20;

/// Antelación con la que una reserva confirmada ya ocupa al chófer.
const kBusyLead = Duration(minutes: 60);

/// Reparto de un viaje completado entre la plataforma y el chófer.
///
/// Lo fija el servidor (Cloud Function `settleBooking`) con la comisión
/// vigente al completar el viaje; la app solo lo lee.
class BookingSettlement {
  const BookingSettlement({
    required this.amount,
    required this.commissionPct,
    required this.platformCommission,
    required this.driverPayout,
  });

  /// Importe repartido (precio final o estimado en ese momento).
  final double amount;
  final double commissionPct;
  final double platformCommission;
  final double driverPayout;

  static BookingSettlement? fromJson(Object? j) {
    if (j is! Map) return null;
    double n(String k) => (j[k] as num?)?.toDouble() ?? 0.0;
    return BookingSettlement(
      amount: n('amount'),
      commissionPct: n('commissionPct'),
      platformCommission: n('platformCommission'),
      driverPayout: n('driverPayout'),
    );
  }

  /// Reparto provisional con [commissionPct], para viajes que el servidor aún
  /// no ha repartido.
  factory BookingSettlement.estimate(
    double amount, {
    double commissionPct = kDefaultCommissionPct,
  }) {
    double round(double v) => (v * 100).roundToDouble() / 100;
    final pct = commissionPct.clamp(0, 100).toDouble();
    final commission = round(amount * pct / 100);
    return BookingSettlement(
      amount: amount,
      commissionPct: pct,
      platformCommission: commission,
      driverPayout: round(amount - commission),
    );
  }
}

// ---------------------------------------------------------------------------
// DriverInfo
// ---------------------------------------------------------------------------

/// Datos públicos del chófer asignado que el servidor copia en la reserva
/// (el pasajero no puede leer el perfil de otros usuarios).
class DriverInfo {
  const DriverInfo({
    required this.name,
    this.photoUrl,
    this.vehicle,
    this.plate = '',
    this.rating,
  });

  /// Sin teléfono: ese va en driverContact, legible solo durante el viaje.
  final String name;
  final String? photoUrl;

  /// Valoración media del chófer al asignarlo (copiada por el servidor).
  final double? rating;

  /// "Toyota Camry · Negro", o null si no hay vehículo.
  final String? vehicle;

  /// Placa, aparte para que el pasajero la reconozca de un vistazo.
  final String plate;

  static DriverInfo? fromJson(Object? j) {
    if (j is! Map) return null;
    final v = j['vehicle'];
    String? vehicle;
    if (v is Map) {
      final parts = [
        '${v['make'] ?? ''} ${v['model'] ?? ''}'.trim(),
        (v['color'] as String?) ?? '',
      ].where((p) => p.isNotEmpty);
      vehicle = parts.isEmpty ? null : parts.join(' · ');
    }
    return DriverInfo(
      name: (j['name'] as String?) ?? '',
      photoUrl: j['photoUrl'] as String?,
      vehicle: vehicle,
      plate: v is Map ? (v['plate'] as String?) ?? '' : '',
      rating: (j['rating'] as num?)?.toDouble(),
    );
  }
}

/// Código de recogida que el pasajero da al chófer. Solo vive en memoria:
/// nunca se guarda en el dispositivo.
class PickupCode {
  const PickupCode({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;

  factory PickupCode.fromJson(Map<String, dynamic> j) => PickupCode(
        code: j['code'] as String,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(
          (j['expiresAt'] as num).toInt(),
        ),
      );
}

// ---------------------------------------------------------------------------
// BookingGuest
// ---------------------------------------------------------------------------

/// Pasajero de una reserva hecha para otra persona. Lo ven el solicitante,
/// el chófer asignado y el admin; nunca un chófer antes de aceptar.
class BookingGuest {
  const BookingGuest({
    this.title = '',
    required this.firstName,
    this.lastName = '',
    this.phone = '',
    this.email = '',
    this.language = '',
  });

  final String title;
  final String firstName;
  final String lastName;
  final String phone;

  /// Solo en reservas antiguas: ya no se pide (minimización de datos).
  final String email;

  /// Idioma en que prefiere que le hablen, si el solicitante lo indicó.
  final String language;

  String get fullName =>
      [title, firstName, lastName].where((p) => p.isNotEmpty).join(' ');

  /// Teléfono, correo e idioma en una línea, sin los vacíos.
  String get contactLine =>
      [phone, email, language].where((p) => p.isNotEmpty).join(' · ');

  static BookingGuest? fromJson(Object? j) {
    if (j is! Map) return null;
    String field(String k) => (j[k] as String?) ?? '';
    if (field('firstName').isEmpty) return null;
    return BookingGuest(
      title: field('title'),
      firstName: field('firstName'),
      lastName: field('lastName'),
      phone: field('phone'),
      email: field('email'),
      language: field('language'),
    );
  }

  Map<String, dynamic> toJson() => {
        if (title.isNotEmpty) 'title': title,
        'firstName': firstName,
        if (lastName.isNotEmpty) 'lastName': lastName,
        if (phone.isNotEmpty) 'phone': phone,
        if (email.isNotEmpty) 'email': email,
        if (language.isNotEmpty) 'language': language,
      };
}

// ---------------------------------------------------------------------------
// Booking
// ---------------------------------------------------------------------------

class Booking {
  const Booking({
    required this.id,
    required this.riderId,
    this.driverId,
    required this.origin,
    required this.destination,
    required this.scheduledAt,
    required this.vehicleClass,
    required this.serviceType,
    required this.status,
    required this.estimatedPrice,
    this.finalPrice,
    this.paymentId,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.guest,
    this.flightNumber,
    this.flightType,
    this.pickupAirport,
    this.hours,
    this.passengerCount = 1,
    this.luggageCount = 0,
    this.pricingReviewReason,
    this.settlement,
    this.refunded = false,
    this.driverInfo,
    this.riderRating,
    this.cardPayment = false,
    this.cardPaymentFailed = false,
    this.riderPreferences = RidePreferences.none,
    this.pickupLocked = false,
  });

  final String id;
  final String riderId;
  final String? driverId;
  final Place origin;
  final Place destination;
  final DateTime scheduledAt;
  final VehicleClass vehicleClass;
  final ServiceType serviceType;
  final BookingStatus status;
  final double estimatedPrice;
  final double? finalPrice;
  final String? paymentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Notas libres del solicitante.
  final String? notes;

  /// Pasajero, si la reserva es para otra persona.
  final BookingGuest? guest;
  final String? flightNumber;

  /// [FlightType.name] of the passenger's flight (airport pickups only).
  final String? flightType;

  /// IATA code of the pickup airport, e.g. "VVI" (airport pickups only).
  final String? pickupAirport;
  final int? hours;
  final int passengerCount;
  final int luggageCount;

  /// Lo marca el servidor si el precio no respeta la tarifa vigente
  /// (`below_fare`, `fare_disabled`, `unknown_fare`). Solo lectura.
  final String? pricingReviewReason;

  /// Reparto plataforma / chófer fijado por el servidor. Solo lectura.
  final BookingSettlement? settlement;

  /// El cobro se reembolsó (lo marca `refundPayment`): el viaje ya no
  /// genera comisión ni pago al chófer. Solo lectura.
  final bool refunded;

  /// Chófer asignado, copiado por el servidor. Solo lectura.
  final DriverInfo? driverInfo;

  /// Valoración (1–5) que dio el pasajero, si ya valoró.
  final int? riderRating;

  /// Estilo de viaje del pasajero, copiado de su perfil al reservar.
  final RidePreferences riderPreferences;

  /// Se paga con tarjeta: el servidor la cobra al completar el viaje.
  final bool cardPayment;

  /// El cobro automático con tarjeta falló; se cobra a mano.
  final bool cardPaymentFailed;

  /// Cinco códigos de recogida incorrectos: la verificación quedó
  /// bloqueada y solo central puede forzarla. Lo fija el servidor.
  final bool pickupLocked;

  /// Cobro con tarjeta aún por resolver por el servidor: no se registra a
  /// mano para no cobrar dos veces.
  bool get cardPaymentPending =>
      cardPayment && !cardPaymentFailed && paymentId == null;

  /// Un viaje ocupa al chófer desde que sale a buscar al pasajero, o si la
  /// recogida es en menos de [kBusyLead]. Uno confirmado para más adelante
  /// no le impide atender otros mientras tanto.
  bool occupiesDriver([DateTime? now]) {
    switch (status) {
      case BookingStatus.driverArriving:
      case BookingStatus.driverArrived:
      case BookingStatus.verified:
      case BookingStatus.inProgress:
        return true;
      case BookingStatus.confirmed:
        return scheduledAt.isBefore((now ?? DateTime.now()).add(kBusyLead));
      default:
        return false;
    }
  }

  /// Importe que se factura: el precio final o, si no hay, el estimado.
  double get chargedAmount => finalPrice ?? estimatedPrice;

  /// Reparto vigente del viaje: el del servidor si corresponde al importe
  /// actual o, si no, uno provisional con [commissionPct].
  BookingSettlement settlementOr(double commissionPct) {
    final s = settlement;
    if (s != null && (s.amount - chargedAmount).abs() < 0.005) return s;
    return BookingSettlement.estimate(
      chargedAmount,
      commissionPct: s?.commissionPct ?? commissionPct,
    );
  }

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j['id'] as String? ?? '',
        riderId: j['riderId'] as String? ?? '',
        driverId: j['driverId'] as String?,
        origin: Place.fromJson(j['origin'] as Map<String, dynamic>? ?? {}),
        destination: Place.fromJson(
          j['destination'] as Map<String, dynamic>? ?? {},
        ),
        scheduledAt: j['scheduledAt'] != null
            ? (j['scheduledAt'] as Timestamp).toDate()
            : DateTime.now(),
        vehicleClass: VehicleClass.values.firstWhere(
          (e) => e.name == (j['class'] ?? j['vehicleClass'] ?? 'business'),
          orElse: () => VehicleClass.business,
        ),
        serviceType: ServiceType.values.firstWhere(
          (e) => e.name == (j['serviceType'] ?? 'oneWay'),
          orElse: () => ServiceType.oneWay,
        ),
        status: BookingStatusX.fromString(j['status'] as String? ?? 'pending'),
        estimatedPrice: (j['estimatedPrice'] as num?)?.toDouble() ?? 0.0,
        finalPrice: (j['finalPrice'] as num?)?.toDouble(),
        paymentId: j['paymentId'] as String?,
        createdAt: j['createdAt'] != null
            ? (j['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: j['updatedAt'] != null
            ? (j['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
        notes: j['notes'] as String?,
        guest: BookingGuest.fromJson(j['guest']),
        flightNumber: j['flightNumber'] as String?,
        flightType: j['flightType'] as String?,
        pickupAirport: j['pickupAirport'] as String?,
        hours: j['hours'] as int?,
        passengerCount: j['passengerCount'] as int? ?? 1,
        luggageCount: j['luggageCount'] as int? ?? 0,
        pricingReviewReason: (j['pricingReview'] as Map?)?['reason'] as String?,
        settlement: BookingSettlement.fromJson(j['settlement']),
        refunded: j['refunded'] == true,
        driverInfo: DriverInfo.fromJson(j['driverInfo']),
        riderRating: (j['riderRating'] as num?)?.toInt(),
        cardPayment: j['stripePaymentIntentId'] != null ||
            j['stripePaymentMethodId'] != null,
        cardPaymentFailed: j['cardPaymentFailed'] == true,
        riderPreferences: RidePreferences.fromJson(j['riderPreferences']),
        pickupLocked: j['pickupLocked'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'riderId': riderId,
        'driverId': driverId,
        'origin': origin.toJson(),
        'destination': destination.toJson(),
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'class': vehicleClass.name,
        // Cloud Functions read `vehicleClass`; keep both keys in sync.
        'vehicleClass': vehicleClass.name,
        'serviceType': serviceType.name,
        'status': status.label,
        'estimatedPrice': estimatedPrice,
        'finalPrice': finalPrice,
        'paymentId': paymentId,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'notes': notes,
        if (guest != null) 'guest': guest!.toJson(),
        'flightNumber': flightNumber,
        'flightType': flightType,
        'pickupAirport': pickupAirport,
        'hours': hours,
        'passengerCount': passengerCount,
        'luggageCount': luggageCount,
      };

  Booking copyWith({
    String? driverId,
    BookingStatus? status,
    double? finalPrice,
    String? paymentId,
    DateTime? updatedAt,
  }) =>
      Booking(
        id: id,
        riderId: riderId,
        driverId: driverId ?? this.driverId,
        origin: origin,
        destination: destination,
        scheduledAt: scheduledAt,
        vehicleClass: vehicleClass,
        serviceType: serviceType,
        status: status ?? this.status,
        estimatedPrice: estimatedPrice,
        finalPrice: finalPrice ?? this.finalPrice,
        paymentId: paymentId ?? this.paymentId,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        notes: notes,
        guest: guest,
        flightNumber: flightNumber,
        flightType: flightType,
        pickupAirport: pickupAirport,
        hours: hours,
        passengerCount: passengerCount,
        luggageCount: luggageCount,
        pricingReviewReason: pricingReviewReason,
        settlement: settlement,
        refunded: refunded,
        driverInfo: driverInfo,
        riderRating: riderRating,
        cardPayment: cardPayment,
        cardPaymentFailed: cardPaymentFailed,
        riderPreferences: riderPreferences,
      );
}

// ---------------------------------------------------------------------------
// AdminAlert
// ---------------------------------------------------------------------------

/// Aviso del servidor para el admin (adminAlerts): precio con distancia
/// aproximada, solicitudes reconciliadas… Solo lectura en la app; se marca
/// revisado con la callable resolveAlert.
class AdminAlert {
  const AdminAlert({
    required this.id,
    required this.type,
    required this.createdAt,
    this.bookingId,
    this.message = '',
    this.resolved = false,
  });

  final String id;
  final String type;
  final DateTime createdAt;
  final String? bookingId;
  final String message;
  final bool resolved;

  factory AdminAlert.fromJson(Map<String, dynamic> j) => AdminAlert(
        id: j['id'] as String,
        type: j['type'] as String? ?? '',
        createdAt: j['createdAt'] is Timestamp
            ? (j['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        bookingId: j['bookingId'] as String?,
        message: j['message'] as String? ?? '',
        resolved: j['resolved'] == true,
      );
}

// ---------------------------------------------------------------------------
// BookingEvent — registro de transiciones (bookings/{id}/events)
// ---------------------------------------------------------------------------

/// Un paso del viaje que registró el servidor. La ubicación del chófer
/// viene de eventLocations, que solo lee el admin.
class BookingEvent {
  const BookingEvent({
    required this.id,
    required this.type,
    required this.from,
    required this.to,
    required this.actorUid,
    required this.actorRole,
    required this.source,
    this.at,
    this.appVersion,
    this.farFromPickup = false,
    this.arrivalCheck,
    this.reason,
    this.method,
    this.failedAttempts,
    this.lat,
    this.lng,
    this.distanceMeters,
  });

  final String id;

  /// 'transition' o 'pickup_locked'.
  final String type;
  final BookingStatus from;
  final BookingStatus to;
  final String actorUid;
  final String actorRole;

  /// driver_app, admin o system.
  final String source;
  final DateTime? at;
  final String? appVersion;
  final bool farFromPickup;

  /// compared, no_radius, no_location o no_pickup (solo en la llegada).
  final String? arrivalCheck;

  /// Motivo del admin al forzar la verificación.
  final String? reason;

  /// pickup_code o admin_override (en la verificación).
  final String? method;
  final int? failedAttempts;
  final double? lat;
  final double? lng;
  final int? distanceMeters;

  bool get hasLocation => lat != null && lng != null;

  factory BookingEvent.fromJson(
    String id,
    Map<String, dynamic> j, [
    Map<String, dynamic>? location,
  ]) {
    final actor = j['actor'] is Map ? j['actor'] as Map : const {};
    return BookingEvent(
      id: id,
      type: j['type'] as String? ?? 'transition',
      from: BookingStatusX.fromString(j['from'] as String? ?? ''),
      to: BookingStatusX.fromString(j['to'] as String? ?? ''),
      actorUid: actor['uid'] as String? ?? '',
      actorRole: actor['role'] as String? ?? '',
      source: j['source'] as String? ?? '',
      at: j['at'] is Timestamp ? (j['at'] as Timestamp).toDate() : null,
      appVersion: j['appVersion'] as String?,
      farFromPickup: j['farFromPickup'] == true,
      arrivalCheck: j['arrivalCheck'] as String?,
      reason: j['reason'] as String?,
      method: j['method'] as String?,
      failedAttempts: (j['failedAttempts'] as num?)?.toInt(),
      lat: (location?['lat'] as num?)?.toDouble(),
      lng: (location?['lng'] as num?)?.toDouble(),
      distanceMeters: (location?['distanceMeters'] as num?)?.toInt(),
    );
  }
}

// ---------------------------------------------------------------------------
// Incident — SOS (incidents/{id}); lo leen quien lo disparó y el admin
// ---------------------------------------------------------------------------

/// cancelRequested: quien lo disparó lo canceló (quizá bajo coacción);
/// central debe verificar por llamada y reconocerlo.
enum IncidentStatus { open, acknowledged, closed, cancelRequested }

IncidentStatus incidentStatusFrom(String? s) => switch (s) {
      'acknowledged' => IncidentStatus.acknowledged,
      'closed' => IncidentStatus.closed,
      'cancel_requested' => IncidentStatus.cancelRequested,
      _ => IncidentStatus.open,
    };

class Incident {
  const Incident({
    required this.id,
    required this.bookingId,
    required this.reporterId,
    required this.reporterRole,
    required this.status,
    this.count = 1,
    this.createdAt,
    this.acknowledgedAt,
    this.closedAt,
    this.closeNote,
    this.cancelledByReporter = false,
    this.escalationCount = 0,
    this.locationRetentionDays,
  });

  final String id;
  final String bookingId;
  final String reporterId;

  /// 'rider' o 'driver'.
  final String reporterRole;
  final IncidentStatus status;

  /// Veces que se pulsó (los repetidos no crean otro incidente).
  final int count;
  final DateTime? createdAt;
  final DateTime? acknowledgedAt;
  final DateTime? closedAt;
  final String? closeNote;
  final bool cancelledByReporter;
  final int escalationCount;

  /// Días que se guardan las ubicaciones al cerrarse; null = sin configurar
  /// (no se borra nada).
  final int? locationRetentionDays;

  /// Abierto o reconocido: se comparte la ubicación y central lo atiende.
  bool get isLive =>
      !cancelledByReporter &&
      (status == IncidentStatus.open || status == IncidentStatus.acknowledged);

  /// Central aún no lo ha reconocido (abierto o cancelado sin verificar).
  bool get needsAck =>
      status == IncidentStatus.open || status == IncidentStatus.cancelRequested;

  factory Incident.fromJson(String id, Map<String, dynamic> j) {
    DateTime? t(Object? v) => v is Timestamp ? v.toDate() : null;
    return Incident(
      id: id,
      bookingId: j['bookingId'] as String? ?? '',
      reporterId: j['reporterId'] as String? ?? '',
      reporterRole: j['reporterRole'] as String? ?? '',
      status: incidentStatusFrom(j['status'] as String?),
      count: (j['count'] as num?)?.toInt() ?? 1,
      createdAt: t(j['createdAt']),
      acknowledgedAt: t(j['acknowledgedAt']),
      closedAt: t(j['closedAt']),
      closeNote: j['closeNote'] as String?,
      cancelledByReporter: j['cancelledByReporter'] == true,
      escalationCount:
          ((j['escalation'] as Map?)?['count'] as num?)?.toInt() ?? 0,
      locationRetentionDays: (j['locationRetentionDays'] as num?)?.toInt(),
    );
  }
}

/// Paso del registro de un incidente (incidents/{id}/events, solo admin).
class IncidentLogEntry {
  const IncidentLogEntry({
    required this.type,
    this.at,
    this.actorRole = '',
    this.note,
    this.count,
  });

  /// raised, repeated, escalated, acknowledged, closed,
  /// cancel_requested, reopened_by_reporter.
  final String type;
  final DateTime? at;
  final String actorRole;
  final String? note;
  final int? count;

  factory IncidentLogEntry.fromJson(Map<String, dynamic> j) => IncidentLogEntry(
        type: j['type'] as String? ?? '',
        at: j['at'] is Timestamp ? (j['at'] as Timestamp).toDate() : null,
        actorRole: (j['actor'] as Map?)?['role'] as String? ?? '',
        note: j['note'] as String?,
        count: (j['count'] as num?)?.toInt(),
      );
}

/// Resultado de pulsar SOS.
class IncidentRaise {
  const IncidentRaise({
    required this.incidentId,
    this.alreadyOpen = false,
    this.count = 1,
  });
  final String incidentId;
  final bool alreadyOpen;
  final int count;
}

// ---------------------------------------------------------------------------
// BookingQuote
// ---------------------------------------------------------------------------

/// Precio de un viaje calculado por el servidor (quoteBooking): es el que se
/// cobra. [approximateDistance] indica que la ruta por calles no estuvo
/// disponible y se usó la línea recta con el factor de ruta del admin.
class BookingQuote {
  const BookingQuote({required this.price, this.approximateDistance = false});

  final double price;
  final bool approximateDistance;

  factory BookingQuote.fromJson(Map<String, dynamic> j) => BookingQuote(
        price: (j['price'] as num).toDouble(),
        approximateDistance: j['distanceSource'] == 'fallback',
      );
}

// ---------------------------------------------------------------------------
// OpenRequest
// ---------------------------------------------------------------------------

/// Reserva pendiente tal como la ve un chófer antes de aceptarla
/// (`openRequests/{bookingId}`, escrita por el servidor). Sin nombres,
/// contactos, direcciones exactas, notas ni preferencias del pasajero.
class OpenRequest {
  const OpenRequest({
    required this.id,
    required this.vehicleClass,
    required this.serviceType,
    required this.scheduledAt,
    required this.estimatedPrice,
    this.hours,
    this.passengerCount = 1,
    this.luggageCount = 0,
    this.pickupAirport,
    this.flightType,
    this.pickupArea,
    this.dropoffArea,
    this.pickupApprox,
    this.dropoffApprox,
    this.tripKm,
  });

  /// Mismo id que la reserva.
  final String id;
  final VehicleClass vehicleClass;
  final ServiceType serviceType;
  final DateTime scheduledAt;
  final double estimatedPrice;
  final int? hours;
  final int passengerCount;
  final int luggageCount;
  final String? pickupAirport;
  final String? flightType;

  /// Ciudad o aeropuerto de recogida y de destino.
  final String? pickupArea;
  final String? dropoffArea;

  /// Puntos redondeados a ~1 km, para el mapa y la ruta aproximada.
  final Place? pickupApprox;
  final Place? dropoffApprox;

  /// Distancia en línea recta entre las zonas, en km.
  final double? tripKm;

  String get pickupLabel => pickupArea ?? 'Zona de recogida';
  String get dropoffLabel => dropoffArea ?? 'Zona de destino';

  static Place? _approx(Object? j, String label) {
    if (j is! Map) return null;
    final lat = j['lat'], lng = j['lng'];
    if (lat is! num || lng is! num) return null;
    return Place(
      name: label,
      address: label,
      lat: lat.toDouble(),
      lng: lng.toDouble(),
    );
  }

  factory OpenRequest.fromJson(String id, Map<String, dynamic> j) {
    final pickupArea = j['pickupArea'] as String?;
    final dropoffArea = j['dropoffArea'] as String?;
    return OpenRequest(
      id: id,
      vehicleClass: VehicleClass.values.firstWhere(
        (e) => e.name == j['vehicleClass'],
        orElse: () => VehicleClass.business,
      ),
      serviceType: ServiceType.values.firstWhere(
        (e) => e.name == j['serviceType'],
        orElse: () => ServiceType.oneWay,
      ),
      scheduledAt: j['scheduledAt'] is Timestamp
          ? (j['scheduledAt'] as Timestamp).toDate()
          : DateTime.now(),
      estimatedPrice: (j['estimatedPrice'] as num?)?.toDouble() ?? 0,
      hours: (j['hours'] as num?)?.toInt(),
      passengerCount: (j['passengerCount'] as num?)?.toInt() ?? 1,
      luggageCount: (j['luggageCount'] as num?)?.toInt() ?? 0,
      pickupAirport: j['pickupAirport'] as String?,
      flightType: j['flightType'] as String?,
      pickupArea: pickupArea,
      dropoffArea: dropoffArea,
      pickupApprox: _approx(
        j['pickupApprox'],
        pickupArea ?? 'Zona de recogida',
      ),
      dropoffApprox: _approx(
        j['dropoffApprox'],
        dropoffArea ?? 'Zona de destino',
      ),
      tripKm: (j['tripKm'] as num?)?.toDouble(),
    );
  }
}

// ---------------------------------------------------------------------------
// Ride
// ---------------------------------------------------------------------------

class Ride {
  const Ride({
    required this.id,
    required this.bookingId,
    required this.riderId,
    required this.driverId,
    required this.startedAt,
    this.completedAt,
    required this.driverRoute,
    this.distanceKm,
    this.durationMin,
    this.riderRating,
    this.driverRating,
  });

  final String id;
  final String bookingId;
  final String riderId;
  final String driverId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<GeoPoint> driverRoute;
  final double? distanceKm;
  final int? durationMin;
  final double? riderRating;
  final double? driverRating;

  factory Ride.fromJson(Map<String, dynamic> j) => Ride(
        id: j['id'] as String,
        bookingId: j['bookingId'] as String,
        riderId: j['riderId'] as String,
        driverId: j['driverId'] as String,
        startedAt: (j['startedAt'] as Timestamp).toDate(),
        completedAt: j['completedAt'] != null
            ? (j['completedAt'] as Timestamp).toDate()
            : null,
        driverRoute: List<GeoPoint>.from(
          (j['driverRoute'] as List? ?? []).map((e) => e as GeoPoint),
        ),
        distanceKm: (j['distanceKm'] as num?)?.toDouble(),
        durationMin: j['durationMin'] as int?,
        riderRating: (j['riderRating'] as num?)?.toDouble(),
        driverRating: (j['driverRating'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookingId': bookingId,
        'riderId': riderId,
        'driverId': driverId,
        'startedAt': Timestamp.fromDate(startedAt),
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'driverRoute': driverRoute,
        'distanceKm': distanceKm,
        'durationMin': durationMin,
        'riderRating': riderRating,
        'driverRating': driverRating,
      };
}

// ---------------------------------------------------------------------------
// Payment
// ---------------------------------------------------------------------------

class Payment {
  const Payment({
    required this.id,
    required this.bookingId,
    required this.riderId,
    required this.stripePaymentIntentId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.receiptUrl,
  });

  final String id;
  final String bookingId;
  final String riderId;
  final String stripePaymentIntentId;

  /// Importe en centavos enteros, como Stripe (12550 = Bs 125,50). Las
  /// reservas guardan bolivianos; convierte con [amountBs] / [toCents].
  final double amount;
  final String currency;
  final PaymentStatus status;
  final DateTime createdAt;
  final String? receiptUrl;

  /// Importe en bolivianos.
  double get amountBs => amount / 100;

  /// Bolivianos → centavos enteros (sin errores de coma flotante).
  static int toCents(double bs) => (bs * 100).round();

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        id: j['id'] as String,
        bookingId: j['bookingId'] as String? ?? '',
        riderId: j['riderId'] as String? ?? '',
        stripePaymentIntentId: j['stripePaymentIntentId'] as String? ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
        currency: j['currency'] as String? ?? 'bob',
        status: PaymentStatusX.fromString(j['status'] as String? ?? 'pending'),
        createdAt: j['createdAt'] is Timestamp
            ? (j['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        receiptUrl: j['receiptUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookingId': bookingId,
        'riderId': riderId,
        'stripePaymentIntentId': stripePaymentIntentId,
        'amount': amount,
        'currency': currency,
        'status': status.label,
        'createdAt': Timestamp.fromDate(createdAt),
        'receiptUrl': receiptUrl,
      };
}

// ---------------------------------------------------------------------------
// PricingRule (admin-configurable)
// ---------------------------------------------------------------------------

/// Tarifa de un tipo de servicio para una clase de vehículo.
///
/// Los importes están en bolivianos (Bs). Los nombres de campo `*Usd` se
/// mantienen por compatibilidad con los documentos ya guardados en Firestore.
class PricingRule {
  const PricingRule({
    required this.id,
    required this.vehicleClass,
    required this.serviceType,
    required this.basePriceUsd,
    required this.pricePerKmUsd,
    required this.pricePerHourUsd,
    required this.minimumPriceUsd,
    this.isActive = true,
    this.updatedAt,
    this.updatedBy,
  });

  final String id;
  final VehicleClass vehicleClass;
  final ServiceType serviceType;
  final double basePriceUsd;
  final double pricePerKmUsd;
  final double pricePerHourUsd;
  final double minimumPriceUsd;

  /// Si es false, la combinación clase + servicio no se puede reservar.
  final bool isActive;
  final DateTime? updatedAt;
  final String? updatedBy;

  /// Id de documento canónico en /pricingRules: `business_oneWay`, etc.
  static String idFor(VehicleClass vc, ServiceType st) =>
      '${vc.name}_${st.name}';

  /// Combinación sin tarifa en Firestore: en blanco, para que el admin la
  /// complete. No hay tarifas de fábrica: sin tarifa no se muestra precio y
  /// el servidor no reserva.
  factory PricingRule.unconfigured(VehicleClass vc, ServiceType st) =>
      PricingRule(
        id: idFor(vc, st),
        vehicleClass: vc,
        serviceType: st,
        basePriceUsd: 0,
        pricePerKmUsd: 0,
        pricePerHourUsd: 0,
        minimumPriceUsd: 0,
      );

  static double _num(Object? v) => (v as num?)?.toDouble() ?? 0.0;

  factory PricingRule.fromJson(Map<String, dynamic> j) => PricingRule(
        id: j['id'] as String,
        vehicleClass: VehicleClass.values.firstWhere(
          (e) => e.name == j['vehicleClass'],
          orElse: () => VehicleClass.business,
        ),
        serviceType: ServiceType.values.firstWhere(
          (e) => e.name == j['serviceType'],
          orElse: () => ServiceType.oneWay,
        ),
        basePriceUsd: _num(j['basePriceUsd']),
        pricePerKmUsd: _num(j['pricePerKmUsd']),
        pricePerHourUsd: _num(j['pricePerHourUsd']),
        minimumPriceUsd: _num(j['minimumPriceUsd']),
        isActive: j['isActive'] as bool? ?? true,
        updatedAt: j['updatedAt'] is Timestamp
            ? (j['updatedAt'] as Timestamp).toDate()
            : null,
        updatedBy: j['updatedBy'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleClass': vehicleClass.name,
        'serviceType': serviceType.name,
        'basePriceUsd': basePriceUsd,
        'pricePerKmUsd': pricePerKmUsd,
        'pricePerHourUsd': pricePerHourUsd,
        'minimumPriceUsd': minimumPriceUsd,
        'isActive': isActive,
      };

  PricingRule copyWith({
    double? basePriceUsd,
    double? pricePerKmUsd,
    double? pricePerHourUsd,
    double? minimumPriceUsd,
    bool? isActive,
  }) =>
      PricingRule(
        id: id,
        vehicleClass: vehicleClass,
        serviceType: serviceType,
        basePriceUsd: basePriceUsd ?? this.basePriceUsd,
        pricePerKmUsd: pricePerKmUsd ?? this.pricePerKmUsd,
        pricePerHourUsd: pricePerHourUsd ?? this.pricePerHourUsd,
        minimumPriceUsd: minimumPriceUsd ?? this.minimumPriceUsd,
        isActive: isActive ?? this.isActive,
        updatedAt: updatedAt,
        updatedBy: updatedBy,
      );

  /// Mismos importes que [other] (ignora metadatos).
  bool sameFareAs(PricingRule other) =>
      basePriceUsd == other.basePriceUsd &&
      pricePerKmUsd == other.pricePerKmUsd &&
      pricePerHourUsd == other.pricePerHourUsd &&
      minimumPriceUsd == other.minimumPriceUsd &&
      isActive == other.isActive;

  /// Errores de validación en español; lista vacía si la tarifa es válida.
  List<String> validate() {
    final errors = <String>[];
    final values = [
      basePriceUsd,
      pricePerKmUsd,
      pricePerHourUsd,
      minimumPriceUsd,
    ];
    if (values.any((v) => v.isNaN || v < 0)) {
      errors.add('Los importes no pueden ser negativos');
    }
    if (serviceType == ServiceType.oneWay &&
        basePriceUsd == 0 &&
        pricePerKmUsd == 0 &&
        minimumPriceUsd == 0) {
      errors.add('Un traslado no puede costar Bs0');
    }
    if (serviceType == ServiceType.byTheHour && pricePerHourUsd <= 0) {
      errors.add('El servicio por horas necesita un precio por hora');
    }
    return errors;
  }

  /// Precio de un servicio: base + distancia (solo ida) o base + horas
  /// (por horas), nunca por debajo del mínimo.
  double estimate({double km = 0, int hours = 2}) {
    final raw = serviceType == ServiceType.byTheHour
        ? basePriceUsd + hours * pricePerHourUsd
        : basePriceUsd + km * pricePerKmUsd;
    return raw < minimumPriceUsd ? minimumPriceUsd : raw;
  }

  double estimateOneWay(double km) => estimate(km: km);

  double estimateByHour(int hours) => estimate(hours: hours);
}

// ---------------------------------------------------------------------------
// AuditLog
// ---------------------------------------------------------------------------

class AuditLog {
  const AuditLog({
    required this.id,
    required this.adminId,
    required this.action,
    required this.targetId,
    required this.targetType,
    required this.details,
    required this.createdAt,
    this.adminEmail,
  });

  final String id;
  final String adminId;
  final String? adminEmail;
  final String action;
  final String targetId;
  final String targetType;
  final String details;
  final DateTime createdAt;

  factory AuditLog.fromJson(Map<String, dynamic> j) => AuditLog(
        id: j['id'] as String,
        adminId: j['adminId'] as String? ?? '',
        adminEmail: j['adminEmail'] as String?,
        action: j['action'] as String? ?? '',
        targetId: j['targetId'] as String? ?? '',
        targetType: j['targetType'] as String? ?? '',
        details: j['details'] as String? ?? '',
        // serverTimestamp() llega como null en la escritura local pendiente.
        createdAt: j['createdAt'] is Timestamp
            ? (j['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'adminId': adminId,
        'adminEmail': adminEmail,
        'action': action,
        'targetId': targetId,
        'targetType': targetType,
        'details': details,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// ---------------------------------------------------------------------------
// AppNotification
// ---------------------------------------------------------------------------

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.bookingId,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final String
      type; // booking_confirmed, driver_arriving, driver_arrived, ride_started, ride_completed, etc.
  final bool isRead;
  final DateTime createdAt;
  final String? bookingId;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        userId: j['userId'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        type: j['type'] as String? ?? 'general',
        isRead: j['isRead'] as bool? ?? false,
        createdAt: j['createdAt'] != null
            ? (j['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        bookingId: j['bookingId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
        'bookingId': bookingId,
      };

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        bookingId: bookingId,
      );
}
